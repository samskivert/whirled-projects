//
// $Id$

package popcraft.gamedata {

import com.threerings.flashbang.resource.ImageResource;
import com.threerings.util.XmlUtil;

import flash.display.DisplayObject;

import popcraft.*;

public class PlayerDisplayData
{
    public var playerName :String;
    public var displayName :String;
    public var headshotName :String;
    public var color :uint;
    public var excludeFromMpBattle :Boolean;

    public function get headshot () :DisplayObject
    {
        return ClientCtx.instantiateBitmap(headshotName);
    }

    public function clone () :PlayerDisplayData
    {
        var theClone :PlayerDisplayData = new PlayerDisplayData();
        theClone.playerName = playerName;
        theClone.displayName = displayName;
        theClone.headshotName = headshotName;
        theClone.excludeFromMpBattle = excludeFromMpBattle;
        theClone.color = color;

        return theClone;
    }

    public static function fromXml (xml :XML, defaults :PlayerDisplayData = null)
        :PlayerDisplayData
    {
        var useDefaults :Boolean = (defaults != null);
        var data :PlayerDisplayData = (useDefaults ? defaults : new PlayerDisplayData());

        data.playerName = XmlUtil.getStringAttr(xml, "name");
        data.displayName = XmlUtil.getStringAttr(xml, "displayName",
            (useDefaults ? defaults.displayName : undefined));
        data.headshotName = XmlUtil.getStringAttr(xml, "headshotName",
            (useDefaults ? defaults.headshotName : undefined));
        data.color = XmlUtil.getUintAttr(xml, "color",
            (useDefaults ? defaults.color : undefined));
        data.excludeFromMpBattle = XmlUtil.getBooleanAttr(xml, "excludeFromMpBattle",
            (useDefaults ? defaults.excludeFromMpBattle : false));

        return data;
    }

    public static function get unknown () :PlayerDisplayData
    {
        if (_unknown == null) {
            _unknown = new PlayerDisplayData();
            _unknown.playerName = "unknown";
            _unknown.displayName = "???";
            _unknown.headshotName = "???";
            _unknown.color = 0;
        }

        return _unknown;
    }

    protected static var _unknown :PlayerDisplayData;
}

}
