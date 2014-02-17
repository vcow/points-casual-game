package modules.start
{
	import base.PtsModule;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import modules.ModuleEvent;

	/**
	 * 
	 * @author jvirkovskiy
	 * Стартовый модуль, служит для задания начальных настроек игры
	 * 
	 */
	
	public class PtsStartModule extends PtsModule
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var startBn:Sprite = new Sprite();
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/* В настоящий момент стартовый модуль ничего не делает, имеет одну кнопку,
		   с помощью которой запускается главный игровой модуль */
		
		/**
		 * Конструктор
		 */
		public function PtsStartModule()
		{
			super("START_MODULE");
			
			startBn.graphics.beginFill(0xff0000);
			startBn.graphics.drawRect(0, 0, 50, 21);
			startBn.graphics.endFill();
			startBn.useHandCursor = true;
			startBn.buttonMode = true;
			
			var bnTxt:TextField = new TextField();
			bnTxt.defaultTextFormat = new TextFormat("Arial", 12, 0x000000, true, false, false, null, null, "center");
			bnTxt.width = 50;
			bnTxt.height = 21;
			bnTxt.text = "Старт!";
			bnTxt.selectable = false;
			bnTxt.mouseEnabled = false;
			
			startBn.addChild(bnTxt);
			
			startBn.addEventListener(MouseEvent.CLICK, start_clickHandler);
			
			addChild(startBn);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		override protected function draw():void
		{
			super.draw();
			
			startBn.x = int((width - 50) / 2);
			startBn.y = int((height - 21) / 2);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private function start_clickHandler(event:MouseEvent):void
		{
			dispatchEvent(new ModuleEvent(ModuleEvent.NEXT));
		}
	}
}