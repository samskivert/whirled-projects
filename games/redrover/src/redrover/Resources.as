package redrover {

import com.threerings.flashbang.resource.*;

public class Resources
{
    public static function loadResources (loadCompleteCallback :Function = null,
        loadErrorCallback :Function = null) :void
    {
        var rm :ResourceManager = ClientCtx.rsrcs;

        rm.queueResourceLoad("swf", "uiBits",  { embeddedClass: SWF_UIBITS });
        rm.queueResourceLoad("swf", "grunt", { embeddedClass: SWF_GRUNT });
        rm.queueResourceLoad("swf", "sapper", { embeddedClass: SWF_SAPPER });
        rm.queueResourceLoad("image", "gem", { embeddedClass: IMG_GEM });
        rm.queueResourceLoad("image", "grass", { embeddedClass: IMG_GRASS });
        rm.queueResourceLoad("image", "rock", { embeddedClass: IMG_ROCK });
        rm.queueResourceLoad("image", "gem_redemption", { embeddedClass: IMG_GEMREDEMPTION });
        rm.queueResourceLoad("image", "player_arrow", { embeddedClass: IMG_PLAYERARROW });
        rm.queueResourceLoad("image", "player_shadow", { embeddedClass: IMG_PLAYERSHADOW });
        rm.queueResourceLoad("image", "instructions_1", { embeddedClass: IMG_INSTRUCTIONS1 });
        rm.queueResourceLoad("image", "instructions_2", { embeddedClass: IMG_INSTRUCTIONS2 });
        rm.queueResourceLoad("image", "instructions_3", { embeddedClass: IMG_INSTRUCTIONS3 });

        // music
        rm.queueResourceLoad("sound", "mus_motm",
            { embeddedClass: MUSIC_MOTM, type: "music", priority: 10 });
        rm.queueResourceLoad("sound", "mus_pepperland",
            { embeddedClass: MUSIC_PEPPERLAND, type: "music", priority: 10 });

        // sfx
        rm.queueResourceLoad("sound", "sfx_gem1", { embeddedClass: SOUND_GEM1 });
        rm.queueResourceLoad("sound", "sfx_gem2", { embeddedClass: SOUND_GEM2 });
        rm.queueResourceLoad("sound", "sfx_gem3", { embeddedClass: SOUND_GEM3 });
        rm.queueResourceLoad("sound", "sfx_gem4", { embeddedClass: SOUND_GEM4 });
        rm.queueResourceLoad("sound", "sfx_gem5", { embeddedClass: SOUND_GEM5 });
        rm.queueResourceLoad("sound", "sfx_gem6", { embeddedClass: SOUND_GEM6 });
        rm.queueResourceLoad("sound", "sfx_gem7", { embeddedClass: SOUND_GEM7 });

        rm.queueResourceLoad("sound", "sfx_got_points", { embeddedClass: SOUND_CASH_REGISTER });
        rm.queueResourceLoad("sound", "sfx_eat_player", { embeddedClass: SOUND_DRINK_GULP });

        rm.loadQueuedResources(loadCompleteCallback, loadErrorCallback);
    }

    [Embed(source="../../rsrc/UI_bits.swf", mimeType="application/octet-stream")]
    protected static const SWF_UIBITS :Class;
    [Embed(source="../../rsrc/streetwalker.swf", mimeType="application/octet-stream")]
    protected static const SWF_GRUNT :Class;
    [Embed(source="../../rsrc/runt.swf", mimeType="application/octet-stream")]
    protected static const SWF_SAPPER :Class;
    [Embed(source="../../rsrc/gem.png", mimeType="application/octet-stream")]
    protected static const IMG_GEM :Class;
    [Embed(source="../../rsrc/grass.png", mimeType="application/octet-stream")]
    protected static const IMG_GRASS :Class;
    [Embed(source="../../rsrc/rock.png", mimeType="application/octet-stream")]
    protected static const IMG_ROCK :Class;
    [Embed(source="../../rsrc/gem_redemption.png", mimeType="application/octet-stream")]
    protected static const IMG_GEMREDEMPTION :Class;
    [Embed(source="../../rsrc/player_arrow.png", mimeType="application/octet-stream")]
    protected static const IMG_PLAYERARROW :Class;
    [Embed(source="../../rsrc/player_shadow.png", mimeType="application/octet-stream")]
    protected static const IMG_PLAYERSHADOW :Class;

    [Embed(source="../../rsrc/instructions_1.png", mimeType="application/octet-stream")]
    protected static const IMG_INSTRUCTIONS1 :Class;
    [Embed(source="../../rsrc/instructions_2.png", mimeType="application/octet-stream")]
    protected static const IMG_INSTRUCTIONS2 :Class;
    [Embed(source="../../rsrc/instructions_3.png", mimeType="application/octet-stream")]
    protected static const IMG_INSTRUCTIONS3 :Class;

    [Embed(source="../../rsrc/music/pepperland.mp3")]
    protected static const MUSIC_PEPPERLAND :Class;
    [Embed(source="../../rsrc/music/motm.mp3")]
    protected static const MUSIC_MOTM :Class;

    [Embed(source="../../rsrc/sfx/steelstring.c3.mp3")]
    protected static const SOUND_GEM1 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.d3.mp3")]
    protected static const SOUND_GEM2 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.e3.mp3")]
    protected static const SOUND_GEM3 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.f3.mp3")]
    protected static const SOUND_GEM4 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.g3.mp3")]
    protected static const SOUND_GEM5 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.a3.mp3")]
    protected static const SOUND_GEM6 :Class;
    [Embed(source="../../rsrc/sfx/steelstring.b3.mp3")]
    protected static const SOUND_GEM7 :Class;
    [Embed(source="../../rsrc/sfx/Cash_Register.mp3")]
    protected static const SOUND_CASH_REGISTER :Class;
    [Embed(source="../../rsrc/sfx/Drink_Gulp.mp3")]
    protected static const SOUND_DRINK_GULP :Class;
}

}
