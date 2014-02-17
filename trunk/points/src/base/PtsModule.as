package base
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	[Event(name="next", type="modules.ModuleEvent")]
	[Event(name="previous", type="modules.ModuleEvent")]
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Базовый класс для всех игровых модулей
	 * 
	 */
	public class PtsModule extends Sprite
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _moduleName:String;						// Имя модуля
		
		private var _invalidDisplayList:Boolean = true;		// Флаг, указывающий на необходимость обновления модуля
		
		private var _width:Number;							// Номинальная ширина модуля
		private var _height:Number;							// Номинальная высота модуля
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param moduleName имя модуля
		 */
		public function PtsModule(moduleName:String)
		{
			super();
			
			_moduleName = moduleName;
			
			addEventListener(Event.ADDED, addedHandler);
			addEventListener(Event.REMOVED, removedHandler);
			addEventListener(Event.RESIZE, resizeHandler);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Имя модуля
		 */
		public function get moduleName():String
		{
			return _moduleName;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Этот метод автоматически вызывается при добавлении модуля в сцену,
		 * может быть переопределен для начальной инициализации
		 */
		protected function create():void
		{
			trace ("create module " + _moduleName);
		}
		
		/**
		 * Этот метод автоматически вызывается при удалении модуля со сцены,
		 * может быть переопределен для корректного завершения действия модуля
		 */
		protected function destroy():void
		{
			trace ("destroy module " + _moduleName);
		}
		
		/**
		 * Этот метод вызывается при перерисовке модуля, которая может происходить,
		 * например, при ресайзе окна, может быть переопределен для реализации
		 * правильного функционирования "резиновых" интерфейсов
		 */
		protected function draw():void
		{
			trace ("draw module " + _moduleName + "; w = " + width + ", h = " + height);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Переопределенное значение ширины модуля
		 */
		override public function set width(value:Number):void
		{
			_invalidDisplayList ||= value != _width;
			_width = value;
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		/**
		 * Переопределенное значение высоты модуля
		 */
		override public function set height(value:Number):void
		{
			_invalidDisplayList ||= value != _height;
			_height = value;
		}
		
		override public function get height():Number
		{
			return _height;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Модуль добавлен в родительский объект
		 * @param event событие
		 */
		private function addedHandler(event:Event):void
		{
			if (event.currentTarget != this ||
				event.currentTarget != event.target)
				return;
			
			create();
			_invalidDisplayList = true;
		}
		
		/**
		 * Модуль удален из родительского объекта
		 * @param event событие
		 */
		private function removedHandler(event:Event):void
		{
			if (event.currentTarget != this ||
				event.currentTarget != event.target)
				return;
			
			destroy();
		}
		
		/**
		 * Изменение размеров модуля
		 * @param event событие
		 */
		private function resizeHandler(event:Event):void
		{
			_invalidDisplayList = true;
		}
		
		/**
		 * Обработчик смены кадров, который используется для отслеживания момента
		 * перерисовки модуля вследствие изменения размеров или по иным причинам
		 * @param event сообытие
		 */
		private function enterFrameHandler(event:Event):void
		{
			if (_invalidDisplayList && !isNaN(_width) && !isNaN(_height))
			{
				draw();
				_invalidDisplayList = false;
			}
		}
	}
}