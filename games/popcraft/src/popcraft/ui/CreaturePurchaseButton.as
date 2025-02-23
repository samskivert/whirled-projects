//
// $Id$

package popcraft.ui {

import com.threerings.flashbang.AppMode;
import com.threerings.flashbang.GameObject;
import com.threerings.flashbang.resource.*;
import com.threerings.flashbang.tasks.*;

import flash.display.BitmapData;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.text.TextField;

import popcraft.*;
import popcraft.game.battle.*;
import popcraft.game.battle.view.*;
import popcraft.gamedata.*;
import popcraft.game.*;

public class CreaturePurchaseButton extends GameObject
{
    public function CreaturePurchaseButton (unitType :int, slotNum :int, parent :MovieClip)
    {
        _unitType = unitType;

        _switch = parent["switch_" + slotNum];
        _costs = parent["cost_" + slotNum];
        _hilite = parent["highlight_" + slotNum];
        _unitDisplay = parent["unit_" + slotNum]["unit"];
        _progress = parent["progress_" + slotNum];
        _button = parent["button_" + slotNum];
        _button.tabEnabled = false;
        _multiplicity = parent["multiplicity_" + slotNum]["multiplicity"];
        _multiplicity.text = "";

        // instaniate some alternate highlight movies, for spells
        _defaultHilite = _hilite;
        _bloodHilite = ClientCtx.instantiateMovieClip("dashboard", "unit_highlight_bloodlust", true);
        _rigorHilite = ClientCtx.instantiateMovieClip("dashboard", "unit_highlight_rigormortis", true);

        // we want to know when the player casts a spell
        var spellSet :CreatureSpellSet = GameCtx.localPlayerInfo.activeSpells;
        registerListener(spellSet, CreatureSpellSet.SET_MODIFIED, onSpellSetModified);

        registerListener(_button, MouseEvent.CLICK, onClicked);

        _unitData = GameCtx.gameData.units[unitType];
        var playerColor :uint = GameCtx.localPlayerInfo.color;

        // try instantiating some animations
        _enabledAnim = CreatureAnimFactory.getBitmapAnim(unitType, playerColor, "attack_SW");
        if (null == _enabledAnim) {
            _enabledAnim = CreatureAnimFactory.getBitmapAnim(unitType, playerColor, "walk_SW");
        }

        _disabledAnim = CreatureAnimFactory.getBitmapAnim(unitType, playerColor, "stand_SW");
        if (null == _disabledAnim) {
            _disabledAnim = CreatureAnimFactory.getBitmapAnim(unitType, playerColor, "walk_SW");
        }

        // set up the Unit Cost indicators
        for (var resType :int = 0; resType < Constants.RESOURCE__LIMIT; ++resType) {
            var resCost :int = _unitData.getResourceCost(resType);
            if (resCost > 0) {
                if (_resource1Cost == 0) {
                    _resource1Type = resType;
                    _resource1Cost = resCost;
                    _resource1Data = GameCtx.gameData.puzzleData.resources[resType];
                } else {
                    _resource2Type = resType;
                    _resource2Cost = resCost;
                    _resource2Data = GameCtx.gameData.puzzleData.resources[resType];
                }
            }
        }

        // put some colored rectangles behind the cost texts
        var resource1Tile :MovieClip =
            ClientCtx.instantiateMovieClip("dashboard", RESOURCE_COST_TILES[_resource1Type], true);
        var resource2Tile :MovieClip =
            ClientCtx.instantiateMovieClip("dashboard", RESOURCE_COST_TILES[_resource2Type], true);
        resource1Tile.x = -(resource1Tile.width * 0.5);
        resource1Tile.y = -2;
        resource2Tile.x = 18 - (resource2Tile.width * 0.5);
        resource2Tile.y = -2;
        _costs.addChildAt(resource1Tile, 0);
        _costs.addChildAt(resource2Tile, 0);

        var cost1Text :TextField = _costs["cost_1"];
        var cost2Text :TextField = _costs["cost_2"];
        cost1Text.filters = [ new GlowFilter(_resource1Data.hiliteColor, 1, 2, 2, 1000, BitmapFilterQuality.LOW) ];
        cost2Text.filters = [ new GlowFilter(_resource2Data.hiliteColor, 1, 2, 2, 1000, BitmapFilterQuality.LOW) ];

        cost1Text.textColor = _resource1Data.color;
        cost1Text.text = String(_resource1Cost);

        cost2Text.textColor = _resource2Data.color;
        cost2Text.text = String(_resource2Cost);

        createPurchaseMeters();
    }

    override protected function addedToDB () :void
    {
        super.addedToDB();
        _animView = new BitmapAnimView(_disabledAnim);
        (this.db as AppMode).addSceneObject(_animView, _unitDisplay);

        if (Constants.UNIT_TYPE_COURIER != _unitType && Constants.UNIT_TYPE_SAPPER != _unitType) {
            _animView.y = 30;
        }

        updateDisplayState();
    }

    override protected function removedFromDB () :void
    {
        super.removedFromDB();
        _animView.destroySelf();
    }

    protected function onSpellSetModified (e :Event) :void
    {
        var spellSet :CreatureSpellSet = CreatureSpellSet(e.target);

        var newHilite :MovieClip;
        if (spellSet.isSpellActive(Constants.SPELL_TYPE_BLOODLUST)) {
            newHilite = _bloodHilite;
        } else if (spellSet.isSpellActive(Constants.SPELL_TYPE_RIGORMORTIS)) {
            newHilite = _rigorHilite;
        } else {
            newHilite = _defaultHilite;
        }

        if (newHilite != _hilite) {
            newHilite.x = _hilite.x;
            newHilite.y = _hilite.y;
            newHilite.visible = _hilite.visible;

            var parent :DisplayObjectContainer = _hilite.parent;
            var index :int = parent.getChildIndex(_hilite);
            parent.removeChildAt(index);
            parent.addChildAt(newHilite, index);

            newHilite.gotoAndStop(_available ? "on" : "off");

            _hilite = newHilite;
        }
    }

    protected function onClicked (...ignored) :void
    {
        if (_enabled) {
            _switch.gotoAndPlay("deploy");
            _hilite.gotoAndPlay("deploy");
            _multiplicity.visible = false;

            GameCtx.gameMode.localPlayerPurchasedCreature(_unitType);

            addNamedTask(
                DEPLOY_ANIM_TASK_NAME,
                After(DEPLOY_ANIM_LENGTH,
                    new FunctionTask(playSwitchHiliteAnimation)),
                true);
        }
    }

    protected function playSwitchHiliteAnimation () :void
    {
        if (_enabled) {
            _switch.gotoAndPlay("activate");
        } else {
            _switch.gotoAndStop("off");
        }

        _hilite.gotoAndStop(_available ? "on" : "off");
        _multiplicity.visible = _available;
    }

    protected function updateDisplayState () :void
    {
        /*if (_enabled) {
            if (null != _disabledAnim.parent) {
                _unitDisplay.removeChild(_disabledAnim);
            }
            _unitDisplay.addChild(_enabledAnim);
        } else {
            if (null != _enabledAnim.parent) {
                _unitDisplay.removeChild(_enabledAnim);
            }
            _unitDisplay.addChild(_disabledAnim);
        }*/
        _animView.anim = (_enabled ? _enabledAnim : _disabledAnim);
        _button.enabled = _enabled;

        // if we're playing the deploy animation, these animations
        // will get played automatically when it has completed
        if (!this.playingDeployAnimation) {
            playSwitchHiliteAnimation();
        }
    }

    override protected function update (dt :Number) :void
    {
        var playerInfo :LocalPlayerInfo = GameCtx.localPlayerInfo;
        var res1Amount :int = playerInfo.getResourceAmount(_resource1Type);
        var res2Amount :int = playerInfo.getResourceAmount(_resource2Type);

        var available :Boolean = (playerInfo.isAlive && res1Amount >= _resource1Cost && res2Amount >= _resource2Cost);
        var enabled :Boolean = (_available && GameCtx.diurnalCycle.isNight);
        if (available != _available || enabled != _enabled) {
            _available = available;
            _enabled = enabled;
            updateDisplayState();
        }

        if (res1Amount == _lastResource1Amount && res2Amount == _lastResource2Amount) {
            // don't update if nothing has changed
            return;
        }

        var numAvailableUnits :int = Math.min(
            Math.floor(res1Amount / _resource1Cost),
            Math.floor(res2Amount / _resource2Cost));

        if (_available) {
            _multiplicity.text = String(numAvailableUnits);
        }

        // update all the meters
        for (var i :int = 0; i < 2; ++i) {
            var availableResources :int;
            var meterArray :Array;
            if (i == 0) {
                availableResources = res1Amount - (numAvailableUnits * _resource1Cost);
                meterArray = _resource1Meters;
            } else {
                availableResources = res2Amount - (numAvailableUnits * _resource2Cost);
                meterArray = _resource2Meters;
            }

            for each (var meter :ResourceMeter in meterArray) {
                var thisMeterVal :int = Math.min(availableResources, meter.maxValue);
                meter.update(thisMeterVal);
                availableResources = Math.max(availableResources - thisMeterVal, 0);
            }
        }
    }

    protected function createPurchaseMeters () :void
    {
        var resource1Bitmap :BitmapData = ClientCtx.getSwfBitmapData("dashboard",
            RESOURCE_BITMAP_NAMES[_resource1Type], 18, 18);
        var resource2Bitmap :BitmapData = ClientCtx.getSwfBitmapData("dashboard",
            RESOURCE_BITMAP_NAMES[_resource2Type], 18, 18);

        var resource1BgColor :uint = _resource1Data.hiliteColor;
        var resource2BgColor :uint = _resource2Data.hiliteColor;

        var meter :ResourceMeter;
        var meterXOffset :Number = FIRST_METER_LOC.x;
        if (_resource1Cost <= 50 && _resource2Cost <= 50) {
            // use large meters for costs <= 50
            meter = new ResourceMeter(resource1Bitmap, resource1BgColor, true, 0, _resource1Cost);
            meter.x = meterXOffset;
            meter.y = FIRST_METER_LOC.y;
            _resource1Meters.push(meter);
            _progress.addChild(meter);

            meterXOffset += meter.meterWidth;

            meter = new ResourceMeter(resource2Bitmap, resource2BgColor, true, 0, _resource2Cost);
            meter.x = meterXOffset;
            meter.y = FIRST_METER_LOC.y;
            _resource2Meters.push(meter);
            _progress.addChild(meter);

        } else {
            // make a bunch of small meters
            for (var i :int = 0; i < 2; ++i) {
                var totalCost :int;
                var fgBitmap :BitmapData;
                var bgColor :uint;
                var meterArray :Array;
                if (i == 0) {
                    totalCost = _resource1Cost;
                    fgBitmap = resource1Bitmap;
                    bgColor = resource1BgColor;
                    meterArray = _resource1Meters;
                } else {
                    totalCost = _resource2Cost;
                    fgBitmap = resource2Bitmap;
                    bgColor = resource2BgColor;
                    meterArray = _resource2Meters;
                }

                while (totalCost > 0) {
                    var meterMax :int = Math.min(totalCost, ResourceMeter.MAX_MAX_VALUE);
                    meter = new ResourceMeter(fgBitmap, bgColor, false, 0, meterMax);
                    meter.x = meterXOffset;
                    meter.y = FIRST_METER_LOC.y;
                    meterArray.push(meter);
                    _progress.addChild(meter);

                    meterXOffset += meter.meterWidth;
                    totalCost -= meterMax;
                }
            }
        }
    }

    protected function get playingDeployAnimation () :Boolean
    {
        return hasTasksNamed(DEPLOY_ANIM_TASK_NAME);
    }

    protected var _unitType :int;
    protected var _unitData :UnitData;

    protected var _switch :MovieClip;
    protected var _costs :MovieClip;
    protected var _hilite :MovieClip;
    protected var _defaultHilite :MovieClip;
    protected var _bloodHilite :MovieClip;
    protected var _rigorHilite :MovieClip;
    protected var _unitDisplay :MovieClip;
    protected var _progress :MovieClip;
    protected var _button :SimpleButton;
    protected var _multiplicity :TextField;

    //protected var _enabledAnim :MovieClip;
    //protected var _disabledAnim :MovieClip;
    protected var _enabledAnim :BitmapAnim;
    protected var _disabledAnim :BitmapAnim;
    protected var _animView :BitmapAnimView;

    protected var _resource1Type :int;
    protected var _resource2Type :int;
    protected var _resource1Cost :int;
    protected var _resource2Cost :int;
    protected var _resource1Data :ResourceData;
    protected var _resource2Data :ResourceData;
    protected var _lastResource1Amount :int = -1;
    protected var _lastResource2Amount :int = -1;
    protected var _resource1Meters :Array = [];
    protected var _resource2Meters :Array = [];

    // _available is true when the player has enough resources to purchase the
    // creature. _enabled is true if _available is true and it's nighttime.
    // If it's daytime, _available will be true and _enabled will be false.
    protected var _available :Boolean;
    protected var _enabled :Boolean;

    protected static const FIRST_METER_LOC :Point = new Point(-18, -46);
    protected static const DEPLOY_ANIM_LENGTH :Number = 0.7;
    protected static const DEPLOY_ANIM_TASK_NAME :String = "DeployAnimation";
    protected static const RESOURCE_COST_TILES :Array = [ "Ablank", "Bblank", "Cblank", "Dblank" ];
    protected static const RESOURCE_BITMAP_NAMES :Array = [ "flesh", "blood", "energy", "artifice" ];
}

}

