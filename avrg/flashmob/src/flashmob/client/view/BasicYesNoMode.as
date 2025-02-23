package flashmob.client.view {

import com.whirled.contrib.simplegame.AppMode;
import com.whirled.contrib.simplegame.audio.AudioManager;
import com.whirled.contrib.simplegame.resource.SwfResource;

import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;

import flashmob.client.*;

public class BasicYesNoMode extends AppMode
{
    public function BasicYesNoMode (text :String, yesHandler :Function, noHandler :Function)
    {
        _text = text;
        _yesHandler = yesHandler;
        _noHandler = noHandler;
    }

    override protected function setup () :void
    {
        var screenBounds :Rectangle = SpaceUtil.roomDisplayBounds;
        var g :Graphics = _modeSprite.graphics;
        g.beginFill(0, 0.5);
        g.drawRect(screenBounds.left, screenBounds.top, screenBounds.width, screenBounds.height);
        g.endFill();

        var roomBounds :Rectangle = SpaceUtil.roomDisplayBounds;
        var window :MovieClip = SwfResource.instantiateMovieClip(ClientCtx.rsrcs, "Spectacle_UI", "leavingparty");
        window.x = roomBounds.width * 0.5;
        window.y = roomBounds.height * 0.5;
        _modeSprite.addChild(window);

        // make it draggable
        addObject(new Dragger(window["dragleaveparty"], window));

        // we don't need the close button
        var closeButton :SimpleButton = window["close"];
        closeButton.visible = false;

        var tf :TextField = window["text"];
        tf.text = _text;

        var yesButton :SimpleButton = window["yes_button"];
        registerOneShotCallback(yesButton, MouseEvent.CLICK, _yesHandler);

        var noButton :SimpleButton = window["no_button"];
        registerOneShotCallback(noButton, MouseEvent.CLICK, _noHandler);
    }

    override protected function enter () :void
    {
        super.enter();
        if (!_playedSound) {
            ClientCtx.audio.playSoundNamed("fail");
            _playedSound = true;
        }
    }

    protected var _text :String;
    protected var _yesHandler :Function;
    protected var _noHandler :Function;
    protected var _playedSound :Boolean;
}

}
