package modules.capture
{
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	/**
	 * 
	 * @author jvirkovskiy
	 * Базовый класс для модулей искусственного интеллекта
	 * 
	 */
	
	public class AI extends EventDispatcher
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		protected var _field:IField;			// Игровое поле
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Статическая функция формирования имени точки
		 * @param x координата точки по горизонтали
		 * @param y координата точки по вертикали
		 * @return имя точки
		 */
		public static function getPointName(x:int, y:int):String
		{
			return x + "_" + y;
		}
		
		/**
		 * Статическая функция восстановления точки по ее имени
		 * @param name имя точки
		 * @return восстановленная точка
		 */
		public static function getPointByName(name:String):Pt
		{
			var parts:Array = name.split("_");
			return new Pt(int(parts[0]), int(parts[1]));
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param field игровое поле, для которого создается модуль искусственного интеллекта
		 */
		public function AI(field:IField)
		{
			super(null);
			
			_field = field;
			_field.addEventListener(FieldEvent.SELECT, field_selectPointHandler);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Игровое поле
		 */
		protected function get field():IField
		{
			return _field;
		}
		
		/**
		 * Обработчик выбора игроком точки, может быть переопределен для реализации игровой логики
		 * @param col координата точки по горизонтали
		 * @param row координата точки по вертикали
		 */
		protected function selectPoint(col:int, row:int):void
		{
			trace ("Select point " + col + ":" + row);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Текущий игрок выбрал точку
		 * @param event событие
		 */
		private function field_selectPointHandler(event:FieldEvent):void
		{
			selectPoint(event.col, event.row);
		}
	}
}