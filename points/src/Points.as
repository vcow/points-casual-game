package {
	import base.PtsModule;
	
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import modules.ModuleEvent;
	import modules.capture.PtsCaptureModule;
	import modules.start.PtsStartModule;
	
	[SWF(frameRate="25", width="807", height="730", pageTitle="points")]
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Казуальная логическая игра "Точки"
	 * 
	 */
	
	public class Points extends PtsModule
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _currentModule:PtsModule;
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 */
		public function Points()
		{
			super("ROOT_MODULE");
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Переопределенный метод, вызываемый в момент добавления приложения в родительский объект
		 */
		override protected function create():void
		{
			super.create();
			
			// Отслеживать изменение размеров главного окна приложения
			stage.addEventListener(Event.RESIZE, stage_resizeHandler);
			stage_resizeHandler(null);
			
			// Создать первый модуль - стартовый
			var newModule:PtsModule = new PtsStartModule();
			newModule.addEventListener(ModuleEvent.NEXT, start_nextHandler);
			
			// Задать стартовый модуль в качестве начального
			currentModule = newModule;
		}
		
		/**
		 * Переопределенный метод, вызываемый в момент удаления приложения из родительского объекта
		 */
		override protected function destroy():void
		{
			super.destroy();
			
			stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
		}
		
		/**
		 * Переопределенный метод отрисовки приложения
		 */
		override protected function draw():void
		{
			super.draw();
			
			graphics.clear();
			
			graphics.lineStyle(4, 0xFF0000);
			graphics.drawRect(2, 2, width - 4, height - 4);
			graphics.lineStyle();
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/* Игра построена по модульному типу, в каждый момент времени работает только
		   один модуль (не считая самого приложения, которое тоже является модулем).
		   По завершении работы модуля, он рассылает событие NEXT для перехода к следующему
		   модулю, или PREV для перехода к предыдущему. */
		
		/**
		 * Текущий игровой модуль
		 */
		private function set currentModule(value:PtsModule):void
		{
			value.width = stage.stageWidth;
			value.height = stage.stageHeight;
			
			addChild(value);
			
			if (_currentModule && _currentModule.parent == this)
				removeChild(_currentModule);
			
			_currentModule = value;
		}
		
		private function get currentModule():PtsModule
		{
			return _currentModule;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Команда перехода к следующему модулю от стартового модуля
		 * @param event событие
		 */
		private function start_nextHandler(event:ModuleEvent):void
		{
			currentModule.removeEventListener(ModuleEvent.NEXT, start_nextHandler);
			
			// Следующим после стартового модуля будет главный игровой модуль, создаем и назначаем текущим
			var newModule:PtsModule = new PtsCaptureModule(PtsCaptureModule.PVE_MODE);
			newModule.addEventListener(ModuleEvent.NEXT, capture_nextHandler);
			newModule.addEventListener(ModuleEvent.PREVIOUS, capture_prevHandler);
			
			currentModule = newModule;
		}
		
		/**
		 * Команда перехода к следующему модулю от главного игрового
		 * @param event событие
		 */
		private function capture_nextHandler(event:ModuleEvent):void
		{
			// TODO: Execute next module
		}
		
		/**
		 * Команда перехода к предыдущему модулю от главного игрового
		 * @param event событие
		 */
		private function capture_prevHandler(event:ModuleEvent):void
		{
			currentModule.removeEventListener(ModuleEvent.NEXT, capture_nextHandler);
			currentModule.removeEventListener(ModuleEvent.PREVIOUS, capture_prevHandler);
			
			// Предыдущим модулем для главного игрового был стартовый, создаем его и назначаем текущим
			var newModule:PtsModule = new PtsStartModule();
			newModule.addEventListener(ModuleEvent.NEXT, start_nextHandler);
			
			currentModule = newModule;
		}
		
		/**
		 * Изменение размеров окна приложения
		 * @param event событие
		 */
		private function stage_resizeHandler(event:Event):void
		{
			width = stage.stageWidth;
			height = stage.stageHeight;
			
			if (currentModule)
			{
				currentModule.width = width;
				currentModule.height = height;
			}
		}
	}
}
