package joingame.modes
{
    import com.threerings.flash.SimpleTextButton;
    import com.threerings.util.*;
    import com.whirled.contrib.simplegame.*;
    import com.whirled.contrib.simplegame.audio.*;
    import com.whirled.contrib.simplegame.net.*;
    import com.whirled.contrib.simplegame.objects.SceneObject;
    import com.whirled.contrib.simplegame.objects.SimpleSceneObject;
    import com.whirled.contrib.simplegame.resource.*;
    import com.whirled.contrib.simplegame.util.*;
    import com.whirled.game.*;
    import com.whirled.net.MessageReceivedEvent;
    
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    
    import joingame.*;
    import joingame.model.*;
    import joingame.net.AllPlayersReadyMessage;
    import joingame.net.StartPlayMessage;
    import joingame.net.StartSinglePlayerGameMessage;
    import joingame.view.*;

    public class SinglePlayerIntroMode extends JoinGameMode
    {
        private static const log :Log = Log.getLog(SinglePlayerIntroMode);
        
        override protected function setup ():void
        {
            super.setup();
            fadeIn();
        }
        override protected function enter ():void
        {
            log.debug("SinglePlayerIntroMode...");
            
            _allPlayersReady = false;
            _startClicked = false;

            AppContext.messageManager.addEventListener(MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);
            
            _bg = ImageResource.instantiateBitmap("INSTRUCTIONS");
            if(_bg != null) {
                _modeLayer.addChild(_bg);
            }
            else {
                trace("!!!!!Background is null!!!");
            }
            
            var swfRoot :MovieClip = MovieClip(SwfResource.getSwfDisplayRoot("UI"));
//            _modeLayer.addChild(swfRoot);
            
            
            var swf :SwfResource = (ResourceManager.instance.getResource("UI") as SwfResource);
            var _intro_panel_Class :Class = swf.getClass("intro_panel");
            
            
            _intro_panel = new SimpleSceneObject( new _intro_panel_Class() );
            addObject( _intro_panel, _modeLayer);
            
//            var controller :GameController = new GameController( modeSprite);
            
            //Add the previous level buttons, if any
            var buttonNames :Array = ["levela", "levelb", "levelc", "leveld"];
            for (var levelBelowMine :int = 1; levelBelowMine <=  buttonNames.length; levelBelowMine++) {
                if( GameContext.playerCookieData.highestRobotLevelDefeated - levelBelowMine > 0) {
                    var selectedLevel :int = GameContext.playerCookieData.highestRobotLevelDefeated - levelBelowMine;
                    var selectPreviousLevelButton :MovieClip = MovieClip(_intro_panel.displayObject[buttonNames[ levelBelowMine - 1]]);
                    selectPreviousLevelButton.level_name.text = "Level " + selectedLevel;
                    selectPreviousLevelButton.level_name.   selectable = false;
                    Command.bind(selectPreviousLevelButton, MouseEvent.CLICK, GameController.START_WAVES, [selectedLevel, selectPreviousLevelButton]);
                    Command.bind(selectPreviousLevelButton, MouseEvent.MOUSE_OVER, GameController.MOUSE_OVER, selectPreviousLevelButton);
                    Command.bind(selectPreviousLevelButton, MouseEvent.MOUSE_OUT, GameController.MOUSE_OUT, selectPreviousLevelButton);
                    Command.bind(selectPreviousLevelButton, MouseEvent.MOUSE_DOWN, GameController.MOUSE_DOWN, selectPreviousLevelButton);
                }
            
            }
            
            
            _startWavesButton = MovieClip(_intro_panel.displayObject["start"]);
            _startWavesButton.mouseEnabled = true;
            Command.bind(_startWavesButton, MouseEvent.MOUSE_OVER, GameController.MOUSE_OVER, _startWavesButton);
            Command.bind(_startWavesButton, MouseEvent.MOUSE_OUT, GameController.MOUSE_OUT, _startWavesButton);
            Command.bind(_startWavesButton, MouseEvent.MOUSE_DOWN, GameController.MOUSE_DOWN, _startWavesButton);
            Command.bind(_startWavesButton, MouseEvent.CLICK, GameController.START_WAVES, [GameContext.playerCookieData.highestRobotLevelDefeated, _startWavesButton]);
            _modeLayer.addChild(_startWavesButton);
            
            var startTournmamentButton :MovieClip = MovieClip(_intro_panel.displayObject["tournament"]);
            startTournmamentButton.mouseEnabled = true;
            Command.bind(startTournmamentButton, MouseEvent.MOUSE_OVER, GameController.MOUSE_OVER, startTournmamentButton);
            Command.bind(startTournmamentButton, MouseEvent.MOUSE_OUT, GameController.MOUSE_OUT, startTournmamentButton);
            Command.bind(startTournmamentButton, MouseEvent.MOUSE_DOWN, GameController.MOUSE_DOWN, startTournmamentButton);
            Command.bind(startTournmamentButton, MouseEvent.CLICK, GameController.START_CAMPAIGN_LEVEL, [GameContext.playerCookieData.highestRobotLevelDefeated, startTournmamentButton]);
//            _modeLayer.addChild(startTournmamentButton);
            
            
//            var startWavesButton :SimpleTextButton = new SimpleTextButton("Start waves");
//            startWavesButton.x = 50;
//            startWavesButton.y = 50;
//            startWavesButton.addEventListener(MouseEvent.CLICK, doStartWavesButtonClick);
//            _modeLayer.addChild( startWavesButton );
//            
//            
//            var startWithXOpponentsButton :SimpleTextButton = new SimpleTextButton("Start 10 opponents");
//            startWithXOpponentsButton.x = startWavesButton.x;
//            startWithXOpponentsButton.y = startWavesButton.y + 50;
//            startWithXOpponentsButton.addEventListener(MouseEvent.CLICK, doStartXOpponentsButtonClick);
//            _modeLayer.addChild( startWithXOpponentsButton );
            
            
            
        }
        
        
//        protected function doStartWavesButtonClick( event:MouseEvent ) :void 
//        {
//            var msg :StartSinglePlayerGameMessage = new StartSinglePlayerGameMessage( AppContext.playerId, Constants.SINGLE_PLAYER_GAME_TYPE_WAVES, GameContext.playerCookieData.clone());
//            log.debug("Client sending " + msg);
//            AppContext.messageManager.sendMessage(msg);
//        }
        
//        protected function doStartXOpponentsButtonClick( event:MouseEvent ) :void 
//        {
//            var msg :StartSinglePlayerGameMessage = new StartSinglePlayerGameMessage( AppContext.playerId, Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS, GameContext.playerCookieData.clone());
//            log.debug("Client sending " + msg);
//            AppContext.messageManager.sendMessage(msg);
//        }
        
        
        
        
//        private function mouseClicked( event:MouseEvent ) :void
//        {
//            _startWavesButton.y -= 4;
//            _startClicked = true;
//            log.debug("Client sending " + StartSinglePlayerGameMessage.NAME);
//            AppContext.messageManager.sendMessage(new StartSinglePlayerGameMessage( AppContext.playerId, Constants.SINGLE_PLAYER_GAME_TYPE_WAVES));
//        }
        
        protected function messageReceived (event :MessageReceivedEvent) :void
        {
            log.debug(event.name);
            if (event.value is AllPlayersReadyMessage) {
                handleAllPlayersReady( AllPlayersReadyMessage(event.value) );
            }
            else if (event.value is StartPlayMessage) {
                handleStartPlay( StartPlayMessage(event.value) );
            }
            else {
                log.debug("ignored message: " + event.name);
            }
        }
        
        protected function handleAllPlayersReady (event :AllPlayersReadyMessage) :void
        {
            GameContext.gameModel = new JoinGameModel( AppContext.gameCtrl);
            GameContext.gameModel.setModelMemento( event.model );
            GameContext.gameModel._initialSeatedPlayerIds = GameContext.gameModel.currentSeatingOrder.slice();
            
            fadeOutToMode( new PlayPuzzleMode() );
//            GameContext.mainLoop.unwindToMode( new PlayPuzzleMode());
//            log.debug(ClassUtil.shortClassName(SinglePlayerIntroMode) + " sending " + ClassUtil.shortClassName(PlayerReceivedGameStateMessage));
//            AppContext.messageManager.sendMessage(new PlayerReceivedGameStateMessage(AppContext.playerId));
                
        }
        
        protected function handleStartPlay (event :StartPlayMessage) :void
        {
            fadeOutToMode( new PlayPuzzleMode() );
//            GameContext.mainLoop.unwindToMode(new PlayPuzzleMode());
        }
        
        override protected function exit () :void
        {
            AppContext.messageManager.removeEventListener( MessageReceivedEvent.MESSAGE_RECEIVED, messageReceived);
//            AppContext.messageManager.removeEventListener( AllPlayersReadyMessage.NAME, handleAllPlayersReady);
//            AppContext.messageManager.removeEventListener( StartPlayMessage.NAME, handleStartPlay);
//            _startWavesButton.removeEventListener(MouseEvent.CLICK, mouseClicked);
            super.exit();
        }
        
        override protected function destroy () :void
        {
//            AppContext.messageManager.removeEventListener( AllPlayersReadyMessage.NAME, handleAllPlayersReady);
//            AppContext.messageManager.removeEventListener( StartPlayMessage.NAME, handleStartPlay);
//            _startWavesButton.removeEventListener(MouseEvent.CLICK, mouseClicked);
            super.destroy();
        }
        
        protected var _intro_panel :SceneObject;
        protected var _startWavesButton :MovieClip;
        
        protected var _allPlayersReady :Boolean;
        protected var _startClicked :Boolean;
        
        protected var _bg :DisplayObject;
        
    }
}

