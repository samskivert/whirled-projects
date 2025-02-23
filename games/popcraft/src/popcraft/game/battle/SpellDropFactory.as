//
// $Id$

package popcraft.game.battle {

import com.threerings.geom.Vector2;
import com.threerings.flashbang.audio.*;

import popcraft.*;
import popcraft.game.*;
import popcraft.game.battle.view.SpellDropView;

public class SpellDropFactory
{
    public static function createSpellDrop (spellType :int, loc :Vector2, playSound :Boolean)
        :SpellDropView
    {
        var spellDrop :SpellDropObject = new SpellDropObject(spellType);
        spellDrop.x = loc.x;
        spellDrop.y = loc.y;

        GameCtx.netObjects.addObject(spellDrop);

        // create the view after adding the spellDrop to the game, so that its
        // GameObjectRef is valid
        var spellDropView :SpellDropView = new SpellDropView(spellDrop);
        spellDropView.x = loc.x;
        spellDropView.y = loc.y;
        GameCtx.gameMode.addSceneObject(spellDropView, GameCtx.battleBoardView.unitViewParent);

        if (playSound) {
            GameCtx.playGameSound("sfx_spelldrop");
        }

        return spellDropView;
    }
}

}
