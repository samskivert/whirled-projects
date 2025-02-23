//
// $Id$

package popcraft.ui {

import com.threerings.util.ArrayUtil;
import com.threerings.flashbang.*;
import com.threerings.flashbang.objects.SceneObject;
import com.threerings.flashbang.objects.SimpleSceneObject;
import com.threerings.flashbang.resource.SwfResource;
import com.threerings.flashbang.tasks.*;

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.text.TextField;

import popcraft.*;
import popcraft.gamedata.ResourceData;
import popcraft.game.*;
import popcraft.util.SpriteUtil;

public class DashboardView extends SceneObject
{
    public function DashboardView ()
    {
        _movie = ClientCtx.instantiateMovieClip("dashboard", "dashboard_sym");
        _shuffleMovie = _movie["shuffle"];
        _puzzleFrame = _movie["frame_puzzle"];

        _movie.cacheAsBitmap = true;
        _puzzleFrame.cacheAsBitmap = true;

        _deathPanel = _movie["death"];

        // If "useSpecialPuzzleFrame" is set, our resource rarities are inverted, and we need to
        // draw a special overlay on the puzzle frame.
        if (GameCtx.gameData.puzzleData.useSpecialPuzzleFrame) {
            var overlay :MovieClip = ClientCtx.instantiateMovieClip("dashboard", "resourced", true);
            var overlayParent :MovieClip = _puzzleFrame["resourced_placer"];
            overlayParent.addChild(overlay);
        }

        // the info panel is no longer used
        var infoPanel :MovieClip = _movie["info"];
        if (null != infoPanel) {
            _movie.removeChild(infoPanel);
        }

        // setup resources
        for (var resType :int = 0; resType < Constants.RESOURCE__LIMIT; ++resType) {
            var resourceTextName :String = RESOURCE_TEXT_NAMES[resType];
            var resourceText :TextField = _puzzleFrame[resourceTextName];
            var resourceTextObj :SimpleSceneObject = new SimpleSceneObject(resourceText);
            GameCtx.gameMode.addObject(resourceTextObj);
            _resourceTextObjs.push(resourceTextObj);
            _resourceBars.push(null);
            _oldResourceAmounts.push(-1);
        }

        // setup unit purchase buttons
        var unitParent :MovieClip = _movie["frame_units"];
        unitParent.cacheAsBitmap = true;

        var buttonNumber :int = 1;
        for (var unitType :int = 0; unitType < Constants.UNIT_TYPE__PLAYER_CREATURE_LIMIT; ++unitType) {
            if (!GameCtx.gameMode.isAvailableUnit(unitType)) {
                // don't create buttons for unavailable units
                continue;
            }

            GameCtx.gameMode.addObject(
                new CreaturePurchaseButton(unitType, buttonNumber++, unitParent));
        }

        // hide the components of all the buttons that aren't being used
        for ( ; buttonNumber < Constants.UNIT_TYPE__PLAYER_CREATURE_LIMIT + 1; ++buttonNumber) {
            DisplayObject(unitParent["switch_" + buttonNumber]).visible = false;
            DisplayObject(unitParent["cost_" + buttonNumber]).visible = false;
            DisplayObject(unitParent["highlight_" + buttonNumber]).visible = false;
            DisplayObject(unitParent["unit_" + buttonNumber]["unit"]).visible = false;
            DisplayObject(unitParent["progress_" + buttonNumber]).visible = false;
            DisplayObject(unitParent["button_" + buttonNumber]).visible = false;
            DisplayObject(unitParent["multiplicity_" + buttonNumber]).visible = false;
        }

        // setup PlayerStatusViews
        updatePlayerStatusViews();

        // pause button only visible in single-player games
        var pauseButton :SimpleButton = _movie["pause"];
        pauseButton.tabEnabled = false;
        if (GameCtx.gameMode.canPause) {
            pauseButton.visible = true;
            registerListener(pauseButton, MouseEvent.CLICK,
                function (...ignored) :void {
                    GameCtx.gameMode.pause();
                });

        } else {
            pauseButton.visible = false;
        }

        // _spellSlots keeps track of whether the individual spell slots are occupied
        // or empty
        var numSlots :int = GameCtx.gameData.maxSpellsPerType * Constants.CASTABLE_SPELL_TYPE__LIMIT;
        for (var ii :int = 0; ii < numSlots; ++ii) {
            _spellSlots.push(false);
        }

        // we need to know when the player gets a spell
        registerListener(GameCtx.localPlayerInfo, GotSpellEvent.GOT_SPELL,
            onGotSpell);

        updateResourceMeters();
    }

    public function updatePlayerStatusViews () :void
    {
        var playerInfo :PlayerInfo;

        var deadViews :Array = [];
        var liveViews :Array = [];

        // discover which existing views are dead
        for each (var existingStatusView :PlayerStatusView in _playerStatusViews) {
            if (existingStatusView.isAlive) {
                liveViews.push(existingStatusView);
            } else {
                deadViews.push(existingStatusView);
            }
        }

        // discover which players don't have views created for them
        for each (playerInfo in GameCtx.playerInfos) {
            if (ArrayUtil.findIf(liveViews,
                function (view :PlayerStatusView) :Boolean {
                    return (view.playerInfo == playerInfo);
                }) == null) {
                liveViews.push(new PlayerStatusView(playerInfo.playerIndex));
            }
        }

        // destroy dead views
        for each (var deadView :PlayerStatusView in deadViews) {
            deadView.addTask(new SerialTask(
                LocationTask.CreateEaseIn(deadView.x, 47 + deadView.height, VIEW_MOVE_TIME),
                new SelfDestructTask()));
        }

        // sort the live views by playerIndex
        liveViews.sort(
            function (a :PlayerStatusView, b :PlayerStatusView) :int {
                var aIndex :int = a.playerInfo.playerIndex;
                var bIndex :int = b.playerInfo.playerIndex;
                if (aIndex < bIndex) {
                    return -1;
                } else if (aIndex > bIndex) {
                    return 1;
                } else {
                    return 0;
                }
            });

        var statusViewLocs :Array = PLAYER_STATUS_VIEW_LOCS[liveViews.length - 2];
        var playerFrame :MovieClip = _movie["frame_players"];
        for (var ii :int = 0; ii < liveViews.length; ++ii) {
            var liveView :PlayerStatusView = liveViews[ii];
            var loc :Point = statusViewLocs[ii];

            // add the view to the DB if it was just created
            if (!liveView.isLiveObject) {
                liveView.x = loc.x;
                liveView.y = loc.y + liveView.height;
                GameCtx.gameMode.addSceneObject(liveView, playerFrame);
            }

            // animate the view to its new location
            liveView.addTask(LocationTask.CreateEaseOut(loc.x, loc.y, VIEW_MOVE_TIME));

        }

        _playerStatusViews = liveViews;
    }

    override protected function addedToDB () :void
    {
        // add any spells the player already has to the dashboard
        for (var spellType :int = 0; spellType < Constants.CASTABLE_SPELL_TYPE__LIMIT; ++spellType) {
            var count :int = GameCtx.localPlayerInfo.getSpellCount(spellType);
            for (var i :int = 0; i < count; ++i) {
                createSpellButton(spellType, false);
            }
        }
    }

    public function puzzleShuffle () :void
    {
        // when the "shuffle" spell is cast, we show an animation in the
        // Dashboard, and then reset the puzzle
        _shuffleMovie.gotoAndPlay("go");

        addNamedTask(
            PUZZLE_SHUFFLE_TASK,
            new SerialTask(
                new WaitForFrameTask("swap", _shuffleMovie),
                new FunctionTask(function () :void { GameCtx.puzzleBoard.puzzleShuffle(); })),
            true);

        GameCtx.playGameSound("sfx_puzzleshuffle");
    }

    protected function onGotSpell (e :GotSpellEvent) :void
    {
        createSpellButton(e.spellType, true);
    }

    protected function createSpellButton (spellType :int, animateIn :Boolean) :void
    {
        // find the first free spell slot to put this spell in
        var numSlotsForType :int = GameCtx.gameData.maxSpellsPerType;

        var slot :int = -1;
        var firstSlot :int = spellType * numSlotsForType;
        var lastSlot :int = (spellType + 1) * numSlotsForType;
        for (var i :int = firstSlot; i <= lastSlot; ++i) {
            if (!Boolean(_spellSlots[i])) {
                slot = i;
                break;
            }
        }

        if (slot < 0) {
            // this should never happen
            return;
        }

        _spellSlots[slot] = true; // occupy the slot

        // create a new icon
        var spellButton :SpellButton = new SpellButton(spellType, slot, animateIn);
        registerListener(spellButton.clickableObject, MouseEvent.CLICK,
            function (...ignored) :void {
                onSpellButtonClicked(spellButton);
            });

        (this.db as AppMode).addSceneObject(spellButton, _movie);
    }

    protected function onSpellButtonClicked (spellButton :SpellButton) :void
    {
        if (!spellButton.isLiveObject) {
            // prevent unlikely but possible multiple clicks on a button
            return;
        }

        if (!spellButton.isCastable) {
            spellButton.showUncastableJiggle();
        } else {
            GameCtx.gameMode.sendCastSpellMsg(GameCtx.localPlayerIndex, spellButton.spellType,
                false);
            // un-occupy the slot
            _spellSlots[spellButton.slot] = false;
            spellButton.destroySelf();
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _movie;
    }

    override protected function update (dt :Number) :void
    {
        updateResourceMeters();

        // when the player dies, show the death panel
        var playerDead :Boolean = !GameCtx.localPlayerInfo.isAlive;
        if (!this.showingDeathPanel && playerDead) {
            _deathPanel.y = 6;
            _deathPanel.visible = true;

        } else if (this.showingDeathPanel && !playerDead) {
            _deathPanel.visible = false;
        }

        // resurrect button
        var shouldShowButton :Boolean = this.showResurrectButton;
        if (_resurrectButton != null && !shouldShowButton) {
            _resurrectButton.parent.removeChild(_resurrectButton);
            _resurrectButton = null;

        } else if (_resurrectButton == null && shouldShowButton) {
            _resurrectButton = UIBits.createButton("Resurrect", 2.5);
            _resurrectButton.x = RESURRECT_BUTTON_LOC.x - (_resurrectButton.width * 0.5);
            _resurrectButton.y = RESURRECT_BUTTON_LOC.y - (_resurrectButton.height * 0.5);
            GameCtx.dashboardLayer.addChild(_resurrectButton);

            registerListener(_resurrectButton, MouseEvent.CLICK,
                function (...ignored) :void {
                    GameCtx.gameMode.sendResurrectPlayerMsg();
                });
        }
    }

    protected function get showingDeathPanel () :Boolean
    {
        return _deathPanel.visible;
    }

    protected function get showResurrectButton () :Boolean
    {
        return (showingDeathPanel &&
            GameCtx.canResurrect &&
            GameCtx.localPlayerInfo.canResurrect);
    }

    protected function updateResourceMeters () :void
    {
        for (var resType :int = 0; resType < Constants.RESOURCE__LIMIT; ++resType) {
            updateResourceMeter(resType);
        }
    }

    protected function updateResourceMeter (resType :int) :void
    {
        var resAmount :int = GameCtx.localPlayerInfo.getResourceAmount(resType);

        // only update if the resource amount has changed
        var oldResAmount :int = _oldResourceAmounts[resType];
        if (resAmount == oldResAmount) {
            return;
        }

        _oldResourceAmounts[resType] = resAmount;

        var textObj :SimpleSceneObject = _resourceTextObjs[resType];
        var textField :TextField = TextField(textObj.displayObject);
        textField.text = String(resAmount);

        var resourceBar :Sprite = _resourceBars[resType];

        if (null == resourceBar) {
            resourceBar = SpriteUtil.createSprite();
            _resourceBars[resType] = resourceBar;
            _puzzleFrame.addChildAt(resourceBar, RESOURCE_METER_PARENT_INDEX);
        }

        var g :Graphics = resourceBar.graphics;
        g.clear();

        if (resAmount > 0) {
            var color :uint = ResourceData(GameCtx.gameData.puzzleData.resources[resType]).color;
            var meterLoc :Point = RESOURCE_METER_LOCS[resType];

            g.lineStyle(1, 0);
            g.beginFill(color);
            g.drawRect(
                meterLoc.x,
                meterLoc.y,
                1 + (RESOURCE_METER_WIDTH * (resAmount / GameCtx.localPlayerInfo.maxResourceAmount)),
                RESOURCE_METER_HEIGHT);
            g.endFill();
        }

        if (resAmount != 0 && oldResAmount == 0) {
            textObj.visible = true;
            textObj.removeAllTasks();

        } else if(resAmount == 0 && oldResAmount != 0) {
            var blinkTask :RepeatingTask = new RepeatingTask();
            blinkTask.addTask(new VisibleTask(false));
            blinkTask.addTask(new TimedTask(0.25));
            blinkTask.addTask(new VisibleTask(true));
            blinkTask.addTask(new TimedTask(0.25));
            textObj.addTask(blinkTask);
        }
    }

    protected var _movie :MovieClip;
    protected var _puzzleFrame :MovieClip;
    protected var _deathPanel :MovieClip;
    protected var _shuffleMovie :MovieClip;
    protected var _resourceTextObjs :Array = [];
    protected var _resourceBars :Array = [];
    protected var _oldResourceAmounts :Array = [];
    protected var _spellSlots :Array = []; // of Booleans
    protected var _playerStatusViews :Array = [];
    protected var _resurrectButton :SimpleButton;

    protected static const PUZZLE_SHUFFLE_TASK :String = "PuzzleShuffle";

    protected static const RESOURCE_TEXT_NAMES :Array =
        [ "resource_2", "resource_1", "resource_4", "resource_3" ];

    protected static const RESOURCE_METER_LOCS :Array =
        [ new Point(-65, 44), new Point(-134, 44), new Point(73, 44), new Point(4, 44) ];

    protected static const RESOURCE_METER_WIDTH :Number = 63;
    protected static const RESOURCE_METER_HEIGHT :Number = 20;

    protected static const RESOURCE_METER_PARENT_INDEX :int = 3;

    protected static const PLAYER_STATUS_VIEW_LOCS :Array = [
        [ new Point(40, 47), new Point(105, 47) ],                                          // 2 players
        [ new Point(40, 47), new Point(105, 47), new Point(170, 47), ],                     // 3 players
        [ new Point(29, 47), new Point(81, 47), new Point(133, 47), new Point(185, 47) ],   // 4 players
    ];

    protected static const RESURRECT_BUTTON_LOC :Point = new Point(350, 422);

    protected static const VIEW_MOVE_TIME :Number = 0.5;
}

}

import flash.display.MovieClip;
import flash.display.DisplayObject;
import flash.text.TextField;

import com.threerings.flashbang.objects.SceneObject;
import com.threerings.flashbang.tasks.*;
import com.threerings.flashbang.resource.*;
import flash.display.InteractiveObject;

/** Currently unused */
class InfoPanel extends SceneObject
{
    public function InfoPanel (parent :MovieClip)
    {
        _infoTextParent = parent["info"];
        _infoText = _infoTextParent["info_text"];
        _infoTextParent.y = 6;
        _infoTextParent.visible = false;

        _infoTextParent.cacheAsBitmap = true;
    }

    override public function get displayObject () :DisplayObject
    {
        return _infoTextParent;
    }

    public function show (text :String) :void
    {
        _infoText.text = text;

        if (!hasTasksNamed(SHOW_TASK_NAME)) {
            // we're not already being shown

            if (hasTasksNamed(HIDE_TASK_NAME)) {
                // the panel is in the process of being hidden
                removeNamedTasks(HIDE_TASK_NAME);
                _infoTextParent.y = VISIBLE_Y;
                this.visible = true;

            } else if (!this.visible) {
                // the panel is already hidden
                _infoTextParent.y = HIDDEN_Y;

                var showTask :SerialTask = new SerialTask();
                showTask.addTask(new TimedTask(SHOW_DELAY));
                showTask.addTask(new VisibleTask(true));
                showTask.addTask(LocationTask.CreateSmooth(_infoTextParent.x, VISIBLE_Y, SLIDE_TIME));
                addNamedTask(SHOW_TASK_NAME, showTask);
            }
        }
    }

    public function hide () :void
    {
        if (!hasTasksNamed(HIDE_TASK_NAME)) {
            // we're not already being hidden

            if (hasTasksNamed(SHOW_TASK_NAME)) {
                // the panel is in the process of being shown
                removeNamedTasks(SHOW_TASK_NAME);
                this.visible = false;

            } else if (this.visible) {
                // the panel is already visible
                var hideTask :SerialTask = new SerialTask();
                hideTask.addTask(LocationTask.CreateSmooth(_infoTextParent.x, HIDDEN_Y, SLIDE_TIME));
                hideTask.addTask(new VisibleTask(false));
                addNamedTask(HIDE_TASK_NAME, hideTask);
            }
        }
    }

    protected var _infoTextParent :MovieClip;
    protected var _infoText :TextField;

    protected static const SHOW_TASK_NAME :String = "Show";
    protected static const HIDE_TASK_NAME :String = "Hide";

    protected static const SHOW_DELAY :Number = 0.7;
    protected static const SLIDE_TIME :Number = 0.2;
    protected static const VISIBLE_Y :Number = 6;
    protected static const HIDDEN_Y :Number = 121;
}
