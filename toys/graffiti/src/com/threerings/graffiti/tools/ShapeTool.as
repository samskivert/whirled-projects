// $Id$

package com.threerings.graffiti.tools {

import flash.utils.ByteArray;

import com.threerings.util.HashMap;

public class ShapeTool extends Tool
{
    public function ShapeTool (thickness :int, alpha :Number, borderColor :uint, 
        borderOn :Boolean, fillColor :uint, fillOn :Boolean)
    {
        super(thickness, alpha, borderColor);
        _borderOn = borderOn;
        _fillColor = fillColor;
        _fillOn = fillOn;
    }

    // from Equalable
    override public function equals (other :Object) :Boolean
    {
        if (!(other is ShapeTool)) {
            return false;
        }

        var otherShape :ShapeTool = other as ShapeTool;
        return super.equals(other) && otherShape._borderOn == _borderOn &&
            otherShape._fillColor == _fillColor && otherShape._fillOn == _fillOn;
    }

    override public function serialize (bytes :ByteArray, colorLUT :HashMap) :void
    {
        super.serialize(bytes, colorLUT);
        bytes.writeBoolean(_borderOn);
        writeColor(_fillColor, bytes, colorLUT);
        bytes.writeBoolean(_fillOn);
    }

    override protected function deserialize (bytes :ByteArray, colorLUT :Array) :void
    {
        super.deserialize(bytes, colorLUT);
        _borderOn = bytes.readBoolean();
        _fillColor = readColor(bytes, colorLUT);
        _fillOn = bytes.readBoolean();
    }

    protected var _borderOn :Boolean;
    protected var _fillColor :uint;
    protected var _fillOn :Boolean;
}
}
