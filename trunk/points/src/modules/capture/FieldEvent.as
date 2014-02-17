package modules.capture
{
	import flash.events.Event;

	/**
	 * 
	 * @author jvirkovskiy
	 * Событие игрового поля
	 * 
	 */
	
	public class FieldEvent extends Event
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public static const SELECT:String = "selectPoint";
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public var col:int;			// Позиция точки по горизонтали
		public var row:int;			// Позиция точки по вертикали
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public function FieldEvent(type:String, col:int, row:int, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			
			this.col = col;
			this.row = row;
		}
		
		override public function clone():Event
		{
			return new FieldEvent(type, col, row, bubbles, cancelable);
		}
	}
}