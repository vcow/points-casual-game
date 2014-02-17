package modules.capture
{
	/**
	 * 
	 * @author jvirkovskiy
	 * Отладочные функции для игрового поля
	 * 
	 */
	
	public interface IDebug
	{
		function markPoint(pt:Pt, color:uint):void;					// Пометить точку цветом
		function markPointAt(x:int, y:int, color:uint):void;		// Пометить точку в позиции цветом
		
		function signPoint(pt:Pt, text:String):void;				// Пометить точку текстом
		function signPointAt(x:int, y:int, text:String):void;		// Пометить точку в позиции текстом
		
		function clearMarkers():void;								// Стереть все маркеры
	}
}