import flash.display.Shape;
import flash.display.BitmapData;
import flash.display.Graphics;

class ResourceMeter extends Shape
{
    public static const MAX_MAX_VALUE :int = 50;
    public static const MAX_HEIGHT :int = 46;

    public function ResourceMeter (fgBitmap :BitmapData, bgColor :uint, isLarge :Boolean,
        value :int, maxValue :int)
    {
        _fgBitmap = fgBitmap;
        _bgColor = bgColor;
        _width = (isLarge ? LG_WIDTH : SM_WIDTH);
        _maxValue = maxValue;

        _totalHeight = (_maxValue / MAX_MAX_VALUE) * MAX_HEIGHT;

        update(value);
    }

    public function update (newValue :int) :void
    {
        if (_value == newValue) {
            return;
        }

        _value = newValue

        var percentFill :Number = _value / _maxValue;
        var fgHeight :Number = _totalHeight * percentFill;
        var bgHeight :Number = _totalHeight - fgHeight;
        var bgStart :Number = MAX_HEIGHT - _totalHeight;
        var fgStart :Number = bgStart + bgHeight;

        var g :Graphics = this.graphics;
        g.clear();

        if (fgHeight > 0) {
            // draw the fg
            g.beginBitmapFill(_fgBitmap);
            g.lineStyle(1, 0);
            g.drawRect(0, fgStart, _width, fgHeight);
            g.endFill();
        }

        if (bgHeight > 1) {
            // draw the bg
            g.beginFill(_bgColor);
            g.lineStyle(1, 0);
            g.drawRect(0, bgStart, _width, bgHeight);
            g.endFill();
        }
    }

    public function get meterWidth () :int
    {
        return _width;
    }

    public function get maxValue () :int
    {
        return _maxValue;
    }

    protected var _fgBitmap :BitmapData;
    protected var _bgColor :uint;
    protected var _maxValue :int;
    protected var _value :int = -1;
    protected var _width :int;
    protected var _totalHeight :Number;

    protected static const LG_WIDTH :int = 18;
    protected static const SM_WIDTH :int = 3;
}
