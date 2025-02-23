package actions
{
	import arithmetic.GraphicCoordinates;
	
	import world.Cell;
	
	public interface MoveInteractions
	{
		function get cell () :Cell
				
		/**
		 * Called at the end of a motion between cells.
		 */
		function arriveInCell (cell:Cell) :void
	
		/**
		 * Must be called when a move is over.
		 */
		function actionComplete () :void
	}
}