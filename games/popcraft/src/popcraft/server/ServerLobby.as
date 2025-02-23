//
// $Id$

package popcraft.server {

import com.threerings.util.ArrayUtil;
import com.threerings.util.EventHandlerManager;
import com.threerings.util.Log;
import com.threerings.util.TimerGroup;
import com.whirled.net.MessageReceivedEvent;

import flash.events.TimerEvent;
import flash.utils.Timer;

import popcraft.*;

public class ServerLobby
{
    public function ServerLobby ()
    {
        _events.registerListener(ServerCtx.gameCtrl.net, MessageReceivedEvent.MESSAGE_RECEIVED,
            onMsgReceived);

        var numPlayers :int = ServerCtx.seatingMgr.numExpectedPlayers;
        ServerCtx.gameCtrl.doBatch(function () :void {
            setProp(LobbyConfig.PROP_GAME_START_COUNTDOWN, false);
            setProp(LobbyConfig.PROP_RANDSEED, uint(Math.random() * uint.MAX_VALUE));
            setProp(LobbyConfig.PROP_HANDICAPS, ArrayUtil.create(numPlayers, false));
            setProp(LobbyConfig.PROP_PORTRAITS,
                ArrayUtil.create(numPlayers, Constants.DEFAULT_PORTRAIT));
            setProp(LobbyConfig.PROP_COLORS, ArrayUtil.create(numPlayers, Constants.RANDOM_COLOR));
            setProp(LobbyConfig.PROP_PLAYER_TEAMS, ArrayUtil.create(numPlayers,
                LobbyConfig.UNASSIGNED_TEAM_ID));
            setProp(LobbyConfig.PROP_HAS_MORBID_INFECTION, ArrayUtil.create(numPlayers, false));
            setProp(LobbyConfig.PROP_HAS_ENDLESS_MODE, ArrayUtil.create(numPlayers, false));

            setProp(LobbyConfig.PROP_INITED, true);
        });

        log.info("Started server lobby");
    }

    public function shutdown () :void
    {
        _events.freeAllHandlers();
        _timers.shutdown();

        setProp(LobbyConfig.PROP_INITED, false);

        log.info("Shutdown server lobby");
    }

    protected function onMsgReceived (e :MessageReceivedEvent) :void
    {
        if (_gameStarted) {
            return;
        }

        log.info("msgReceived", "name", e.name, "val", e.value);

        var playerId :int = e.senderId;
        var playerSeat :int = ServerCtx.seatingMgr.getPlayerSeat(playerId);
        if (playerSeat < 0) {
            return;
        }

        switch (e.name) {
        case LobbyConfig.MSG_SET_TEAM:
            var teamId :int = e.value as int;
            if (ServerCtx.lobbyConfig.playerTeams[playerSeat] != teamId &&
                ServerCtx.lobbyConfig.isValidTeamId(teamId) &&
                !ServerCtx.lobbyConfig.isTeamFull(teamId)) {

                setPropAt(LobbyConfig.PROP_PLAYER_TEAMS, playerSeat, teamId);
                gamePropertyChanged();
            }
            break;

        case LobbyConfig.MSG_SET_HANDICAP:
            var handicap :Boolean = e.value as Boolean;
            if (ServerCtx.lobbyConfig.isPlayerHandicapped(playerSeat) != handicap) {
                setPropAt(LobbyConfig.PROP_HANDICAPS, playerSeat, handicap);
                gamePropertyChanged();
            }
            break;

        case LobbyConfig.MSG_SET_PORTRAIT:
            var portrait :String = e.value as String;
            if (ServerCtx.lobbyConfig.getPlayerPortraitName(playerSeat) != portrait) {
                setPropAt(LobbyConfig.PROP_PORTRAITS, playerSeat, portrait);
            }
            break;

        case LobbyConfig.MSG_SET_COLOR:
            var color :uint = e.value as uint;
            if (ServerCtx.lobbyConfig.getPlayerColor(playerSeat) != color) {
                setPropAt(LobbyConfig.PROP_COLORS, playerSeat, color);
            }
            break;

        case LobbyConfig.MSG_SET_MORBID_INFECTION:
            setPropAt(LobbyConfig.PROP_HAS_MORBID_INFECTION, playerSeat, e.value as Boolean);
            break;

        case LobbyConfig.MSG_SET_ENDLESS_MODE:
            setPropAt(LobbyConfig.PROP_HAS_ENDLESS_MODE, playerSeat, e.value as Boolean);
            break;
        }
    }

    protected function gamePropertyChanged () :void
    {
        if (this.shouldStartCountdown) {
            restartCountdown();
        } else {
            stopCountdown();
        }
    }

    protected function get shouldStartCountdown () :Boolean
    {
        return (!_gameStarted &&
                ServerCtx.lobbyConfig.isEveryoneTeamed &&
                ServerCtx.lobbyConfig.teamsDividedProperly);
    }

    protected function restartCountdown () :void
    {
        stopCountdown();
        _countdownTimer = _timers.createTimer(LobbyConfig.COUNTDOWN_TIME * 1000, 1);
        _countdownTimer.addEventListener(TimerEvent.TIMER,
            function (...ignored) :void {
                log.info("Starting game");
                stopCountdown();
                sendMessage(LobbyConfig.MSG_START_GAME);
                _gameStarted = true;
            });
        _countdownTimer.start();
        setProp(LobbyConfig.PROP_GAME_START_COUNTDOWN, true);

        log.info("Started countdown");
    }

    protected function stopCountdown () :void
    {
        if (_countdownTimer != null) {
            _timers.cancelTimer(_countdownTimer);
            _countdownTimer = null;
            setProp(LobbyConfig.PROP_GAME_START_COUNTDOWN, false);
            log.info("Stopped countdown");
        }
    }

    protected function get hasStartedCountdown () :Boolean
    {
        return _countdownTimer != null;
    }

    protected function setProp (name :String, val :Object) :void
    {
        log.info("setProp", "name", name, "val", val);
        ServerCtx.gameCtrl.net.set(name, val, true);
    }

    protected function setPropAt (name :String, index :int, val :Object) :void
    {
        log.info("setPropAt", "name", name, "index", index, "val", val);
        ServerCtx.gameCtrl.net.setAt(name, index, val, true);
    }

    protected function sendMessage (name :String, val :Object = null) :void
    {
        log.info("sendMessage", "name", name, "val", val);
        ServerCtx.gameCtrl.net.sendMessage(name, val);
    }

    protected var _events :EventHandlerManager = new EventHandlerManager();
    protected var _timers :TimerGroup = new TimerGroup();

    protected var _gameStarted :Boolean;
    protected var _countdownTimer :Timer;

    protected static var log :Log = Log.getLog(ServerLobby);
}

}
