package modules.capture
{
	import base.PtsModule;
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Главный игровой модуль, отвечает за отображение игрового поля
	 * и логику игры
	 * 
	 */
	
	public class PtsCaptureModule extends PtsModule
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		// Режимы игры
		public static const PVP_MODE:String = "pvp";				// игрок против игрока
		public static const PVE_MODE:String = "pve";				// игрок против машины
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _fieldUi:FieldUI = new FieldUI(30, 30);			// Игровое поле
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param mode режим игры (PVP/PVE)
		 */
		public function PtsCaptureModule(mode:String)
		{
			super("CAPTURE_MODULE");
			
			addChild(_fieldUi);
			
			var ai:AI;
			switch (mode)
			{
				case PVP_MODE:
					ai = new PVPAI(_fieldUi);
					break;
				case PVE_MODE:
					ai = new PVEAI(_fieldUi);
					break;
				default:
					throw (Error("Unexpected Capture minigame type (PVP/PVE)"));
			}
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
	}
}