//import com.threerings.util.Controller;
//import flash.events.IEventDispatcher;
//import joingame.net.StartSinglePlayerGameMessage;
//import joingame.AppContext;
//import joingame.Constants;
//import joingame.GameContext;
//import flash.display.DisplayObject;
//import flash.filters.ColorMatrixFilter;
//    
//
//class GameController extends Controller
//{
//    public static const START_CAMPAIGN_LEVEL :String = "StartCampainLevel";
//    public static const START_WAVES :String = "StartWaves";
//    public static const MOUSE_DOWN :String = "MouseDown";
//    public static const MOUSE_OVER :String = "MouseOver";
//    public static const MOUSE_OUT :String = "MouseOut";
//    
//    /* See http://www.adobetutorialz.com/articles/1987/1/Color-Matrix */                         
//    protected var myElements_array:Array = [2,0,0,0,-13.5,0,2,0,0,-13.5,0,0,2,0,-13.5,0,0,0,1,0];
//    protected var _myColorMatrix_filter :ColorMatrixFilter = new ColorMatrixFilter(myElements_array);
//    
//    public function GameController(controlledPanel :IEventDispatcher)
//    {
//        setControlledPanel(controlledPanel);
//    }
//    
//    public function handleStartCampainLevel( level :int, button :DisplayObject ) :void
//    {
//        button.y -= 4;
//        var msg :StartSinglePlayerGameMessage = new StartSinglePlayerGameMessage( AppContext.playerId, Constants.SINGLE_PLAYER_GAME_TYPE_CHOOSE_OPPONENTS, GameContext.playerCookieData.clone(), level);
//        GameContext.requestedSinglePlayerLevel = level;
//        AppContext.messageManager.sendMessage(msg);
//    }
//    
//    public function handleStartWaves( level :int, button :DisplayObject ) :void
//    {
//        button.y -= 4;
//        var msg :StartSinglePlayerGameMessage = new StartSinglePlayerGameMessage( AppContext.playerId, Constants.SINGLE_PLAYER_GAME_TYPE_WAVES, GameContext.playerCookieData.clone(), level);
//        GameContext.requestedSinglePlayerLevel = level;
//        AppContext.messageManager.sendMessage(msg);
//    }
//    
//    public function handleMouseDown( button :DisplayObject ) :void 
//    {
//        button.y += 4;
//    }
//    
//    
//    public function handleMouseOver( button :DisplayObject ) :void
//    {
//        button.filters = [_myColorMatrix_filter];
//    }
//    
//    public function handleMouseOut( button :DisplayObject ) :void 
//    {
//        button.filters = [];
//    }
//    
//}