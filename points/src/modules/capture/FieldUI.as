package modules.capture
{
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	[Event(name="selectPoint", type="modules.capture.FieldEvent")]

	/**
	 * 
	 * @author jvirkovskiy
	 * Игровое поле
	 * 
	 */
	
	public class FieldUI extends Sprite implements IField, IDebug
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		// Набор флагов, представляющих связи точки
		private static const LT:uint = 0x01;
		private static const T:uint = 0x02;
		private static const RT:uint = 0x04;
		private static const R:uint = 0x08;
		private static const RB:uint = 0x10;
		private static const B:uint = 0x20;
		private static const LB:uint = 0x40;
		private static const L:uint = 0x80;
		
		// Смещения близлежащих точек
		private static var nearOffsets:Vector.<Pt> = new <Pt>[ new Pt(-1, -1), new Pt(0, -1), new Pt(1, -1), new Pt(1, 0),
															   new Pt(1, 1), new Pt(0, 1), new Pt(-1, 1), new Pt(-1, 0) ];
		
		// Список направлений для связей точки
		private static var vectors:Vector.<uint> = new <uint>[ LT, T, RT, R, RB, B, LB, L ];
		
		// Флаг, указывающий замыкать вертикальные и горизонтальные соединения между точками,
		// принадлежащими разным окружениям
		private static const closeVerticals:Boolean = true;
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _col:int;										// Количество столбцов в матрице
		private var _row:int;										// Количество строк в матрице
		
		private var _colStep:Number;								// Расстояние между столбцами
		private var _rowStep:Number;								// Расстояние между строками
		
		private var _matrix:Vector.<Vector.<uint>>;					// Матрица игрового поля
		
		private var _surroundContainer:Sprite;						// Визуальный слой, на котором отображаются связи окружения
		private var _message:TextField;
		
//		private var _enemyMode:Boolean = false;						// Флаг, указывающий, что в настоящий момент осуществляется ход противника
		
		private var _flags:Dictionary = new Dictionary(false);		// Набор флагов окружений, которым принадлежат точки
		
		private var _debugLayer:Sprite;								// Слой для отрисовки отладочной информации
		private var _debugSigns:Dictionary;							// Список отладочных маркеров
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param col ширина игрового поля в столбцах
		 * @param row высота игрового поля в строках
		 * @param colStep расстояние между столбцами
		 * @param rowStep расстояние между строками
		 */
		public function FieldUI(col:int, row:int, colStep:Number = 19, rowStep:Number = 19)
		{
			super();
			
			_col = col;
			_row = row;
			_colStep = colStep;
			_rowStep = rowStep;
			
			draw();
		}
		
		////////////////////////////////////////////////////
		// IField
		////////////////////////////////////////////////////
		
		/**
		 * Ширина игровго поля в столбцах
		 */
		public function get col():int
		{
			return _col;
		}
		
		/**
		 * Высота игрового поля в строках
		 */
		public function get row():int
		{
			return _row;
		}
		
		/**
		 * Матрица игрового поля
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
		 * @param type играющая сторона, которой принадлежит точка
		 * @param surroundId идентификатор окружения, к которому принадлежит точка
		 * @param flags значение, которое полностью переопределяет флаги окружения (surroundId игнорируется)
		 */
		public function setPointType(col:int, row:int, type:int, surroundId:uint=0, flags:uint=0):void
		{
			var name:String = AI.getPointName(col, row);
			var point:FieldPoint = FieldPoint(getChildByName(name));
			point.type = type;
			
			if (flags)
			{
				// Для этой точки задан набор флагов окружений
				
				_flags[name] = flags;
			}
			else if (surroundId)
			{
				// Эта точка принадлежит окружению, запомнить, какому именно.
				// Значение в словаре _flags, имеющее в качестве ключа имя точки,
				// содержит набор битовых флагов, каждый из которых означает принадлежность
				// к какому-либо окружению. Одна точка может участвовать в нескольких окружениях.
				
				var flag:uint = _flags[name] as uint;
				_flags[name] = flag | surroundId;
			}
			
			_matrix[col][row] = type;
		}
		
		/**
		 * Перерисовать окружения
		 */
		public function updateSurround():void
		{
			// Очистить слой для отрисовки связей
			for (var i:int = _surroundContainer.numChildren - 1; i >= 0; i--)
				_surroundContainer.removeChildAt(i);
			
			_surroundContainer.graphics.clear();
			
			// Пройтись по всем точкам всех играющих сторон и нарисовать окружения
			// для каждой из них
			
			// TODO: В настоящий момент подразумевается, что стороны всего две, и они
			// имеют индексы 1 и 2 соответственно, если сторон будет больше, или они будут иметь
			// иную нумерацию, следует изменить формат ниже приведенного цикла
			
			for (var side:int = 1; side <= 2; side++)
			{
				// Проход по всем строкам и столбцам
				
				for (i = 0; i < _col; i++)
				{
					for (var j:int = 0; j < _row; j++)
					{
						var cell:int = matrix[i][j];
						
						// Точка в матрице представлена целым числом следующего формата:
						// младшие 4 бита содержат идентификатор стороны, которой принадлежит точка
						// биты с 5 по 8 содержат флаг, означающий, что точка участвует в окружении
						// биты с 9 по 12 содержат флаг, означающий, что точка окружена
						// биты с 13 по 16 содержат флаг, означающий, что точка в списке потенциально
						// участвующих в окружении
						// биты с 17 по 20 содержат флаг, означающий заблокированный бит, который не должен
						// участвовать в расчетах AI
						
						if ((cell & 0x0F) != side ||
							!(cell & 0xF0))
							continue;
							
						var isSurround1:Boolean = (cell & 0xF00) != 0;
						var flag1:uint = getSurrounFlags(i, j);
						
						// Набор флагов, означающих направления, в которых точка имеет соединения с другими точками
						var vector:uint = 0;
						
						// Пройтись по всем смежным точкам и выяснить, какие направления соединений есть у этой точки
						for (var k:int = 0; k < nearOffsets.length; k++)
						{
							var pt:Pt = nearOffsets[k];
							
							var x:int = i + pt.x;
							var y:int = j + pt.y;
							
							if (x < 0 || x >= _col ||
								y < 0 || y >= _row)
								continue;
							
							cell = matrix[x][y];
							
							var isSurround2:Boolean = (cell & 0xF00) != 0;
							var flag2:uint = getSurrounFlags(x, y);
							
							if (isSurround1 == isSurround2 &&
								(!flag1 && !flag2 || (flag1 & flag2) || (closeVerticals && (k % 2) != 0)) &&
								(cell & 0x0F) == side &&
								(cell & 0xF0) != 0)
								vector |= vectors[k];
						}
						
						drawSurround(i, j, vector);
					}
				}
			}
		}
		
		/**
		 * Вспомогательная функция отрисовки соединений
		 * @param col позиция по горизонтали точки, для которой отрисовываются соединения
		 * @param row позиция по вертикали точки, для которой отрисовываются соединения
		 * @param vector набор флагов, указывающих, в каких направлениях есть соединения у этой точки
		 */
		private function drawSurround(col:int, row:int, vector:uint):void
		{
			var x:Number = _colStep + _colStep * col;
			var y:Number = _rowStep + _rowStep * row;
			
			var dx:Number = _colStep / 2;
			var dy:Number = _rowStep / 2;
			
			_surroundContainer.graphics.lineStyle(1);
			_surroundContainer.graphics.moveTo(x, y);
			
			if (vector & LT)
			{
				_surroundContainer.graphics.lineTo(x - dx, y - dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & T)
			{
				_surroundContainer.graphics.lineTo(x, y - dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & RT)
			{
				_surroundContainer.graphics.lineTo(x + dx, y - dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & R)
			{
				_surroundContainer.graphics.lineTo(x + dx, y);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & RB)
			{
				_surroundContainer.graphics.lineTo(x + dx, y + dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & B)
			{
				_surroundContainer.graphics.lineTo(x, y + dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & LB)
			{
				_surroundContainer.graphics.lineTo(x - dx, y + dy);
				_surroundContainer.graphics.moveTo(x, y);
			}
			if (vector & L)
			{
				_surroundContainer.graphics.lineTo(x - dx, y);
				_surroundContainer.graphics.moveTo(x, y);
			}
			
			_surroundContainer.graphics.lineStyle();
		}
		
		/**
		 * Блокировка игрового поля для ввода
		 */
		public function set lock(value:Boolean):void
		{
			mouseChildren = mouseEnabled = !value;
		}
		
		/**
		 * Отладочные функции
		 */
		public function get debug():IDebug
		{
			return this;
		}
		
		////////////////////////////////////////////////////
		// IDebug
		////////////////////////////////////////////////////
		
		/**
		 * Пометить указанную точку указанным цветом
		 * @param pt точка
		 * @param color цвет
		 */
		public function markPoint(pt:Pt, color:uint):void
		{
			markPointAt(pt.x, pt.y, color);
		}
		
		/**
		 * Пометить точку в указанной позиции указанным цветом
		 * @param x позиция точки по горизонтали
		 * @param y позиция точки по вертикали
		 * @param color цвет
		 */
		public function markPointAt(x:int, y:int, color:uint):void
		{
			var graphics:Graphics = debugLayer.graphics;
			
			graphics.beginFill(color);
			graphics.drawCircle(_colStep + _colStep * x, _rowStep + _rowStep * y, 9.0);
			graphics.endFill();
		}
		
		/**
		 * Пометить точку текстом
		 * @param pt помечаемая точка
		 * @param text текст метки
		 */
		public function signPoint(pt:Pt, text:String):void
		{
			signPointAt(pt.x, pt.y, text);
		}
		
		/**
		 * Пометить точку текстом в указанной позиции
		 * @param x позиция точки по x
		 * @param y позиция точки по y
		 * @param text текст метки
		 */
		public function signPointAt(x:int, y:int, text:String):void
		{
			if (!_debugSigns)
				_debugSigns = new Dictionary();
			
			var field:TextField = _debugSigns[AI.getPointName(x, y)];
			if (!field)
			{
				_debugSigns[AI.getPointName(x, y)] = field = new TextField();
				field.defaultTextFormat = new TextFormat("Arial", 9, 0x000000, true);
				field.mouseEnabled = false;
				field.x = x * _colStep + _colStep;
				field.y = y * _rowStep + _rowStep + 2;
				debugLayer.addChild(field);
				
				field.text = text;
			}
			else
			{
				field.appendText(";" + text);
			}
		}
		
		/**
		 * Стереть все отладочные маркеры
		 */
		public function clearMarkers():void
		{
			_debugSigns = null;
			
			debugLayer.graphics.clear();
			
			for (var i:int = debugLayer.numChildren - 1; i >= 0; i--)
				debugLayer.removeChildAt(i);
		}
		
		/**
		 * Возвращает отладочный слой. Если слой не создан, создает и размещает в поле
		 */
		private function get debugLayer():Sprite
		{
			if (!_debugLayer)
			{
				_debugLayer = new Sprite();
				_debugLayer.mouseEnabled = false;
				addChildAt(_debugLayer, 0);
			}
			return _debugLayer;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Функция отрисовки игрового поля
		 */
		private function draw():void
		{
			graphics.clear();
			graphics.beginFill(0xFFFFFF);
			graphics.drawRect(0, 0, _colStep + _col * _colStep, _rowStep + _row * _rowStep);
			graphics.endFill();
			
			while (numChildren)
				removeChildAt(0);
			
			_message = new TextField();
			_message.width = 100;
			_message.height = 21;
			_message.y = _rowStep + _row * _rowStep - 21;
			
			_message.selectable = false;
			_message.mouseEnabled = false;
			
			addChild(_message);
			
			_surroundContainer = new Sprite();
			addChild(_surroundContainer);
			
//			var enemyModeBn:Sprite = new Sprite();
//			enemyModeBn.graphics.beginFill(0x00FF00);
//			enemyModeBn.graphics.drawRect(0, 0, 15, 15);
//			enemyModeBn.graphics.endFill();
//			
//			enemyModeBn.addEventListener(MouseEvent.CLICK, enemyMode_clickHandler);
//			
//			addChild(enemyModeBn);
			
			_matrix = new Vector.<Vector.<uint>>();
			
			// Расставить на поле интерактивные области для отслеживания кликов по точкам
			for (var r:int = 0; r < row; r++)
			{
				var colDict:Vector.<uint> = new Vector.<uint>();
				_matrix[r] = colDict;
				
				for (var c:int = 0; c < col; c++)
				{
					var point:FieldPoint = new FieldPoint(c, r);
					point.name = AI.getPointName(c, r);
					point.addEventListener(MouseEvent.CLICK, point_clickHandler);
					point.addEventListener(MouseEvent.ROLL_OVER, point_overHandler);
					point.addEventListener(MouseEvent.ROLL_OUT, point_outHandler);
					point.x = _colStep + c * _colStep;
					point.y = _rowStep + r * _rowStep;
					
					addChild(point);
					
					colDict[c] = 0;
				}
			}
		}
		
		/**
		 * Клик по точке в игровом поле
		 * @param event событие
		 */
		private function point_clickHandler(event:MouseEvent):void
		{
			var point:FieldPoint = event.target as FieldPoint;
			
			var pt:Pt = AI.getPointByName(point.name);
			
//			if (_enemyMode)
//				setPointType(pt.x, pt.y, 2);
//			else
				dispatchEvent(new FieldEvent(FieldEvent.SELECT, pt.x, pt.y));
		}
		
		/**
		 * Наведение на точку в игровом поле
		 * @param event событие
		 */
		private function point_overHandler(event:MouseEvent):void
		{
			var point:FieldPoint = event.target as FieldPoint;
			
			_message.text = point.pointName;
		}
		
		/**
		 * Уход мыши с точки в игровом поле
		 * @param event событие
		 */
		private function point_outHandler(event:MouseEvent):void
		{
			var point:FieldPoint = event.target as FieldPoint;
			
			if (_message.text == point.pointName)
				_message.text = "";
		}
		
//		private function enemyMode_clickHandler(event:MouseEvent):void
//		{
//			var enemyModeBn:Sprite = event.target as Sprite;
//			
//			_enemyMode = !_enemyMode;
//			
//			enemyModeBn.graphics.beginFill(_enemyMode ? 0xFF0000 : 0x00FF00);
//			enemyModeBn.graphics.drawRect(0, 0, 15, 15);
//			enemyModeBn.graphics.endFill();
//		}
	}
}


import flash.display.Sprite;

/**
 * 
 * @author jvirkovskiy
 * Класс интерактивной области для отслеживания клика по точке
 * на игровом поле
 * 
 */

class FieldPoint extends Sprite
{
	
	////////////////////////////////////////////////////
	// 
	////////////////////////////////////////////////////
	
	private var _type:int = 0;
	private var _pointName:String = "";
	
	////////////////////////////////////////////////////
	// 
	////////////////////////////////////////////////////
	
	/**
	 * Конструктор
	 * @param x координата точки по горизонтали
	 * @param y координата точки по вертикали
	 */
	public function FieldPoint(x:Number = NaN, y:Number = NaN)
	{
		super();
		
		useHandCursor = true;
		buttonMode = true;
		
		draw();
		
		if (!isNaN(x) && !isNaN(y))
			_pointName = x + ":" + y;
	}
	
	/**
	 * Тип точки (соответствует идентификатору играющей стороны, которой принадлежит точка, или 0, если точка не занята)
	 */
	public function set type(value:int):void
	{
		if (value == _type)
			return;
		
		if ((value & 0x0F) > 2)
			throw (Error("Point type can be 0, 1 or 2 only"));
		
		_type = value;
		draw();
		
		useHandCursor = buttonMode = _type == 0;
	}
	
	/**
	 * Имя точки (используется в качестве отладочной информации)
	 */
	public function get pointName():String
	{
		return _pointName;
	}
	
	////////////////////////////////////////////////////
	// 
	////////////////////////////////////////////////////
	
	/**
	 * Отрисовка точки 
	 */
	private function draw():void
	{
		var color:int = 0xA0A0A0;
		var radius:Number = 3;
		
		switch (_type & 0x0F)
		{
			case 1:
			{
				color = (_type & 0xF00) > 0 ? 0x007F00 : 0x00FF00;
				radius = 4.5;
				break;
			}
			case 2:
			{
				color = (_type & 0xF00) > 0 ? 0x7F0000 : 0xFF0000;
				radius = 4.5;
				break;
			}
			default:
			{
				if (_type & 0xF00)
				{
					graphics.clear();
					graphics.lineStyle(1);
					graphics.drawCircle(0, 0, radius);
					graphics.lineStyle();
					return;
				}
			}
		}
		
		graphics.clear();
		graphics.beginFill(color);
		graphics.drawCircle(0, 0, radius);
		graphics.endFill();
	}
}
