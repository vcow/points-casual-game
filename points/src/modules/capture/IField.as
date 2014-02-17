package modules.capture
{
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Интерфейс игрового поля
	 * 
	 */
	
	public interface IField extends IEventDispatcher
	{
		function get col():int;																// Размер поля по горизонтали в столбцах
		function get row():int;																// Размер поля по вертикали в строках
		
		function get matrix():Vector.<Vector.<uint>>;										// Матрица игрового поля
		
		function updateSurround():void;														// Перерисовать окружения
		function setPointType(col:int, row:int, type:int,									// Задать значение точки
							  surroundId:uint=0, flags:uint=0):void;
		
		function getSurrounFlags(col:int, row:int):uint;									// Получить флаги окружений для точки
		
		function set lock(value:Boolean):void;												// Блокировать поле для ввода
		
		function get debug():IDebug;														// Отладочные функции
	}
}