package modules.capture
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Игровое поле для хранения промежуточных результатов при эвристическом просчете хода машины
	 * 
	 */
	
	public class AIFakeField implements IField
	{
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _col:int;										// Количество столбцов в матрице
		private var _row:int;										// Количество строк в матрице
		
		private var _matrix:Vector.<Vector.<uint>>;					// Матрица игрового поля
		
		private var _debug:IDebug;									// Отладочные функции
		
		private var _flags:Dictionary = new Dictionary(false);		// Набор флагов окружений, которым принадлежат точки
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param fieldToClone игровое поле, из которого следует продублировать данные
		 */
		public function AIFakeField(fieldToClone:IField=null)
		{
			if (fieldToClone)
				clone(fieldToClone);
		}
		
		/**
		 * Продублировать данные из указанного поля
		 * @param field поле, из которого дублируются данные
		 */
		public function clone(field:IField):void
		{
			_col = field.col;
			_row = field.row;
			_debug = field.debug;
			
			_matrix = new Vector.<Vector.<uint>>();
			for (var c:int = 0; c < field.matrix.length; c++)
			{
				var col:Vector.<uint> = new Vector.<uint>();
				_matrix[c] = col;
				
				var column:Vector.<uint> = field.matrix[c];
				
				// В процессе копирования данных матрицы отсекаем старшие 8 бит,
				// где хранятся флаги, указывающие на потенциальное участие в окружении,
				// окруженные точки блокируются
				for (var r:int = 0; r < column.length; r++)
				{
					var cell:uint = column[r];
					col[r] = (cell & 0xF00) == 0 ? cell & 0xFF0FFF : 0x10000;
				}
			}
		}
		
		////////////////////////////////////////////////////
		// IField
		////////////////////////////////////////////////////
		
		/**
		 * Ширина поля в столбцах
		 */
		public function get col():int
		{
			return _col;
		}
		
		/**
		 * Высота поля в строках
		 */
		public function get row():int
		{
			return _row;
		}
		
		/**
		 * Игровая матрица
		 */
		public function get matrix():Vector.<Vector.<uint>>
		{
			return _matrix;
		}
		
		/**
		 * Получить флаги окружений для точки
		 * @param col позиция точки по горизонтали
		 * @param row позиция точки по вертикали
		 * @return флаги окружения
		 */
		public function getSurrounFlags(col:int, row:int):uint
		{
			return _flags[AI.getPointName(col, row)] as uint;
		}
		
		/**
		 * Задать значение точки
		 * @param col позиция точки по горизонтали
		 * @param row позиция точки по вертикали
		 * @param type тип точки (играющая сторона, которой принадлежит точка)
		 * @param surroundId идентификатор окружения, к которому принадлежит точка
		 * @param flags значение, которое полностью переопределяет флаги окружения (surroundId игнорируется)
		 */
		public function setPointType(col:int, row:int, type:int, surroundId:uint=0, flags:uint=0):void
		{
			if (flags)
			{
				// Для этой точки задан набор флагов окружений
				
				var name:String = AI.getPointName(col, row);
				
				_flags[name] = flags;
			}
			else if (surroundId)
			{
				// Эта точка принадлежит окружению, запомнить, какому именно.
				
				name = AI.getPointName(col, row);
				
				var flag:uint = _flags[name] as uint;
				_flags[name] = flag | surroundId;
			}
			
			_matrix[col][row] = type;
		}
		
		/**
		 * Обновить окружения
		 */
		public function updateSurround():void
		{
		}
		
		/**
		 * Заблокировать игровое поле для ввода
		 */
		public function set lock(value:Boolean):void
		{
		}
		
		public function get debug():IDebug
		{
			return _debug;
		}
		
		////////////////////////////////////////////////////
		// IEventDispatcher
		////////////////////////////////////////////////////
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return false;
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return false;
		}
		
		public function willTrigger(type:String):Boolean
		{
			return false;
		}
	}
}