//
// $Id$

package popcraft.game.battle.ai {

import com.threerings.geom.Vector2;
import com.threerings.flashbang.*;

import popcraft.*;
import popcraft.game.battle.*;
import popcraft.gamedata.*;

public class AttackUnitTask extends MoveToLocationTask
{
    public static const NAME :String = "AttackUnit";

    public function AttackUnitTask (
        unitRef :GameObjectRef,
        followUnit :Boolean,
        loseInterestRange :Number,
        disableCollisionsAfter :Number = -1,
        disableCollisionsTime :Number = 0.5)
    {
        // MoveToLocationTask's "moveToLoc" will be set to a reasonable value
        // when this task updates
        super(NAME, new Vector2(), 0, disableCollisionsAfter, disableCollisionsTime);

        _unitRef = unitRef;
        _followUnit = followUnit;
        _loseInterestRange = loseInterestRange;
    }

    override public function update (dt :Number, unit :CreatureUnit) :AITaskStatus
    {
        // is the enemy dead?
        // (or has it turned invincible, in which case attacking it is futile?)
        var enemy :Unit = _unitRef.object as Unit;
        if (null == enemy || enemy.isInvincible) {
            return AITaskStatus.COMPLETE;
        }

        var weapon :UnitWeaponData = unit.unitData.weapon;
        if (unit.canAttackWithWeapon(enemy, weapon)) {
            unit.sendAttack(enemy, weapon);
            return AITaskStatus.INCOMPLETE;

        } else if (_followUnit && !shouldLoseInterest(unit, enemy)) {
            // get closer to the enemy (via MoveToLocationTask, our super class)
            moveToLoc = unit.findNearestAttackLocation(enemy, weapon);
            super.update(dt, unit);
            return AITaskStatus.INCOMPLETE;

        } else {
            // we've lost interest
            return AITaskStatus.COMPLETE;
        }
    }

    protected function shouldLoseInterest (unit :CreatureUnit, enemy :Unit) :Boolean
    {
        return (_loseInterestRange > 0 && !unit.isUnitInRange(enemy, _loseInterestRange));
    }

    override public function get name () :String
    {
        return NAME;
    }

    protected var _unitRef :GameObjectRef;
    protected var _followUnit :Boolean;
    protected var _loseInterestRange :Number;
}

}
