package redrover.data {

import com.threerings.util.StringUtil;
import com.threerings.flashbang.util.NumRange;
import com.threerings.flashbang.util.Rand;
import com.threerings.util.XmlUtil;
import com.threerings.util.XmlReadError;

import redrover.*;
import redrover.util.IntValueTable;

public class LevelData
{
    public var endCondition :int;
    public var endValue :int;
    public var cellSize :int;
    public var ownBoardZoom :Number;
    public var otherBoardZoom :Number;
    public var gemSpawnTime :NumRange = new NumRange(0, 0, Rand.STREAM_GAME);
    public var ownBoardSpeedBase :Number;
    public var otherBoardSpeedBase :Number;
    public var speedOffsetPerGem :Number;
    public var slowTerrainSpeedMultiplier :Number;
    public var maxTurnOvershoot :Number;
    public var maxCarriedGems :int;
    public var switchBoardsTime :Number;
    public var gotEatenTime :Number;
    public var returnHomeGemsMin :int;
    public var eatPlayerPoints :int;
    public var switchedBoardsInvincibleTime :Number;
    public var teammateScoreMultiplier :Number;

    public var gemValues :IntValueTable;
    public var playerColors :Array = [];
    public var maleRobotNames :Array = [];
    public var femaleRobotNames :Array = [];

    public var terrain :Array = [];
    public var objects :Array = [];
    public var cols :int;
    public var rows :int;

    public static function fromXml (xml :XML) :LevelData
    {
        var data :LevelData = new LevelData();

        data.endCondition = XmlUtil.getStringArrayAttr(xml, "endCondition",
            Constants.END_CONDITION_NAMES);
        data.endValue = XmlUtil.getNumberAttr(xml, "endValue");
        data.cellSize = XmlUtil.getUintAttr(xml, "cellSize");
        data.ownBoardZoom = XmlUtil.getNumberAttr(xml, "ownBoardZoom");
        data.otherBoardZoom = XmlUtil.getNumberAttr(xml, "otherBoardZoom");
        data.gemSpawnTime.min = XmlUtil.getUintAttr(xml, "gemSpawnTimeMin");
        data.gemSpawnTime.max = XmlUtil.getUintAttr(xml, "gemSpawnTimeMax");
        data.ownBoardSpeedBase = XmlUtil.getNumberAttr(xml, "ownBoardSpeedBase");
        data.otherBoardSpeedBase = XmlUtil.getNumberAttr(xml, "otherBoardSpeedBase");
        data.speedOffsetPerGem = XmlUtil.getNumberAttr(xml, "speedOffsetPerGem");
        data.slowTerrainSpeedMultiplier = XmlUtil.getNumberAttr(xml, "slowTerrainSpeedMultiplier");
        data.maxTurnOvershoot = XmlUtil.getNumberAttr(xml, "maxTurnOvershoot");
        data.maxCarriedGems = XmlUtil.getUintAttr(xml, "maxCarriedGems");
        data.switchBoardsTime = XmlUtil.getNumberAttr(xml, "switchBoardsTime");
        data.gotEatenTime = XmlUtil.getNumberAttr(xml, "gotEatenTime");
        data.returnHomeGemsMin = XmlUtil.getUintAttr(xml, "returnHomeGemsMin");
        data.eatPlayerPoints = XmlUtil.getIntAttr(xml, "eatPlayerPoints");
        data.switchedBoardsInvincibleTime = XmlUtil.getNumberAttr(xml,
            "switchedBoardsInvincibleTime");
        data.teammateScoreMultiplier = XmlUtil.getNumberAttr(xml, "teammateScoreMultiplier");

        data.gemValues = IntValueTable.fromXml(XmlUtil.getSingleChild(xml, "GemValues"));

        for each (var colorXml :XML in xml.PlayerColors.Color) {
            data.playerColors.push(XmlUtil.getUintAttr(colorXml, "value"));
        }

        for each (var nameXml :XML in xml.MaleRobotNames.Name) {
            data.maleRobotNames.push(XmlUtil.getStringAttr(nameXml, "value"));
        }

        for each (nameXml in xml.FemaleRobotNames.Name) {
            data.femaleRobotNames.push(XmlUtil.getStringAttr(nameXml, "value"));
        }

        parseTerrainString(xml.Terrain, data);
        parseObjectString(xml.Objects, data);

        return data;
    }

    protected static function parseTerrainString (str :String, data :LevelData) :void
    {
        // eat any whitespace at the beginning and end of the string
        str = StringUtil.trim(str);

        // split into lines
        var rows :Array = str.split("\n");
        if (rows.length == 0) {
            throw new XmlReadError("No Terrain!");
        }

        data.cols = getRowWidth(rows[0]);
        data.rows = rows.length;

        for each (var row :String in rows) {
            if (getRowWidth(row) != data.cols) {
                throw new XmlReadError("All Terrain rows must be the same width!");
            }

            for (var ii :int = 0; ii < row.length; ++ii) {
                var char :String = row.charAt(ii);
                if (StringUtil.isWhitespace(char)) {
                    continue;
                }

                var terrainType :int = getTerrainType(char);
                if (terrainType < 0) {
                    throw new XmlReadError("Unrecognized terrain type: " + char);
                }

                data.terrain.push(terrainType);
            }
        }
    }

    protected static function parseObjectString (str :String, data :LevelData) :void
    {
        str = StringUtil.trim(str);
        var rows :Array = str.split("\n");
        if (rows.length != data.rows) {
            throw new XmlReadError("Bad number of Objects rows (expected=" + data.rows +
                                   ", got=" + rows.length + ")");
        }

        var yy :int = 0;
        for each (var row :String in rows) {
            if (getRowWidth(row) != data.cols) {
                throw new XmlReadError("All Objects rows must be the same width!");
            }

            var xx :int = 0;
            for (var ii :int = 0; ii < row.length; ++ii) {
                var char :String = row.charAt(ii);
                if (StringUtil.isWhitespace(char)) {
                    continue;
                }

                if (char != "." && char != '#') {
                    var objType :int = getObjectType(char);
                    if (objType < 0) {
                        throw new XmlReadError("Unrecognized object type: " + char);
                    }

                    data.objects.push(new LevelObjData(xx, yy, objType));
                }

                ++xx;
            }

            ++yy;
        }
    }

    protected static function getRowWidth (line :String) :int
    {
        // Count all non-whitespace characters in the line
        var length :int;
        for (var ii :int = 0; ii < line.length; ++ii) {
            if (!StringUtil.isWhitespace(line.charAt(ii))) {
                length++;
            }
        }

        return length;
    }

    protected static function getTerrainType (char :String) :int
    {
        for (var type :int = 0; type < Constants.TERRAIN_SYMBOLS.length; ++type) {
            if (Constants.TERRAIN_SYMBOLS[type] == char) {
                return type;
            }
        }

        return -1;
    }

    protected static function getObjectType (char :String) :int
    {
        for (var type :int = 0; type < Constants.OBJ_SYMBOLS.length; ++type) {
            if (Constants.OBJ_SYMBOLS[type] == char) {
                return type;
            }
        }

        return -1;
    }
}

}
