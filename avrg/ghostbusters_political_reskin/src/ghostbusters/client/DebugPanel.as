//
// $Id$

package ghostbusters.client {

import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;

import flash.text.TextField;

import com.threerings.util.StringUtil;

import com.whirled.avrg.AVRGamePlayerEvent;
import com.whirled.net.ElementChangedEvent;
import com.whirled.net.PropertyChangedEvent;

import ghostbusters.data.Codes;

public class DebugPanel extends Sprite
{
    public function DebugPanel ()
    {
        _bits = new TextBits();
        this.addChild(_bits);

        this.opaqueBackground = 0x662211;
        this.alpha = 0.5;

        addEventListener(Event.ADDED_TO_STAGE, handleAdded);
        addEventListener(Event.REMOVED_FROM_STAGE, handleRemoved);

        _bits.addButton("Lev+", false, function () :void { dbg(Codes.DBG_LEVEL_UP); });
        _bits.addButton("Lev-", false, function () :void { dbg(Codes.DBG_LEVEL_DOWN); });
        _bits.addButton("Skip", true, function () :void { dbg(Codes.DBG_END_STATE); });
        _bits.addButton("Reset", true, function () :void { dbg(Codes.DBG_RESET_ROOM); });

        updateDisplay();
    }

    protected function handleAdded (evt :Event) :void
    {
        Game.control.room.props.addEventListener(
            PropertyChangedEvent.PROPERTY_CHANGED, updateDisplay);
        Game.control.room.props.addEventListener(
            ElementChangedEvent.ELEMENT_CHANGED, updateDisplay);
        Game.control.player.addEventListener(
            AVRGamePlayerEvent.ENTERED_ROOM, updateDisplay);
    }

    protected function handleRemoved (evt :Event) :void
    {
        Game.control.room.props.removeEventListener(
            PropertyChangedEvent.PROPERTY_CHANGED, updateDisplay);
        Game.control.room.props.removeEventListener(
            ElementChangedEvent.ELEMENT_CHANGED, updateDisplay);
        Game.control.player.removeEventListener(
            AVRGamePlayerEvent.ENTERED_ROOM, updateDisplay);
    }

    protected function updateDisplay (... ignored) :void
    {
        var result :String = "{ ";
        for each (var key :String in Game.control.room.props.getPropertyNames()) {
            if (result.length > 2) {
                result += ", ";
            }
            result += key + ": " + StringUtil.toString(Game.control.room.props.get(key));
        }
        result += " }";

        _bits.text = result;
    }

    protected function dbg (request :String) :void
    {
        Game.control.agent.sendMessage(Codes.CMSG_DEBUG_REQUEST, request);
    }

    protected var _bits :TextBits;
}
}
