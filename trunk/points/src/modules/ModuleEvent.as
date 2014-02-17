package modules
{
	import flash.events.Event;

	/**
	 * 
	 * @author jvirkovskiy
	 * Событие игрового модуля
	 * 
	 */
	
	public class ModuleEvent extends Event
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public static const NEXT:String = "next";
		public static const PREVIOUS:String = "previous";
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public var data:Object;
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public function ModuleEvent(type:String, data:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
		
		override public function clone():Event
		{
			return new ModuleEvent(type, data, bubbles, cancelable);
		}
	}
}