package modules.capture
{
	import flash.utils.Dictionary;

	/**
	 * 
	 * @author jvirkovskiy
	 * Модуль искусственного интеллекта для боя против машины
	 * 
	 */
	
	public class PVEAI extends PVPAI
	{
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private static var PC_SIDE:int = 2;				// Команда, за которую играет машина
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		private var _stepInProcess:Boolean = false;		// Флаг, указывающий, что ход машины в процессе обсчета
		private var _invertG:Boolean = false;			// Флаг, указывающий инвертировать стоимость прохода точки (используется для уточняющего расчета)
		
		private var _fakeField:AIFakeField;				// Временное игровое поле для хранения промежуточного результата расчетов
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Конструктор
		 * @param field игровое поле
		 */
		public function PVEAI(field:IField)
		{
			super(field);
		}
		
		////////////////////////////////////////////////////
		// 
		////////////////////////////////////////////////////
		
		/**
		 * Переопределенная текущая играющая сторона
		 */
		override protected function set currentSide(value:int):void
		{
			super.currentSide = value;
			
			if (value == PC_SIDE)
			{
				// Ход машины
				
				field.lock = true;
				
				var pt:Pt = doStep(1);
				selectPoint(pt.x, pt.y);
				
				field.lock = false;
			}
		}
		
		/**
		 * Просчет хода машины
		 * @param complexity уровень сложности - на сколько ходов вперед производится расчет
		 */
		private function doStep(complexity:int):Pt
		{
			// Сторона противника определяется из расчета, что играющих
			// сторон две, если сторон будет больше, следует анализировать отдельно
			// все стороны, противостоящие PC_SIDE
			var side1:int = PC_SIDE;
			var side2:int = PC_SIDE == 1 ? 2 : 1;
			var results:Vector.<Pt> = new Vector.<Pt>();
			
			// Шаблон игрового поля может модифицироваться, если уровень сложности
			// превышает 1, поэтому следует сделать дубликат для сохранения настоящего
			// игрового поля в исходном состоянии
			var templateField:IField = complexity > 1 ? new AIFakeField(super._field) : super._field;
			
			_stepInProcess = true;
			
			do {
				var result:Pt = null;
				var favorite1:DPt = null;
				var favorite2:DPt = null;
				
				var doRandomStep:Boolean = false;			// Флаг, указывающий на необходимость сделать случайный ход
				var isCriticalResult:int = 0;				// Сторона, для которой расчитанный шаг является критическим
				
				_fakeField = new AIFakeField(templateField);
				
				// Получить потенциально опасные точки, ход на которые
				// может привести к победе противника
				
				var dangerPoints:Dictionary = getDangerPoints(side1, side2, 10);
				
				for each (var dpt:DPt in dangerPoints)
				{
					if (favorite2)
					{
						if (favorite2.danger < dpt.danger)
							favorite2 = dpt;
					}
					else
					{
						favorite2 = dpt;
					}
				}
				
				if (!favorite2)
				{
					// Опасных точек нет, это означает, что машина еще не сделала ни одного хода,
					// сделать первый ход в любое ближайшее к вражеской точке поле
					
					doRandomStep = true;
				}
				else
				{
					if (favorite2.danger >= 1.0)
					{
						// Следующий же ход приведет к завершению окружения.
						// Предотвращаем это, блокирую первую точку из последовательности
						
						result = favorite2;
						isCriticalResult = side2;
					}
					else
					{
						// Восстановить поле и найти наиболее выгодные ходы для currentSide
						
						_fakeField = new AIFakeField(templateField);
						
						dangerPoints = getDangerPoints(side2, side1, 5);
						
						for each (dpt in dangerPoints)
						{
							if (favorite1)
							{
								if (favorite1.danger < dpt.danger)
									favorite1 = dpt;
							}
							else
							{
								favorite1 = dpt;
							}
						}
						
						if (!favorite1)
						{
							// Выгодных ходов для currentSide не найдено.
							// делаем ход в точку, выгодную для противника, или куда-нибудь еще
							
							result = favorite2;
						}
						else
						{
							if (favorite1.danger >= 1.0)
							{
								// Следующий же ход приведет к завершению окружения
								
								result = favorite1;
								isCriticalResult = side1;
							}
						}
					}
				}
				
				if (!result)
				{
					// Однозначного результата в процессе расчета не получено
					
					if (doRandomStep || !favorite1 || !favorite2)
					{
						// По тем или иным причинам требуется генерация случайного хода
						
						var nearPoints:Dictionary = getNearEmptyPoints(side2);
						var np:Vector.<Pt> = new Vector.<Pt>();
						for each (var pt:Pt in nearPoints)
							np.push(pt);
						
						// Рандомная точка из ближайшего окружения вражеских
						result = np.length > 0 ? np[int(Math.random() * np.length)] : null;
						
						if (!result)
							result = new Pt(int(Math.random() * field.col), int(Math.random() * field.row));
					}
					else
					{
						// если ход противника менее опасен, чем ход стороны, блокируем ход противника,
						// иначе делаем ход стороны
						
						result = favorite2.danger > favorite1.danger ? favorite2 : favorite1;
					}
				}
				
				if (side1 == PC_SIDE)
				{
					results.push(result);
					complexity--;
				}
				
				_fakeField = null;
				
				if (isCriticalResult)
				{
					// Обнаружен критически важный ход, который приведет к окружению
					
					if (side1 == PC_SIDE)
					{
						// Будут окружены вражеские точки, верное направление, выбрать первую расчетную позицию
						result = results[0];
					}
					else
					{
						// Будут окружены свои точки, сделать упреждающий ход в текущую найденную позицию
					}
					
					break;
				}
				
				if (templateField !== super._field)
				{
					// Это эвристический расчет, сымитировать ход стороны и расчитать возможный ход противника
					
					templateField.setPointType(result.x, result.y, side1);
				}
				
				// Меняем стороны местами чтобы выполнить эвристический расчет хода противоположной стороны
				
				var x:int = side1;
				side1 = side2;
				side2 = x;
				
				// На случай выхода восстанавливаем первое полученное значение
				result = results[0];
				
			} while (complexity);
			
			_stepInProcess = false;
			
			return result;
		}
		
		/**
		 * Получить список потенциально опасных точек
		 * @param side сторона, которой принадлежат потенциально опасные точки
		 * @param depth точность, с которой определяется опасность точки, соответствует
		 * количеству ходов, за которые будет завершено окружение с участием этой точки,
		 * точки, чье количество ходов выше, не попадают в список опасных
		 * @param paranoid параметр, указывающий количество ходов до завершения окружения,
		 * которое считается критическим
		 * @return список опасых точек
		 */
		private function getDangerPoints(side:int, enemySide:int, paranoid:int = 10):Dictionary
		{
			var pt:DPt, cell:uint, x:int, y:int;
			var nearPoints:Dictionary = getNearEmptyPoints(side);
			
			// Пометить все найденные точки как потенциально участвующие в окружении
			for each (pt in nearPoints)
				field.setPointType(pt.x, pt.y, field.matrix[pt.x][pt.y] | 0x01000);
			
			// Для каждой из потенциальных точек определяем, сколько
			// потребуется ходов, чтобы завершить какое-либо окружение
			
			var rawResult:Array = [];
			
			for each (pt in nearPoints)
			{
				var surrounds:Vector.<SurrResult> = getPointResult(pt.x, pt.y, enemySide);
				
				if (!surrounds)
				{
					// Если не найдено ни одного окружения, возможно возникла ситуация,
					// когда более выгодное окружение обсчитывается по существующим точкам,
					// а окружение по потенциальным точкам игнорируется из за высокой
					// стоимости точки. Изменяем правило формирования стоимости точки
					// (функция getG()) и повторяем расчет
					
					_invertG = true;
					surrounds = getPointResult(pt.x, pt.y, enemySide);
					_invertG = false;
				}
				
				for each (var sr:SurrResult in surrounds)
				{
					var emptyPointsNum:int = 0;
					var startPointIsIncluded:Boolean = false;
					var ptNeighbours:Array = [];
					
					for each (var surrPt:Pt in sr.surround)
					{
						cell = field.matrix[surrPt.x][surrPt.y];
						
						if (surrPt.x == pt.x && surrPt.y == pt.y)
						{
							// Это стартовая точка
							
							emptyPointsNum++;
							startPointIsIncluded = true;
						}
						else
						{
							// Это не стартовая точка
							
							if ((cell & 0x0F) == 0)
								emptyPointsNum++;
							
							// Подсчитать для стартовой точки количество смежных точек из
							// того же окружения. Если это количество меньше 2, то стартовая точка
							// является "висячей" и возможно потребуется добавить еще одну точку
							// до полноценного окружения
							
							if (ptNeighbours.length < 2)
							{
								for each (var nearPt:Pt in nearOffsets)
								{
									x = surrPt.x + nearPt.x;
									y = surrPt.y + nearPt.y;
									
									if (pt.x == x && pt.y == y)
									{
										ptNeighbours.push(surrPt);
										break;
									}
								}
							}
						}
						
						// Снять пометку о том, что точка участвует в окружении
						field.setPointType(surrPt.x, surrPt.y, cell & 0xFFFFFF0F);
					}
					
					if (ptNeighbours.length < 2)
					{
						// Стартовая точка является висячей
						
						if (ptNeighbours.length == 1)
						{
							// Проанализировать триады, в состав которых входит исследуемая точка
							// и единственная соседняя точка из окружения. Следует найти точку,
							// которая, при добавлении, даст корректное окружение с участием
							// исследуемой точки
							
							nearPt = ptNeighbours[0];
							x = nearPt.x - pt.x;
							y = nearPt.y - pt.y;
							
							var appendedPoints:Vector.<Pt>;
							
							for each (var triad:Vector.<Pt> in triads)
							{
								nearPt = triad[0];
								
								if (nearPt.x == x && nearPt.y == y)
								{
									appendedPoints = new <Pt>[ triad[1], triad[2] ];
									break;
								}
							}
							
							if (appendedPoints)
							{
								// Найдены точки, которые могут быть добавлены в окружение для
								// того, чтобы исследуемая точка перестала быть висячей
								
								var allAppendedIsEmpty:Boolean = true;
								
								for each (nearPt in appendedPoints)
								{
									x = pt.x + nearPt.x;
									y = pt.y + nearPt.y;
									
									if (isOutOfMatrix(x, y))
										continue;
									
									// Такая точка должна иметь три соседних точки, принадлежащие
									// дополняемому окружению, иначе она не годится для исправления
									// висячей точки
									
									var nearPointsFromSurr:int = 0;
									
									for each (var offset:Pt in nearOffsets)
									{
										var nx:int = x + offset.x;
										var ny:int = y + offset.y;
										
										for each (surrPt in sr.surround)
										{
											if (surrPt.x == nx && surrPt.y == ny)
											{
												nearPointsFromSurr++;
												break;
											}
										}
										
										if (nearPointsFromSurr > 2)
											break;
									}
									
									if (nearPointsFromSurr > 2)
									{
										cell = field.matrix[x][y];
										
										if ((cell & 0x0F) == enemySide)
										{
											allAppendedIsEmpty = false;
											break;
										}
									}
								}
								
								if (allAppendedIsEmpty)
								{
									// Эти точки пусты, значит потребуется еще одна точка для
									// построения корректного окружения
									emptyPointsNum++;
								}
							}
							else
							{
								trace ("Can't find triad to fix hanging point at [" + pt.x + ":" + pt.y + "].");
							}
						}
						else
						{
							trace ("Point is out of surround and hasn't neighbours.");
						}
					}
					
					if (!startPointIsIncluded)
					{
						// Стартовая точка была урезана в процессе удаления триад
						emptyPointsNum++;
					}
					
					var surrPointsNum:int = 0;
					for each (var catchedPts:Vector.<Pt> in sr.result)
					{
						surrPointsNum += catchedPts.length;
						
						// Снять с окруженных точек пометку об окружении для корректного
						// расчета результатов для других потенциальных точек
						for each (var catchedPt:Pt in catchedPts)
						{
							cell = field.matrix[catchedPt.x][catchedPt.y];
							field.setPointType(catchedPt.x, catchedPt.y, cell & 0xFFFFF0FF);
						}
					}
					
					if (emptyPointsNum)
					{
						if (surrPointsNum)
							rawResult.push({ point:pt, numSteps: emptyPointsNum, prey: surrPointsNum });
					}
					else
					{
						trace ("Unexpected closed surround detected!");
					}
				}
			}
			
			var res:Dictionary = new Dictionary();
			
			if (rawResult.length > 0)
			{
				rawResult.sort(dangerPointsSort);
				var resultIsEmpty:Boolean = true;
				
				for (var i:int = 0; i < rawResult.length; i++)
				{
					var raw:Object = rawResult[i];
					var numSteps:int = raw.numSteps;
					
					if (numSteps >= paranoid)
						break;
					
					pt = raw.point;
					var key:String = AI.getPointName(pt.x, pt.y);
					
					var value:DPt = res[key];
					if (!value)
					{
						res[key] = pt;
						pt.danger = numSteps == 1 ? 1.0 : Number(paranoid - numSteps) / paranoid;
					}
					
					resultIsEmpty = false;
				}
				
				if (resultIsEmpty)
				{
					// Не найдено точек, которые считались бы опасными,
					// поместить в результат самую опасную из найденных
					
					pt = rawResult[rawResult.length - 1].point;
					res[AI.getPointName(pt.x, pt.y)] = pt;
				}
			}
			
			// Снять пометку с потенциально участвующих в окружении точек
			for each (pt in nearPoints)
				field.setPointType(pt.x, pt.y, field.matrix[pt.x][pt.y] & 0xFFFF0F0F);
			
			return res;
		}
		
		/**
		 * Вспомогательная функция сортировки потенциальных точек хода
		 * @param a результат 1
		 * @param b результат 2
		 * @return 1 если первый результат предпочтительнее второго, -1 если
		 * второй результат предпочтительнее первого, 0 если результаты равны
		 */
		private function dangerPointsSort(a:Object, b:Object):int
		{
			if (a.numSteps > b.numSteps)
				return 1;
			else if (a.numSteps < b.numSteps)
				return -1;
			else if (a.prey > b.prey)
				return 1;
			else if (a.prey < b.prey)
				return -1;
			return 0;
		}
		
		/**
		 * Определить все близстоящие пустые точки, в которые может быть совершен ход
		 * @param side проверяемая играющая сторона
		 * @return список точек
		 */
		private function getNearEmptyPoints(side:int):Dictionary
		{
			var nearEmptyPoints:Dictionary = new Dictionary();
			
			for (var x:int = 0; x < field.matrix.length; x++)
			{
				var column:Vector.<uint> = field.matrix[x];
				for (var y:int = 0; y < column.length; y++)
				{
					var cell:uint = column[y];
					if ((cell & 0x0F) == side && (cell & 0xFF00) == 0)
					{
						// Для каждой неокруженной точки исследуемой стороны определить
						// окружающие ее незанятые точки
						for each (var pt:Pt in nearOffsets)
						{
							var nx:int = x + pt.x;
							var ny:int = y + pt.y;
							
							// Отсечь выходящие за пределы поля
							if (isOutOfMatrix(nx, ny))
								continue;
							
							// Отсечь занятые
							if ((field.matrix[nx][ny] & 0xF000F) != 0)
								continue;
							
							// Занести в хеш под именем, образованным из адреса точки
							nearEmptyPoints[AI.getPointName(nx, ny)] = new DPt(nx, ny);
						}
					}
				}
			}
			
			return nearEmptyPoints;
		}
		
		/**
		 * Фуункция проверки точки на пригодность к окружению
		 * @param cell значение ячейки
		 * @return true если точка может быть распознана как значащая и окружена, false в противном случае
		 */
		override protected function canBeCatched(cell:uint):Boolean
		{
			if (isSimulation)
				return cell && !(cell & 0xFF0F0);
			return super.canBeCatched(cell);
		}
		
		/**
		 * Флаг, указывающий на то, что в настоящее время происходит симуляция
		 * игрового процесса для поиска решения AI
		 */
		override protected function get isSimulation():Boolean
		{
			return _stepInProcess;
		}
		
		/**
		 * Переопределение дополнительной обработки результата окружения
		 * @param result точки, образующие полное кольцо окружения
		 * @param side текущая играющая сторона
		 */
		override protected function postProcessSurround(result:Vector.<Pt>, side:int):void
		{
			if (isSimulation)
			{
				// Удалить все триады для получения минимального количества точек,
				// входящих в каждое окружение для определения минимального количества ходов,
				// необходимых для завершения окружения
				processTriad(result, side, true, false);
			}
			else
			{
				super.postProcessSurround(result, side);
			}
		}
		
		/**
		 * Переопределенное игровое поле, используется для эвристического расчета ходов
		 */
		override protected function get field():IField
		{
			if (isSimulation)
				return _fakeField;
			
			return _field;
		}
		
		/**
		 * Переопределенная проверка возможности добавления точки в соседние, также позволяет
		 * добавлять в соседние незанятые точки для определения потенциальных окружений
		 * @param cell точка
		 * @param side текущая играющая сторона
		 * @return флаг, означающий возможность добавления в соседи
		 */
		override protected function envCellIsValid(cell:int, side:int):Boolean
		{
			if (isSimulation)
			{
				// Если AI в процессе расчета возможных путей,
				// то учитывать также точки, потенциально участвующие в окружении как свои
				return (cell & 0xF000F) == side || (cell & 0x0F000) > 0;
			}
			
			// Иначе учитывать только точки, принадлежащие своей стороне
			return (cell & 0x0F) == side;
		}
		
		/**
		 * Переопределенная функция расчета стоимости прохождения точки, делает также проходимыми
		 * незанятые точки для определения потенциальных окружений
		 * @param cell точка
		 * @return проходимость
		 */
		override protected function getG(cell:int):int
		{
			if (isSimulation)
			{
				if (_invertG)
					return (cell & 0x0F) > 0 ? 100 : 1;
				return (cell & 0x0F) > 0 ? 1 : 100;
			}
			return super.getG(cell);
		}
	}
}


import modules.capture.Pt;

/**
 * 
 * @author Администратор
 * Вспомогательный класс точки, снабженный характеристикой
 * потенциальной опасности
 * 
 */

class DPt extends Pt
{
	public var danger:Number;		// Потенциальная опасность точки
	
	public function DPt(x:int, y:int, danger:Number = 0.0)
	{
		super(x, y);
		this.danger = danger;
	}
}
