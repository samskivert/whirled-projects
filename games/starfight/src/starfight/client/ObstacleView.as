package starfight.client {

import com.threerings.util.Log;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.media.Sound;
import flash.utils.getTimer;

import starfight.*;

public class ObstacleView extends Sprite
{
    public static function getHitSound (type :int) :Sound
    {
        switch (type) {
        case Obstacle.ASTEROID_1:
        case Obstacle.ASTEROID_2:
            return Resources.getSound("asteroid_hit.wav");
        case Obstacle.JUNK:
            return Resources.getSound("junk_hit.wav");
        case Obstacle.WALL:
        default:
            return Resources.getSound("metal_hit.wav");
        }
    }

    public function ObstacleView (obstacle :Obstacle)
    {
        _obstacle = obstacle;
        _obstacle.addEventListener(Obstacle.COLLIDED, onCollided);

        setupGraphics();

        x = _obstacle.bX * Constants.PIXELS_PER_TILE;
        y = _obstacle.bY * Constants.PIXELS_PER_TILE;
        if (_obstacle.type != Obstacle.WALL) {
            x += Constants.PIXELS_PER_TILE * 0.5;
            y += Constants.PIXELS_PER_TILE * 0.5;
        }
    }

    public function tick (time :int) :void
    {
        if (_obstacle.type != Obstacle.WALL) {
            rotation = (rotation + (360 * time / 10000)) % 360;
        }
    }

    protected function setupGraphics () :void
    {
        if (_obstacle.type == Obstacle.WALL) {
            if (_obstacle.w == 0 || _obstacle.h == 0) {
                return;
            }
            var data :BitmapData = new BitmapData(
                    _obstacle.w * Constants.PIXELS_PER_TILE, _obstacle.h * Constants.PIXELS_PER_TILE);
            var drawData :BitmapData = Resources.getBitmapData("box_bitmap.gif");
            var matrix :Matrix;
            for (var yy :int = 0; yy < _obstacle.h; yy++) {
                for (var xx :int = 0; xx < _obstacle.w; xx++) {
                    matrix = new Matrix();
                    matrix.translate(xx * Constants.PIXELS_PER_TILE, yy * Constants.PIXELS_PER_TILE);
                    data.draw(drawData, matrix);
                }
            }
            addChild(new Bitmap(data));
        } else {
            var obsMovie :MovieClip =
                MovieClip(new (Resources.getClass(OBS_MOVIES[_obstacle.type]))());
            addChild(obsMovie);
            rotation = Math.random()*360;
        }
    }

    public function explode (...ignored) :void
    {
        if (OBS_EXPLODE[_obstacle.type] == null) {
            if (null != this.parent) {
                this.parent.removeChild(this);
            }

        } else {
            removeChildAt(0);
            var obsMovie :MovieClip =
                MovieClip(new (Resources.getClass(OBS_EXPLODE[_obstacle.type]))());
            addChild(obsMovie);

            // remove self from the displaylist when the explode movie completes
            var thisObstacleView :ObstacleView = this;
            obsMovie.addEventListener(Event.COMPLETE, function (event :Event) :void {
                obsMovie.removeEventListener(Event.COMPLETE, arguments.callee);
                if (null != thisObstacleView.parent) {
                     thisObstacleView.parent.removeChild(thisObstacleView);
                }
            });
        }
    }

    protected function onCollided (...ignored) :void
    {
        var time :int = flash.utils.getTimer();
        if (time - _lastCollisionSoundTime >= MIN_COLLISION_SOUND_MS) {
            var sound :Sound = getCollisionSound(_obstacle.type);
            if (sound != null) {
                ClientContext.game.playSoundAt(sound, _obstacle.bX, _obstacle.bY);
                _lastCollisionSoundTime = time;
            }
        }
    }

    protected static function getCollisionSound (type :int) :Sound
    {
        switch (type) {
        case Obstacle.ASTEROID_1:
        case Obstacle.ASTEROID_2:
            return Resources.getSound("collision_asteroid2.wav");
        case Obstacle.JUNK:
            return Resources.getSound("collision_junk.wav");
        case Obstacle.WALL:
        default:
            return Resources.getSound("collision_metal3.wav");
        }
    }

    protected var _obstacle :Obstacle;

    protected static var _lastCollisionSoundTime :int;

    protected static const log :Log = Log.getLog(ObstacleView);

    protected static const MIN_COLLISION_SOUND_MS :int = 200;

    protected static const OBS_MOVIES :Array = [
        "meteor1", "meteor2", "junk_metal"
    ];
    protected static const OBS_EXPLODE :Array = [
        "asteroid_explosion", "asteroid_explosion", null, null
    ];
}

}
