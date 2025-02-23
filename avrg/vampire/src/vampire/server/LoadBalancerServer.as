package vampire.server
{
import com.threerings.flashbang.objects.BasicGameObject;
import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.whirled.net.MessageReceivedEvent;

import flash.utils.ByteArray;
import flash.utils.setInterval;

import vampire.data.VConstants;
import vampire.net.messages.LoadBalancingMsg;

/**
 * Periodically sorts rooms according to the number of players (with some caveats)
 * and stores the 5 best rooms.  When players request, the room list is sent to the
 * player.  This updates the LoadBalancer on the client, which shows 4 rooms the
 * player can click and be transported to.
 *
 */
public class LoadBalancerServer extends BasicGameObject
{
    public function LoadBalancerServer (server :GameServer)
    {
        _server = server;
        registerListener(_server.ctrl.game, MessageReceivedEvent.MESSAGE_RECEIVED, handleMessage);
        addIntervalId(setInterval(refreshLowPopulationRoomData, ROOM_POPULATION_REFRESH_RATE));
    }

    protected function handleMessage (evt :MessageReceivedEvent) :void
    {
        if (evt.name == LoadBalancingMsg.NAME) {
            log.debug("Received load balance request from " + evt.senderId);
//            _playersRequestedRoomInfo.add(evt.senderId);
            sendPlayerRoomsMessage(evt.senderId as int);
        }

    }

    protected function sendPlayerRoomsMessage (playerId :int) :void
    {
        var roomIds :Array = _sortedRoomIds.slice(0,
                VConstants.ROOMS_SHOWN_IN_LOAD_BALANCER + 1);
            log.debug("sendPlayerRoomsMessage", "roomIds", roomIds);
            var roomNames :Array = roomIds.map(function (roomId :int, ...ignored) :String {
                if (_server.isRoom(roomId)) {
                    return _server.getRoom(roomId).name;
                }
                else {
                    return "";
                }
            });
            log.debug("sendPlayerRoomsMessage", "roomNames", roomNames);

            var roomInfoMessage :LoadBalancingMsg =
                new LoadBalancingMsg(0, roomIds, roomNames);
            var bytes :ByteArray = roomInfoMessage.toBytes();

            //Only handle the message if the originating player exists.
            try {
                if (_server.isPlayer(playerId)) {
                    var player :PlayerData = _server.getPlayer(playerId);
                    log.debug("Sending " + player.name + " " + roomInfoMessage);
                    player.sctrl.sendMessage(LoadBalancingMsg.NAME, bytes);
                }
            }
            catch(err :Error) {
                log.error(err + "\n" + err.getStackTrace());
            }
    }

//    override protected function update (dt:Number) :void
//    {
//        if (_playersRequestedRoomInfo.size() > 0) {
//            log.debug("update", "_sortedRoomIds", _sortedRoomIds);
//
//            var roomIds :Array = _sortedRoomIds.slice(0,
//                VConstants.ROOMS_SHOWN_IN_LOAD_BALANCER + 1);
//            log.debug("update", "roomIds", roomIds);
//            var roomNames :Array = roomIds.map(function (roomId :int, ...ignored) :String {
//                if (_server.isRoom(roomId)) {
//                    return _server.getRoom(roomId).name;
//                }
//                else {
//                    return "";
//                }
//            });
//            log.debug("update", "roomNames", roomNames);
//
//            var roomInfoMessage :LoadBalancingMsg =
//                new LoadBalancingMsg(0, roomIds, roomNames);
//            var bytes :ByteArray = roomInfoMessage.toBytes();
//
//            _playersRequestedRoomInfo.forEach(function (playerId :int) :void {
//                //Only handle the message if the originating player exists.
//                try {
//                    if (_server.isPlayer(playerId)) {
//                        var player :PlayerData = _server.getPlayer(playerId);
//                        log.debug("Sending " + player.name + " " + roomInfoMessage);
//                        PlayerSubControlServer(player.ctrl).sendMessage(LoadBalancingMsg.NAME, bytes);
//                    }
//                }
//                catch(err :Error) {
//                    log.error(err + "\n" + err.getStackTrace());
//                }
//            });
//            _playersRequestedRoomInfo.clear();
//        }
//    }

    override public function shutdown (...ignored) :void
    {
        super.shutdown();
        _server = null;
    }

    protected function refreshLowPopulationRoomData (...ignored) :void
    {
        var roomId2Players :Map = Maps.newMapOf(int);
        //Create the roomId to population map
        _server.rooms.forEach(function (roomId :int, room :Room) :void {
            if (room.ctrl != null && room.name != null) {
                roomId2Players.put(roomId, room.ctrl.getPlayerIds().length);
            }
        });
        //Sort the rooms ids.
        var roomIdsSorted :Array = sortRoomsToSendPlayers(roomId2Players);
        _sortedRoomIds = roomIdsSorted;
    }


    protected static function sortRoomsToSendPlayers (roomId2PlayerCount :Map) :Array
    {
        var rooms :Array = roomId2PlayerCount.keys();
        //We want rooms with 3-6 occupants preferentially, then rooms with 1 person, then 7+
        var preferredRangeMin :int = 3;
        var preferredRangeMax :int = 6;

        //Exclude rooms with 2 or 0 players
        rooms = rooms.filter(function (roomId :int, ...ignored) :Boolean {
            if (roomId2PlayerCount.get(roomId) == 2 || roomId2PlayerCount.get(roomId) == 0) {
                return false;
            }
            return true;
        });

        var sortedRooms :Array = rooms.sort(function (roomId1 :int, roomId2 :int) :int {
            var r1 :int = roomId2PlayerCount.get(roomId1);
            var r2 :int = roomId2PlayerCount.get(roomId2);

            //Numbers are in the same band
            if ((r1 == 1 && r2 == 1) ||
                (r1 >= preferredRangeMin && r1 <= preferredRangeMax
                    && r2 >= preferredRangeMin && r2 <= preferredRangeMax) ||
                r1 > preferredRangeMax && r2 > preferredRangeMax) {

                if (r1 < r2) {
                    return -1;
                }
                else if (r1 == r2) {
                    return 0;
                }
                else {
                    return 1;
                }
            }
//            else
            //r1 is 1
            if (r1 == 1) {
                if (r2 == 1) {
                    return 0;
                }
                else if (r2 >= preferredRangeMin && r2 <= preferredRangeMax) {
                    return 1;
                }
                else {
                    return -1;
                }
            }
            //r1 is between [preferredRangeMin, preferredRangeMax]
            else if (r1 >= preferredRangeMin && r1 <= preferredRangeMax) {
                if (r2 == 1 || r2 > preferredRangeMax) {
                    return -1;
                }
                else {
                    if (r1 < r2) {
                        return -1;
                    }
                    else if (r1 == r2) {
                        return 0;
                    }
                    else {
                        return 1;
                    }
                }
            }
            //r1 is greater than preferredRangeMax
            else {
                if (r2 == 1 || (r2 >= preferredRangeMin && r2 <= preferredRangeMax)) {
                    return 1;
                }
                else {
                    if (r1 < r2) {
                        return -1;
                    }
                    else if (r1 == r2) {
                        return 0;
                    }
                    else {
                        return 1;
                    }
                }
            }


        });

        //Add the rooms with two players again
        roomId2PlayerCount.forEach(function (roomId :int, playerCount :int) :void {
            if (playerCount == 2) {
                sortedRooms.push(roomId);
            }
        });

        return sortedRooms;
    }
    protected var _server :GameServer;
    protected var _sortedRoomIds :Array = [];

//    protected var _playersRequestedRoomInfo :HashSet = new HashSet();
    /**
     * An array of the form [[roomid1, roomid2, ..], [room1Population, room2Population, ...]]
     * Used by the client to find low population rooms
     */
    protected var _lowPopulationRooms :Array = [];

    /**
    * Resort the rooms every 5 seconds.
    */
    protected static const ROOM_POPULATION_REFRESH_RATE :int = 10000;
    protected static const log :Log = Log.getLog(LoadBalancerServer);

}
}
