package world
{
	import arithmetic.BoardCoordinates;
	import arithmetic.BoardIterator;
	import arithmetic.Vector;
	
	import cells.CellInteractions;
	
	import flash.events.EventDispatcher;
	
	import interactions.Sabotage;
	import interactions.SabotageEvent;
	
	import items.Item;
	import items.ItemPlayer;
	
	import paths.Path;
	
	import world.arbitration.MovablePlayer;
	import world.arbitration.MoveEvent;
	import world.level.*;
	
	public class Player extends EventDispatcher implements CellInteractions, ItemPlayer, MovablePlayer
	{
		public function Player(id:int, name:String)
		{
			_id = id;
			_name = name;
			_inventory = new Inventory(this);
			addEventListener(MoveEvent.PATH_START, handlePathStart);			
		}

        public function get id () :int 
        {
        	return _id;
        }

        public function enterLevel (level:Level) :void
        {
            _level = level;
            level.playerEnters(this);
            dispatchEvent(new LevelEvent(LevelEvent.LEVEL_ENTERED, level, this)); 
        }

        public function get position () :BoardCoordinates
        {
            return _cell.position;
        }
        
        public function set cell (cell:Cell) :void
        {
        	_cell = cell;
        	Log.debug(this+" dispatching move complete - position "+_cell.position);
        	dispatchEvent(new PlayerEvent(PlayerEvent.MOVE_COMPLETED, this));
        }
        
        public function get cell () :Cell
        {
        	return _cell;
        }
        
        public function proposeMove (coords:BoardCoordinates) :void
        {
        	_level.proposeMove(this, coords);
        }
        
        public function get level () :Level
        {
        	return _level;
        }
        
        /**
         * When movement starts, keep track of it.
         */ 
        public function handlePathStart (event:MoveEvent) :void
        {
        	_path = event.path;
            cell.playerBeginsToDepart();
        }
        
        public function moveComplete (coords:BoardCoordinates) :void
        {
        	Log.debug(this + " completing path "+_path);
            if (_path.finish.equals(coords)) {
            	_level.map(_path.finish);
            	_path = null;
            		
            	// now check whether there are consequences of landing on this cell
            	_level.arriveAt(this, coords);
            	
            	if (position.y == _level.exitRow) {
            	    exit();
            	} 
            	
            	if (position.y < _level.exitRow) {            	    
            	    finishLevel();
            	}
            	
            	// now check whether the player needs to fall
            	if (! cell.grip) {
            	    const sabotaged:Sabotage = cell as Sabotage;
            	    if (sabotaged != null) {
            	        dispatchEvent(new SabotageEvent(SabotageEvent.TRIGGERED, sabotaged, id));
            	    }
            		fall();
            	} 
            } else {
	            Log.warning("move to " + _path.finish + " completed with unexpected endpoint "+coords);
	        }
        }
        
        /**
         * The player has reached the exit row.  The exit move should now begin.
         */ 
        protected function exit () :void
        {
           // the player moves one cell up.
           const path:Path = new Path(Path.CLIMB, cell.position, cell.position.translatedBy(Vector.UP));
           dispatchEvent(new MoveEvent(MoveEvent.PATH_START, this, path));
        }
        
        protected function finishLevel () :void
        {
            Log.debug("dispatching finish level");
            dispatchEvent(new LevelEvent(LevelEvent.LEVEL_COMPLETE, _level, this));
        }
        
        
        /**
         * Start the player off falling.
         */
        protected function fall () :void
        {
        	const bottom:Cell = findBottom();
        	const path:Path = new Path(Path.FALL, cell.position, bottom.position);
            dispatchEvent(new MoveEvent(MoveEvent.PATH_START, this, path));
        }
        
        protected function findBottom () :Cell
        {
            var target:Cell;
            // The player will fall until they reach a cell that they can grip
            const search:BoardIterator = new BoardIterator(cell.position, Vector.DOWN);
            Log.debug ("player starting to fall from "+cell);
            do {
                var test:Cell = cellAt(search.next());
                if (test.grip) {
                    target = test;
                }
            } while (target == null);
            Log.debug ("falling to "+target);
            
            return target;  
        }
        
        public function isMoving () :Boolean
        {
        	return _path != null;
        }
        
        override public function toString () :String
        {
        	return "world player "+_id;
        }
        
        public function canReceiveItem () :Boolean
        {
        	return (! _inventory.full);
        }
        
        public function receiveItem (item:Item) :void
        {
        	const position:int = _inventory.add(item);
        	dispatchEvent(new InventoryEvent(InventoryEvent.RECEIVED, this, item, position));
        	//Log.debug(this+" now holds "+_inventory.contents);
        }
        
        public function useItem (position:int) :void
        {
        	var found:Item = _inventory.item(position);
        	if (found != null) {
        		if (found.isUsableBy(this)) {
        			Log.debug("attempting to use "+found+" at position "+position);
        			found.useBy(this);
        			_inventory.removeItem(position);
        			dispatchEvent(new InventoryEvent(InventoryEvent.USED, this, found, position));
        		} else {
        			Log.debug("item is not usable");
        		}
        	}
        }
        
        public function cellAt (coords:BoardCoordinates) :Cell
        {
        	return _level.cellAt(coords);
        }
        
        public function get startingPosition () :BoardCoordinates
        {
        	return _level.startingPosition;
        }
        
        /**
         * Replace a cell on behalf of this player, and distribute the change to all interested parties.
         */ 
        public function replace (cell:Cell) :void
        {
            if (cell.position == _cell.position) {
            	_cell = cell;
            }
        	_level.replace(cell);
        	cell.distributeState();
        }
        
        public function get name () :String
        {
        	return _name;
        }
        
        public function teleport () :void
        {
        	throw new Error("teleport not implemented yet");
        }
        
        public function get levelNumber () :int
        {
        	return _level.levelNumber;
        }
        
        protected var _name:String;
        protected var _path:Path;
        protected var _cell:Cell;
        protected var _level:Level;
        protected var _id:int;
        protected var _inventory:Inventory;
	}
}