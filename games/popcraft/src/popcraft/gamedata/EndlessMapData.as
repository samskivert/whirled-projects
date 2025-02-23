//
// $Id$

package popcraft.gamedata {

import com.threerings.geom.Vector2;
import com.threerings.util.Maps;
import com.threerings.util.Map;
import com.threerings.util.XmlUtil;

import popcraft.*;

public class EndlessMapData
{
    public var gameDataOverride :GameData;
    public var mapSettings :MapSettingsData;

    public var displayName :String;
    public var isSavePoint :Boolean;

    public var multiplierDropLoc :Vector2 = new Vector2();

    public var humans :Map = Maps.newMapOf(String); // Map<PlayerName, EndlessHumanPlayerData>
    public var computers :Array = []; // array of EndlessComputerPlayerDatas

    public static function fromXml (xml :XML) :EndlessMapData
    {
        var data :EndlessMapData = new EndlessMapData();

        // does the level override game data?
        var gameDataOverrideNode :XML = xml.GameDataOverride[0];
        if (null != gameDataOverrideNode) {
            data.gameDataOverride = GameData.fromXml(gameDataOverrideNode,
                                                        ClientCtx.defaultGameData.clone());
        }

        data.mapSettings = MapSettingsData.fromXml(XmlUtil.getSingleChild(xml, "MapSettings"));

        data.displayName = XmlUtil.getStringAttr(xml, "displayName");
        data.isSavePoint = XmlUtil.getBooleanAttr(xml, "isSavePoint");

        for each (var humanXml :XML in xml.HumanPlayers.HumanPlayer) {
            var playerName :String = XmlUtil.getStringAttr(humanXml, "playerName");
            var humanPlayerData :EndlessHumanPlayerData = EndlessHumanPlayerData.fromXml(humanXml);
            data.humans.put(playerName, humanPlayerData);
        }

        var multiplierDropXml :XML = XmlUtil.getSingleChild(xml, "MultiplierDropLocation");
        data.multiplierDropLoc = DataUtil.parseVector2(multiplierDropXml);

        for each (var computerXml :XML in xml.Computer) {
            data.computers.push(EndlessComputerPlayerData.fromXml(computerXml));
        }

        return data;
    }
}

}
