package modules.capture
{
	
	import flash.utils.Dictionary;
	
	/**
	 * 
	 * @author jvirkovskiy
	 * Модуль искусственного интеллекта для боя против другого человека
	 * 
	 */
	
	public class PVPAI extends AI
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _currentSide:int = 1;										// Текущая играющая сторона
		private var _currentEnemySide:int = 2;									// Текущая сторона противника
		
		private var _surrCtrs:Dictionary = new Dictionary();
		private var _fakeSurrCtrs:Dictionary = new Dictionary();
		
		// Координаты точек, образующих простое окружение в четыре точки (такое окружение не поддается расчету через A*, поэтому задано явно)
		private static var simpleSurrOffsets:Vector.<Pt> = new <Pt>[ new Pt(0, -1), new Pt(-1, 0), new Pt(0, 1), new Pt(1, 0) ];
		
		// Координаты точек, отстоящих от целевой на одну позицию
		protected static var nearOffsets:Vector.<Pt> = new <Pt>[ new Pt(-1, -1), new Pt(0, -1), new Pt(1, -1), new Pt(1, 0),
																 new Pt(1, 1), new Pt(0, 1), new Pt(-1, 1), new Pt(-1, 0) ];
		
		// Координаты точек, отстоящих от целевой на две позиции
		protected static var farOffsets:Vector.<Pt> = new <Pt>[ new Pt(-2, -2), new Pt(-1, -2), new Pt(0, -2), new Pt(1, -2), new Pt(2, -2),
																new Pt(-2, -1), new Pt(2, -1),
																new Pt(-2, 0), new Pt(2, 0),
																new Pt(-2, 1), new Pt(2, 1),
																new Pt(-2, 2), new Pt(-1, 2), new Pt(0, 2), new Pt(1, 2), new Pt(2, 2) ];
		
		// Координаты точек, составляющих триады. Массив построен таким образом, что первым элементом идет смещение по диагонали,
		// а два других значения - смещения по вертикали и горизонтали. Если существует подходящая точка в горизонтали, то две другие
		// могут быть усечены (или наоборот добоавлены) без изменения результатов окружения, но с изменением в большую или меньшую сторону
		// количества точек, участвующих в окружении
		protected static var triads:Vector.<Vector.<Pt>> = new <Vector.<Pt>>[ new <Pt>[ new Pt(1, 1), new Pt(0, 1), new Pt(1, 0) ],
																			  new <Pt>[ new Pt(-1, 1), new Pt(-1, 0), new Pt(0, 1) ],
																			  new <Pt>[ new Pt(-1, -1), new Pt(0, -1), new Pt(-1, 0) ],
																			  new <Pt>[ new Pt(1, -1), new Pt(1, 0), new Pt(0, -1) ] ];
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param field игровое поле
		 */
		public function PVPAI(field:IField)
		{
			super(field);
		}
		
		/* Логика игры закладывалась под то, что в игре могут принимать участие более двух
		   игроков, хотя в классическом варианте игроков лишь двое */
		
		/**
		 * Текущая играющая сторона
		 */
		protected function set currentSide(value:int):void
		{
			_currentEnemySide = value == 1 ? 2 : 1;
			
			_currentSide = value;
		}
		
		protected function get currentSide():int
		{
			return _currentSide;
		}
		
		/**
		 * Текущая сторона противника (она же следующая играющая сторона)
		 */
		protected function get currentEnemySide():int
		{
			return _currentEnemySide;
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Переопределенный обработчик выбора игроком точки
		 * @param col координата точки по горизонтали
		 * @param row координата точки по вертикали
		 */
		override protected function selectPoint(col:int, row:int):void
		{
			super.selectPoint(col, row);
			
			if (field.matrix[col][row] != 0)
			{
				// Эта точка уже выбрана, игнорируем запрос
				return;
			}
			
			field.setPointType(col, row, currentSide);
			
			// TODO: Сюда вставить отправку сообщения на сервер о выборе игроком точки
			
			process(col, row, currentSide, currentEnemySide);
		}
		
		////////////////////////////////////////////////////
		// AI
		////////////////////////////////////////////////////
		
		// Проанализировать ход игрока
		/**
		 * Анализ хода игрока
		 * @param col координата выбранной точки по горизонтали
		 * @param row координата выбранной точки по вертикали
		 * @param side текущая играющая сторона
		 * @param enemySide текущая сторона противника (следующая играющая сторона)
		 */
		private function process(col:int, row:int, side:int, enemySide:int):void
		{
			var pointResult:Vector.<SurrResult> = getPointResult(col, row, side);
			
			if (pointResult)
			{
				field.updateSurround();
				
				// TODO: Сообщить серверу о том, что завершено окружение, передать ход снова победившей стороне
				
				currentSide = side;
			}
			else
			{
				// TODO: Сообщить серверу о том, что ход передается стороне противника (следующей играющей стороне)
				
				currentSide = enemySide;
			}
		}
		
		/**
		 * Флаг, указывающий на то, что в настоящее время происходит симуляция
		 * игрового процесса для поиска решения AI
		 */
		protected function get isSimulation():Boolean
		{
			return false;
		}
		
		/**
		 * Получить результат присвоения указанной точки играющей стороне
		 * @param col позиция точки по горизонтали
		 * @param row позиция точки по вертикали
		 * @param side сторона, которой присваивается точка
		 * @return массив полученных в результате окружений, каждый элемент которого
		 * содержит массив точек, задействованных в окружении и словарь со списками
		 * окруженных вражеских точек, где индекс соответствует стороне, которой
		 * принадлежат окруженные точки
		 */
		protected function getPointResult(col:int, row:int, side:int):Vector.<SurrResult>
		{
			// Получить списки окружений, если списки не пусты,
			// проанализировать результат, если пусты, передать ход противнику
			var targets:Vector.<Pt> = getTargets(col, row, side);
			
			var surrounds:Vector.<Vector.<Pt>> = new Vector.<Vector.<Pt>>();
			
			for each (var pt:Pt in targets)
			{
				// Для всех целевых точек запускаем A*,
				// который в итоге вместе с третьей промежуточной точкой
				// должен дать полное окружение
				var surround:Vector.<Pt> = checkTarget(new Pt(col, row), pt, side);
				
				if (surround)
				{
					// Дополнить результат до полного кольца
					appendResult(surround, side);
					surrounds.push(surround);
				}
			}
			
			var checkResult:Vector.<SurrResult> = new Vector.<SurrResult>();
			
			if (surrounds.length > 0)
			{
				surrounds = surrounds.sort(sortArraysByLen);
			
				for each (surround in surrounds)
				{
					var result:Dictionary = checkSurrResult(surround, side, !isSimulation);
					if (result)
						checkResult.push(new SurrResult(surround, result));
				}
				
				if (checkResult.length > 0)
				{
					// Есть окружения
					
					// Сгенерировать новый флаг окружения, текущий уже отработан
					getSurroundFlag(side, true);
					
					if (isSimulation)
					{
						// Если это симуляция, то следует выбрать из одинаковых
						// окружений то, которое меньше весит, и оставить тольк его
						
						if (checkResult.length > 1)
						{
							var res1:SurrResult, res2:SurrResult;
							var resultsIsEqual:Boolean;
							var basePtr:int = 0;
							
							while (basePtr < checkResult.length)
							{
								res1 = checkResult[basePtr];
								
								do {
									resultsIsEqual = false;
									
									for (var i:int = 0; i < checkResult.length; i++)
									{
										if (i == basePtr)
											continue;
										
										res2 = checkResult[i];
										resultsIsEqual = compareResults(res1.result, res2.result);
										
										if (resultsIsEqual)
										{
											if (getSurroundWeight(res1.surround) > getSurroundWeight(res2.surround))
												checkResult.splice(basePtr, 1);
											else
												checkResult.splice(i, 1);
											
											break;
										}
									}
								} while (resultsIsEqual && basePtr < checkResult.length);
								
								basePtr++;
							}
						}
					}
				}
			}
			
			return checkResult.length > 0 ? checkResult : null;
		}
		
		/**
		 * Вспомогательная функция сравнения двух результатов окружения
		 * (результаты представляют собой списки окруженных точек, где
		 * сторона, к которой принадлежат точки, выступает в качестве индекса)
		 * @param res1 первый результат
		 * @param res2 второй результат
		 * @return true, если результаты эквивалентны
		 */
		private function compareResults(res1:Dictionary, res2:Dictionary):Boolean
		{
			var commonLen1:int = 0;
			var commonLen2:int = 0;
			
			for each (var prey1:Vector.<Pt> in res1)
				commonLen1 += prey1.length;
				
			for each (var prey2:Vector.<Pt> in res2)
				commonLen2 += prey2.length;
			
			if (commonLen1 != commonLen2)
				return false;
			
			for (var index:String in res1)
			{
				var i:int = int(index);
				
				prey1 = res1[i];
				prey2 = res2[i];
				
				if (!prey2 || !prey1 || prey1.length != prey2.length)
					return false;
				
				for each (var pt1:Pt in prey1)
				{
					var hasSamePt:Boolean = false;
					
					for each (var pt2:Pt in prey2)
					{
						if (pt1.x == pt2.x && pt1.y == pt2.y)
						{
							hasSamePt = true;
							break;
						}
					}
					
					if (!hasSamePt)
						return false;
				}
				
				commonLen1 -= prey1.length;
				commonLen2 -= prey2.length;
			}
			
			return commonLen1 == commonLen2;
		}
		
		/**
		 * Вспомогательная функция нахождения суммарного веса окружения
		 * (под весом подразумевается цена прохождения точки, расчитанная
		 * как результат функции getG(), используемой для A*)
		 * @param surr массив точек, представляющий окружение
		 * @return суммарный вес окружения
		 */
		private function getSurroundWeight(surr:Vector.<Pt>):int
		{
			var res:int = 0;
			for each (var pt:Pt in surr)
				res += getG(field.matrix[pt.x][pt.y]);
			return res;
		}
		
		/**
		 * Функция сортировки векторов по длине
		 * @param a первый вектор
		 * @param b второй верктор
		 * @return 1 если первый вектор больше второго, -1 если второй больше первогоб 0 если равны
		 */
		private function sortArraysByLen(a:Vector.<Pt>, b:Vector.<Pt>):int
		{
			if (a.length > b.length)
				return 1;
			if (a.length < b.length)
				return -1;
			return 0;
		}
		
		/**
		 * Вспомогательная функция проверки завершения окружения
		 * @param result точки, образующие полное кольцо окружения
		 * @param side играющая сторона
		 * @param checkAllInUse флаг, указывающий проверять, не являютс ли окруженные точки уже окруженными
		 * @return списки окруженных вражеских точек, где сторона противника выступает в качестве индекса
		 */
		private function checkSurrResult(result:Vector.<Pt>, side:int, checkAllInUse:Boolean):Dictionary
		{
			if (checkAllInUse)
			{
				// Проверить наличие в новом окружении точек, не участвующих
				// в предыдущих окружениях, чтобы не отрабатывать два раза
				// одно и то же окружение
				var allInUse:Boolean = true;
				for each (var pt:Pt in result)
				{
					var cell:uint = field.matrix[pt.x][pt.y];
					if (!(cell & 0xF0))
					{
						allInUse = false;
						break;
					}
				}
				
				if (allInUse)
					return null;
			}
			
			// Получить списки окруженных точек и подсчитать
			// количество вражеских окруженных точек
			var catchPoints:Dictionary = getCatchPoints(result, side);
			var blackList:Vector.<int> = new Vector.<int>();
			
			for (var index:String in catchPoints)
			{
				var i:int = int(index);
				var catchPointsSide:int = i & 0x0F;
				
				if (!catchPointsSide || catchPointsSide == side || catchPoints[i].length == 0)
					blackList.push(i);
			}
			
			for each (i in blackList)
				delete catchPoints[i];
			
			for (index in catchPoints)
				return catchPoints;
			
			return null;
		}
		
		/**
		 * Фуункция проверки точки на пригодность к окружению
		 * @param cell значение ячейки
		 * @return true если точка может быть распознана как значащая и окружена, false в противном случае
		 */
		protected function canBeCatched(cell:uint):Boolean
		{
			return cell && !(cell & 0xFF0);
		}
		
		/**
		 * Вспомогательная функция для нахождения точек, попавших в окружение
		 * @param result точки, образующие полное кольцо окружения
		 * @param side текущая играющая сторона
		 * @return словарь с наборами окруженных точек, в качестве индекса используется
		 * сторона, которой принадлежат точки
		 */
		private function getCatchPoints(result:Vector.<Pt>, side:int):Dictionary
		{
			var res:Dictionary = new Dictionary(false);
			
			// Найти границы окружения
			var minX:int = field.col;
			var minY:int = field.row;
			var maxX:int = 0;
			var maxY:int = 0;
			
			// Заодно создать хеш для заполнения матрицы
			var rawResult:Dictionary = new Dictionary();
			
			for each (var pt:Pt in result)
			{
				if (pt.x < minX) minX = pt.x;
				if (pt.y < minY) minY = pt.y;
				if (pt.x > maxX) maxX = pt.x;
				if (pt.y > maxY) maxY = pt.y;
				
				rawResult[AI.getPointName(pt.x, pt.y)] = new Pt(pt.x, pt.y);
			}

			// Создать матрицу
			var matrix:Vector.<Vector.<Pt>> = new Vector.<Vector.<Pt>>();
			var c:int = 0;
			var r:int = 0;
			
			for (var i:int = minX; i <= maxX; i++)
			{
				var col:Vector.<Pt> = new Vector.<Pt>();
				matrix[c++] = col;
				r = 0;
				
				for (var j:int = minY; j <= maxY; j++)
					col[r++] = rawResult[AI.getPointName(i, j)] as Pt;
			}
			
			var matrixWidth:int = maxX - minX + 1;
			var matrixHeight:int = maxY - minY + 1;
			
			// Найти затравочную точку
			var current:PFNode = null;
			
			for (i = 1; i < matrixWidth - 1; i++)
			{
				col = matrix[i];
				
				for (j = 0; j < matrixHeight - 1; j++)
				{
					if (matrix[i][j] && matrix[i - 1][j + 1] && !matrix[i][j + 1])
					{
						current = new PFNode(i, j + 1);
						break;
					}
				}
				
				if (current)
				{
					var insideSurround:Boolean = false;
					for (j = current.y; j < matrixHeight; j++)
					{
						if (matrix[i][j])
						{
							insideSurround = true;
							break;
						}
					}
					
					if (insideSurround)
						break;
					else
						current = null;
				}
			}
			
			if (!current)
			{
				// Не найдена затравочная точка, вероятно это окружение
				// представляет собой плоскую петлю
				return res;
			}
			
			// От затравочной точки делаем поиск в ширину,
			// пока в закрытом списке не окажутся все окруженные точки
			var openList:Dictionary = new Dictionary(false);
			var closeList:Dictionary = new Dictionary(false);
			
			openList[current.name] = current;

			while (!isEmpty(openList))
			{
				for each (current in openList) break;
				
				delete openList[current.name];
				closeList[current.name] = current;
				
				for (i = 0; i < simpleSurrOffsets.length; i++)
				{
					pt = simpleSurrOffsets[i];
					
					var x:int = current.x + pt.x;
					var y:int = current.y + pt.y;
					
					// Отсечь выходящие за пределы матрицы
					if (isOutOfMatrix(x, y))
						continue;
					
					if (!matrix[x][y])
					{
						var newOpenPoint:PFNode = new PFNode(x, y);
						if (!closeList[newOpenPoint.name])
							openList[newOpenPoint.name] = newOpenPoint;
					}
				}
			}
			
			var totalSurrPoints:int = 0;
			var hasCaptive:Boolean = false;
			
			for each (current in closeList)
			{
				totalSurrPoints++;
				
				x = current.x + minX;
				y = current.y + minY;
				
				var cell:uint = field.matrix[x][y];
				
				if (canBeCatched(cell))
				{
					var cellSide:int = cell & 0x0F;
					var holder:Vector.<Pt> = res[cellSide];
					if (!holder)
						res[cellSide] = holder = new Vector.<Pt>();
					
					holder.push(new Pt(x, y));
					
					if (!hasCaptive && !envCellIsValid(cell, side))
						hasCaptive = true;
				}
			}
			
			if (hasCaptive)
			{
				// Имеются окруженные вражеские точки
				var flag:uint = getSurroundFlag(side);
				
				for each (current in closeList)
				{
					x = current.x + minX;
					y = current.y + minY;
					
					cell = field.matrix[x][y];
					
					if (cell)
					{
						if (!(cell & 0xF00) && !envCellIsValid(cell, side))
							field.setPointType(x, y, cell | 0x100);
					}
					else
						field.setPointType(current.x + minX, current.y + minY, 0x100);
				}
				
				// Отметить проверяемые точки как участвующие в окружении
				for each (pt in result)
				{
					cell = field.matrix[pt.x][pt.y];
					field.setPointType(pt.x, pt.y, cell | 0x10, flag);
				}
				
				if (!isSimulation)
				{
					while (res[side])
					{
						// В окружение попали собственные точки.
						// Проверить, если они имеют две смежные точки из
						// текущего окружения, то добавить их к окружению
						
						holder = res[side] as Vector.<Pt>;
						
						var newHolder:Vector.<Pt> = new Vector.<Pt>();
						var hasPendant:Boolean = false;
						
						for each (var missPt:Pt in holder)
						{
							var neighbourCtr:int = 0;
							
							for each (pt in nearOffsets)
							{
								x = missPt.x + pt.x;
								y = missPt.y + pt.y;
								
								if (!rawResult[AI.getPointName(x, y)])
									continue;
								
								neighbourCtr++;
								
								if (neighbourCtr >= 2)
									break;
							}
							
							if (neighbourCtr >= 2)
							{
								result.push(new Pt(missPt.x, missPt.y));
								
								cell = field.matrix[missPt.x][missPt.y];
								field.setPointType(missPt.x, missPt.y, cell | 0x10, flag);
								
								rawResult[AI.getPointName(missPt.x, missPt.y)] = missPt;
								hasPendant = true;
							}
							else
								newHolder.push(missPt);
						}
						
						if (newHolder.length > 0)
						{
							// В окружении остались "висячие" точки
							res[side] = newHolder;
						}
						else
						{
							// Все точки были добавлены в окружение
							delete res[side];
						}
						
						if (!hasPendant)
							break;
					}
				}
				
				postProcessSurround(result, side);
			}
			
			return res;
		}
		
		/**
		 * Дополнительная обработка результата окружения
		 * @param result точки, образующие полное кольцо окружения
		 * @param side текущая играющая сторона
		 */
		protected function postProcessSurround(result:Vector.<Pt>, side:int):void
		{
			// Добавить в окружение все рядом стоящие точки, образующие триады
			processTriad(result, side, false, true);
		}
		
		/**
		 * Вспомогательная функция обработки триад - добавляет в окружение точки, составляющие
		 * триады с входящими в окружение, или же наоборот удаляет, максимально упрощая окружение
		 * @param result точки, составляющие окружение
		 * @param side текущая играющая сторона
		 * @param removeTriads флаг, указывающий на то, что триады должны быть удалены из окружения
		 * @param attachToOtherSurrounds флаг, предписывающий объединять окружение с
		 * другими окружениями, если их точки попадают в триады
		 */
		protected function processTriad(result:Vector.<Pt>, side:int, removeTriads:Boolean, attachToOtherSurrounds:Boolean):void
		{
			var startOffset:int = 0;
			var newResultPoints:Vector.<Pt> = new Vector.<Pt>();
			
			do {
				var resultIsChanged:Boolean = false;
				
				for (var p:int = startOffset; p < result.length; p++)
				{
					var pt:Pt = result[p];
					
					// Пройтись по всем диагоналям, если есть смежные точки,
					// обработать их соответственно флагу removeTriads
					
					for each (var triad:Vector.<Pt> in triads)
					{
						var neighbour:Pt = triad[0];
						
						var x:int = pt.x + neighbour.x;
						var y:int = pt.y + neighbour.y;
						
						// Отсечь выходящие за пределы матрицы
						if (isOutOfMatrix(x, y))
							continue;
						
						var cell:uint = field.matrix[x][y];
						
						// Отсечь точки, не участвующие в окружении
						if ((cell & 0x0F0) == 0)
							continue;
						
						// Дополнительное условие, которое можно переопределять в модуле PVE
						if (!envCellIsValid(cell, side))
							continue;
						
						// Отсечь свои точки, не принадлежащие текущему окружению
						if (!isValueInVector(x, y, result))
							continue;
						
						// Пройтись по вертикалям и горизонталям
						
						var newStartOffset:int = result.length;
						for (var i:int = 1; i < triad.length; i++)
						{
							neighbour = triad[i];
							
							x = pt.x + neighbour.x;
							y = pt.y + neighbour.y;
							
							// Отсечь выходящие за пределы матрицы
							if (isOutOfMatrix(x, y))
								continue;
							
							cell = field.matrix[x][y];
							
							if (envCellIsValid(cell, side))
							{
								var flag:uint = getSurroundFlag(side);
								var neighbourFlags:uint = field.getSurrounFlags(x, y);
								var inSameSurround:Boolean = isValueInVector(x, y, result);
								
								if (inSameSurround && removeTriads)
								{
									// Точка принадлежит тому же окружению, что и исследуемая триада,
									// убрать ее из окружения
									
									for (var j:int = 0; j < result.length; j++)
									{
										var surrPt:Pt = result[j];
										
										if (surrPt.x == x && surrPt.y == y)
										{
											result.splice(j, 1);
											field.setPointType(x, y, field.matrix[x][y] & 0xFFFFFF0F, 0, neighbourFlags & ~flag);
											resultIsChanged = true;
											
											// startOffset - это точка, с которой начнется проверка в следующий раз,
											// точки до startOffset уже проверены и не затронуты в процессе модификации.
											// Вычисляем новую стартовую точку из расчета, что у нас может быть два
											// прохода - для вертикали и для горизонтали
											
											var so:int = p < j ? p : j;
											newStartOffset = newStartOffset < so ? newStartOffset : so;
											break;
										}
									}
								}
								else if (!inSameSurround && !removeTriads)
								{
									// Точка не принадлежит окружению, которому принадлежит триада
									// добавить ее в окружение
									
									if (!attachToOtherSurrounds && neighbourFlags > 0)
									{
										// Не добавлять в триады точки, которые уже принадлежат другим окружениям
										continue;
									}
									
									newResultPoints.push(new Pt(x, y));
									field.setPointType(x, y, field.matrix[x][y] | 0x10, 0, neighbourFlags | flag);
								}
							}
						}
						
						if (resultIsChanged)
						{
							startOffset = newStartOffset;
							break;
						}
					}
					
					// Поскольку результат изменился, следует начать расчет сначала
					if (resultIsChanged)
						break;
				}
			} while (resultIsChanged);
			
			// Добавить в окружение обнаруженные триады
			for each (pt in newResultPoints)
				result.push(pt);
		}
		
		/**
		 * Вспомогательная функция, определяет наличие в векторе указанной точки
		 * @param x координата по горизонтали исследуемой точки
		 * @param y координата по вертикали исследуемой точки
		 * @param vector вектор
		 * @return результат - true, если точка найдена
		 */
		private function isValueInVector(x:int, y:int, vector:Vector.<Pt>):Boolean
		{
			for each (var pt:Pt in vector)
				if (pt.x == x && pt.y == y)
					return true;
			return false;
		}
		
		/**
		 * Получить новый идентификатор окружения. Идентификаторы окружения представляют собой
		 * бинарные флаги и служат для предотвращения смешивания колец разных окружений. Всего
		 * для каждой играющей стороны может быть не более 32 уникальных индентификаторов, размер
		 * игрового поля должен быть расчитан таким образом, чтобы теоретическое количество окружений
		 * одной из сторон не превышало этого предела
		 * @param side играющая сторона
		 * @param increment флаг, указывающий на необходимость генерации нового идентификатора
		 * @return текущий идентификатор окружения для указанной стороны, или новый идентификатор,
		 * если increment установлен в true
		 */
		private function getSurroundFlag(side:int, increment:Boolean = false):uint
		{
			var sc:Dictionary = isSimulation ? _fakeSurrCtrs : _surrCtrs;
			var res:uint = sc[side] as uint;
			if (res == 0)
			{
				res = 0x00000001;
				sc[side] = res;
				return res;
			}
			
			if (!increment)
				return res;
			
			var newRes:uint = res;
			
			if (int(newRes) < 0)
				newRes = 0x00000001;
			else
				newRes <<= 1;
			
			sc[side] = newRes;
			return res;
		}
		
		/**
		 * Вспомогательная функция, дополняющая окружение до полного кольца. Алгортм
		 * A* не может правильно посчитать путь от одной до другой смежной точки (в этом случае
		 * возвращается прямая между этими точками), поэтому находятся три смежных точки, из
		 * которых выбрасывается центральная, а затем ищется окружной путь. Эта функция
		 * возвращает центральную точку (точки) в список точек, образующих кольцо окружения
		 * @param result точки, образующие кольцо окружения
		 * @param side играющая сторона
		 */
		private function appendResult(result:Vector.<Pt>, side:int):void
		{
			// Получить граничные точки окружения (вершины)
			var pt1:Pt = result[0];
			var pt2:Pt = result[result.length - 1];
			
			if (abs(pt1.x - pt2.x) <= 1 && abs(pt1.y - pt2.y) <= 1)
			{
				// Это смежные точки, достраивать окружение не нужно
				return;
			}
			
			// Между этими точками должна быть одна или несколько
			// соединительных точек, которые урезаются перед отправкой
			// на A* для получения окружения, отличного от линии
			// из трех точек
			var rawCommonPoints:Dictionary = new Dictionary();
			var commonPoints:Vector.<Pt> = new Vector.<Pt>();
			
			// Найти все точки, граничашие с первой вершиной
			for each (var pt:Pt in nearOffsets)
			{
				var x:int = pt1.x + pt.x;
				var y:int = pt1.y + pt.y;
				
				// Отсечь выходящие за пределы поля
				if (isOutOfMatrix(x, y))
					continue;
				
				var cell:uint = field.matrix[x][y];
				
				// Дополнительное условие, которое можно переопределять в модуле PVE
				if (!envCellIsValid(cell, side))
					continue;
				
				// Отсечь окруженные
				if (cell & 0xF00)
					continue;
				
				// Занести в хеш под именем, образованным из адреса точки
				rawCommonPoints[AI.getPointName(x, y)] = new Pt(x, y);
			}
			
			// Пройтись по всем граничным точкам для второй вершины
			for each (pt in nearOffsets)
			{
				x = pt2.x + pt.x;
				y = pt2.y + pt.y;
				
				var commonPt:Pt = rawCommonPoints[AI.getPointName(x, y)] as Pt;
				if (!commonPt)
					continue;
				
				// Если в хеше обнаружится точка с именем,
				// соответствующим одной из соседних комбинаций,
				// добавить ее в список общих точек
				commonPoints.push(commonPt);
			}
			
			// Взять первую из найденных точек и добавить в
			// конец результирующго массива, чтобы окружение замкнулось
			for each (pt in commonPoints)
			{
				result.push(pt);
				break;
			}
		}
		
		/**
		 * Статическая функция вычисления абсолютного целого значения
		 * @param value исходное значение
		 * @return абсолютное целое значение
		 */
		private static function abs(value:int):int
		{
			return value < 0 ? value * -1 : value;
		}
		
		/**
		 * Вспомогательная функция, возвращает набор точек, до которых теоретически
		 * возможно построить окружение, начиная с указанной позиции
		 * @param col позиция по горизонтали
		 * @param row позиция по вертикали
		 * @param side играющая сторона
		 * @return список точек, до которых можно построить окружение
		 */
		private function getTargets(col:int, row:int, side:int):Vector.<Pt>
		{
			// Список целевых точек
			var targets:Vector.<Pt> = new Vector.<Pt>();
			
			var neighbours:Vector.<Pt> = new Vector.<Pt>();
			var rawTargets:Dictionary = new Dictionary();
			
			// Создать список всех точек, отстоящих от стартовой на два шага
			for each (var pt:Pt in farOffsets)
			{
				var x:int = col + pt.x;
				var y:int = row + pt.y;
				
				// Отсечь выходящие за пределы поля
				if (isOutOfMatrix(x, y))
					continue;
				
				var cell:uint = field.matrix[x][y];
				
				// Дополнительное условие, которое можно переопределять в модуле PVE
				if (!envCellIsValid(cell, side))
					continue;
				
				// Отсечь окруженные
				if (cell & 0xF00)
					continue;
				
				neighbours.push(new Pt(x, y));
			}
			
			// Выделить из них те, которые имеют связь со стартовой точкой
			// через точку, отстоящую от стартовой на один шаг
			for each (pt in nearOffsets)
			{
				x = col + pt.x;
				y = row + pt.y;
				
				// Отсечь выходящие за пределы поля
				if (isOutOfMatrix(x, y))
					continue;
				
				cell = field.matrix[x][y];
				
				// Дополнительное условие, которое можно переопределять в модуле PVE
				if (!envCellIsValid(cell, side))
					continue;
				
				// Отсечь окруженные
				if (cell & 0xF00)
					continue;
				
				for each (var nb:Pt in neighbours)
				{
					var dx:int = nb.x - x;
					var dy:int = nb.y - y;
					
					if (abs(dx) > 1 || abs(dy) > 1)
						continue;
					
					rawTargets[AI.getPointName(nb.x, nb.y)] = nb;
				}
			}
			
			for each (nb in rawTargets)
				targets.push(nb);
			
			if (targets.length == 0)
				return null;
			
			// В результате получаем список целевых точек, которые
			// отстоят от стартовой на два шага и при этом могут быть
			// соединены с ней через третью промежуточную точку.
			return targets;
		}
		
		/**
		 * Эвристический расчет длины пути до конечной точки
		 * @param ax позиция начальной точки по горизонтали
		 * @param ay позиция начальной точки по вертикали
		 * @param bx позиция конечной точки по горизонтали
		 * @param by позиция конечной точки по вертикали
		 * @return длина пути
		 */
		protected function getH(ax:int, ay:int, bx:int, by:int):int
		{
			return abs(ax - bx) + abs(ay - by);
		}
		
		/**
		 * Расчет стоимости прохождения для точки
		 * @param cell точка
		 * @return проходимость
		 */
		protected function getG(cell:int):int
		{
			return (cell & 0xF0) > 0 ? 4 : 1;
		}
		
		/**
		 * Вспомогательная функция, отрабатывает алгоритм A* от исходной до
		 * конечной точки для указанной играющей стороны
		 * @param dest исходная точка
		 * @param targ конечная точка
		 * @param side текущая играющая сторона
		 * @return список точек, образующих кольцо окружения, или null, если связи
		 * между исходной и конечной точкой нет
		 */
		private function checkTarget(dest:Pt, targ:Pt, side:int):Vector.<Pt>
		{
			// Функция получения соседних точек для A*
			var getNodeEnv:Function = function(parent:PFNode):Vector.<PFNode> {
				var res:Vector.<PFNode> = new Vector.<PFNode>();
				
				// Получить все близлежащие от указанной точки
				for each (var pt:Pt in nearOffsets)
				{
					var x:int = parent.x + pt.x;
					var y:int = parent.y + pt.y;
					
					// Отсечь выходящие за пределы поля
					if (isOutOfMatrix(x, y))
						continue;
					
					var cell:uint = field.matrix[x][y];
					
					// Отсечь окруженные
					if (cell & 0xF00)
						continue;
					
					// Дополнительное условие, которое можно переопределять в модуле PVE
					if (!envCellIsValid(cell, side))
						continue;
					
					// Отсечь точки-соединители между стартовой
					// и целевой точками, чтобы не получить в результате
					// работы A* линию из трех точек вместо окружения
					var dx1:int = abs(dest.x - x);
					var dy1:int = abs(dest.y - y);
					var dx2:int = abs(targ.x - x);
					var dy2:int = abs(targ.y - y);
					
					if (dx1 < 2 && dy1 < 2 && dx2 < 2 && dy2 < 2)
						continue;
					
					// Добавить служебную информацию
					var node:PFNode = new PFNode(x, y);
					node.parent = parent;
					node.H = getH(x, y, targ.x, targ.y);
					node.G = getG(cell);
					node.F = node.H + node.G;
					
					res.push(node);
				}
				
				return res;
			}
			
			// Проверить на наличие простого окружения
			var path:Vector.<Pt> = checkSimpleSurr(dest, targ, side);
			
			if (!path)
				// Отработать A*, вернуть результат
				path = PFFind(new PFNode(dest.x, dest.y),
					new PFNode(targ.x, targ.y), getNodeEnv);
			
			return path.length > 0 ? path : null;
		}
		
		/**
		 * Проверка значения на выход за пределы матрицы
		 * @param x координата по горизонтали
		 * @param y координата по вертикали
		 * @return true, если указанные координаты лежат вне матрицы
		 */
		protected function isOutOfMatrix(x:int, y:int):Boolean
		{
			return x < 0 || x >= field.col || y < 0 || y >= field.row;
		}
		
		/**
		 * Дополнительная проверка на возможность добавления точки в соседние
		 * @param cell проверяемая точка
		 * @param side текущая играющая сторона
		 * @return флаг, означающий возможность добавления в соседи
		 */
		protected function envCellIsValid(cell:int, side:int):Boolean
		{
			// Точка должна принадлежать своей стороне
			return (cell & 0x0F) == side;
		}
		
		/**
		 * Вспомогательная функция проверки на наличие простого окружения.
		 * Под простым понимается окружение, состоящее из четырех точек, такое
		 * окружение не может быть просчитано с помощью A*, поэтому проверяется
		 * отдельно
		 * @param dest исходная точка
		 * @param targ конечная точка
		 * @param side играющая сторона
		 * @return точки, участвующие в простом окружении, или null, если
		 * простое окружение отсутствует
		 */
		private function checkSimpleSurr(dest:Pt, targ:Pt, side:int):Vector.<Pt>
		{
			var dx:int = targ.x - dest.x;
			var dy:int = targ.y - dest.y;
			
			var surrPt:Pt;
			
			// Найти единственную предположительно окруженную точку
			if (dy == 0)
				surrPt = new Pt(targ.x - dx / 2, targ.y);
			else if (dx == 0)
				surrPt = new Pt(targ.x, targ.y - dy / 2);
			else
				return null;
			
			var res:Vector.<Pt> = new Vector.<Pt>();
			
			// Проверить наличие минимального окружения
			for each (var pt:Pt in simpleSurrOffsets)
			{
				var x:int = surrPt.x + pt.x;
				var y:int = surrPt.y + pt.y;
				
				if (x < 0 || x >= field.col ||
					y < 0 || y >= field.row)
					return null;
				
				var cell:uint = field.matrix[x][y];
				
				if ((cell & 0xF00) || !envCellIsValid(cell, side))
					return null;
				
				res.push(new Pt(x, y));
			}
			
			return res;
		}
		
		////////////////////////////////////////////////////
		// A*
		////////////////////////////////////////////////////
		
		private var openList:Dictionary;	// Открытый список
		private var closeList:Dictionary;	// Закрытый список
		private var current:PFNode;			// Текущая вершина
		
		/**
		 * Проверка словаря на наличие в нем элементов
		 * @param dict проверяемый словарь
		 * @return true, если словарь пуст, false в противном случае
		 */
		private static function isEmpty(dict:Dictionary):Boolean
		{
			for each (var item:PFNode in dict) break;
			return item == null;
		}
		
		/**
		 * Получение минимального элемента из словаря
		 * @param dict словарь
		 * @return минимальный элемент
		 */
		private static function getMin(dict:Dictionary):PFNode
		{
			for each (var res:PFNode in dict) break;
			
			for each (var node:PFNode in dict)
				if (node.F < res.F)
					res = node;
			
			return res;
		}
		
		/**
		 * Найти путь
		 * @param a исходная точка
		 * @param b конечная точка
		 * @param envFn функция для определения соседних точек
		 * @return список точек, образующих путь, или пустой список,
		 * если путь не найден
		 */
		private function PFFind(a:PFNode, b:PFNode, envFn:Function):Vector.<Pt>
		{
			openList = new Dictionary(false);
			closeList = new Dictionary(false);
			
			// Занести первую вершину в открытый список и сделать текущей
			openList[a.name] = a;
			current = a;
			
			var res:Vector.<Pt> = new Vector.<Pt>();
			
			// Искать путь пока открытый список не пуст
			while (!isEmpty(openList))
			{
				var min:PFNode = getMin(openList);
				
				delete openList[current.name];
				closeList[current.name] = current;
				current = min;
				
				var env:Vector.<PFNode> = envFn(current);
				for each (var node:PFNode in env)
				{
					if (closeList[node.name])
						continue;
					
					var oldNode:PFNode = openList[node.name];
					if (oldNode)
					{
						if (node.G < oldNode.G)
							oldNode.parent = current;
						continue;
					}
					
					openList[node.name] = node;
				}
				
				var lastNode:PFNode = openList[b.name];
				if (lastNode)
				{
					// В открытом списке есть целевая вершина,
					// сформировать путь и выйти из цикла
					while (lastNode)
					{
						res.push(new Pt(lastNode.x, lastNode.y));
						lastNode = lastNode.parent;
					}
					break;
				}
			}
			
			return res;
		}
	}
}


import modules.capture.Pt;
import modules.capture.AI;

/**
 * 
 * @author jvirkovskiy
 * Вспомогательный класс узла для алгоритма нахождения пути A*
 * 
 */

class PFNode extends Pt
{
	public var name:String;
	
	public var F:int = 0;
	public var G:int = 0;
	public var H:int = 0;
	
	public var parent:PFNode;
	
	/**
	 * Конструктор
	 * @param x позиция по горизонтали
	 * @param y позиция по вертикали
	 */
	public function PFNode(x:int, y:int)
	{
		super(x, y);
		
		this.name = AI.getPointName(x, y);
	}
}
