package modules.capture
{
	import flash.utils.Dictionary;

	/**
	 * 
	 * @author jvirkovskiy
	 * Класс-хранилище данных для результатов окружения
	 * 
	 */
	
	public class SurrResult
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public var surround:Vector.<Pt>;		// Список точек, участвующих в окружении
		public var result:Dictionary;			// Словарь массивов окруженных вражеских точек
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		public function SurrResult(surround:Vector.<Pt>, result:Dictionary)
		{
			this.surround = surround;
			this.result = result;
		}
	}
}