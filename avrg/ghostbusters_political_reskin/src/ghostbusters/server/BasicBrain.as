//
// $Id$

package ghostbusters.server {

import ghostbusters.data.Codes;
import ghostbusters.server.Server;

public class BasicBrain
{
    public function BasicBrain (room :Room)
    {
        _room = room;
    }

    public function tick (frames :int) :void//actuall frames, but ticked every second
    {
        if (frames - _lastAttack < 5 * Server.FRAMES_PER_SECOND ) {
            // all attacks have a 5 second cooldown, basically to make sure the animation finished
            return;
        }

        var team :Array = _room.getTeam(true);

        // make sure there's anybody left alive to attack
        if (team.length == 0) {
            return;
        }
        // roll a d20 and determine what happens
        var roll :int = Server.random.nextInt(20);

        switch(roll) {
        case 0: case 1:
            // 10% chance of attacking a single player
            team[Server.random.nextInt(team.length)].damage(_room.ghost.calculateSingleAttack());
            break;

        case 2: case 3:
            // 10% chance of an AE attack
            var dmg :int = _room.ghost.calculateSplashAttack();
            // Splash team with a fixed moderate amount of damage per player
            for (var ii :int = 0; ii < team.length; ii ++) {
                team[ii].damage(dmg);
            }
            break;

        default:
            // 80% chance of doing nothing - return rather than break
            return;
        }

        // remember when the attack happened
        _lastAttack = frames;
    }

    protected var _room :Room;
    protected var _lastAttack :int;
}
}

