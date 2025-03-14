extends Node2D

var arrBlocks: Array = []

var maxRow = 5
var maxCol = 5
var blockMod
var movingTween:int = 0
var cell_size = 128

var GEN_NUM_MAX = 6
var draging_cell = null
var hover_cell = null
var tweenID = 0

var falltime = 0.3

signal end_game( score: int)
signal update_score(score)
signal update_step(step_count)
signal remove_block

var curScore :int = 0
var curStep  :int = 5
var max_step = 5
var recordScore : int = 0;

var is_game_end = true;
var dirs = [ Vector2(0,1), Vector2(0, -1), Vector2(1,0), Vector2(-1,0)]

var player_info_file = "user://playerinfo.json"
	
func initLogicCells():
	for row in range( maxRow ):
		var arrRows: Array = []
		for col in range( maxCol ):
			arrRows.push_back( null )
		
		arrBlocks.push_back( arrRows )

func save_record( ):
	var save_data = {}
	save_data["record"] = recordScore
	var file = FileAccess.open(player_info_file, FileAccess.WRITE)
	if file:
		file.store_string( JSON.stringify(save_data))
		file.close()
	else:
		print("Save_record fail!")

func load_record():
	if FileAccess.file_exists(player_info_file):
		var file = FileAccess.open( player_info_file, FileAccess.READ)
		if file:
			var data_string = file.get_as_text()
			var save_data = JSON.parse_string(data_string)
			file.close()
			recordScore = save_data["record"]
		else:
			print("Load_record fail!")
	else:
		print("No player info file!")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blockMod = preload("res://block.tscn")  # 预加载场景
	$fly_block.hide()
	initLogicCells();
	onNewGame()
	print("当前 FPS:", Engine.get_frames_per_second())
	load_record()
	
	
func check_hover():
	if is_game_end:
		return 
		
	var global_pos = get_global_mouse_position()
	var block_index = get_grid_pos( global_pos )
	var hover_block = get_block( block_index )
	if hover_block:
		if hover_cell != block_index:
			hover_block.onHover()
			if hover_cell != null:
				var pre_hover_block = get_block( hover_cell )
				pre_hover_block.onHoverEnd()
			hover_cell = block_index
	else:
		if hover_cell != null:
			var pre_hover_block = get_block( hover_cell )
			pre_hover_block.onHoverEnd()
		hover_cell = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_hover()

func get_random_except( arr_nums :Array ) -> int :
	var rand = getRandNum();
	while rand in arr_nums:
		rand = (rand ) % GEN_NUM_MAX + 1
	return rand
		
func switch_block_num( pos: Vector2 ):
	var arr_nearbys = []
	for dir in dirs:
		var nearby = pos + dir;
		var nearby_block = get_block( nearby )
		if nearby_block:
			arr_nearbys.append( nearby_block.blockNum)
	
	var cur_block = get_block( pos )
	if cur_block:
		var new_num = get_random_except( arr_nearbys )
		print("Switch block Num:", cur_block.blockNum, ", to:", new_num )
		cur_block.setNum( new_num )
		
	
	
	
#if there is elimination, just replace one cell	
func check_for_remove_before():
	for row in range( maxRow ):
		for col in range( maxCol ):
			var arrSame=[]
			var can_remove = _check_remove_pos( Vector2(row, col),arrSame)
			if can_remove:
				switch_block_num( Vector2(row, col ))
		
func onNewGame():
	clear()
	emit_signal("update_score", curScore)
	emit_signal("update_step", curStep)
	is_game_end = false
	for i in range(maxCol):
		generateBlocks( i, maxRow )
	
	check_for_remove_before()
	
	for i in range(maxCol):
		show_fall_col_generated( i, maxRow )
		
func get_block( pos: Vector2) -> Sprite2D :
	if is_valid_cell( pos ):
		return arrBlocks[pos.x][pos.y]
	else:
		return null
		
func _checkRemovePosR( targetNum : int, arrSame: Array, pos : Vector2 ) :
	var block = get_block( pos )
	if block == null || block.blockNum != targetNum :
		return;
			
	if pos in arrSame:
		return;
		
	arrSame.push_back( pos )
	
	
	for dir in dirs :
		var newPos = pos + dir
		_checkRemovePosR( targetNum, arrSame, newPos )
		
		

func _check_remove_pos( pos: Vector2, arrSame:Array)	 ->bool :
	var block = get_block( pos )
	if !block:
		return false
	
	_checkRemovePosR( block.blockNum, arrSame, pos )
	if arrSame.size() >= 3 :
		return true;
	else:
		return false;	
	
# check the given point if there is a remove	
func checkRemovePos( pos : Vector2 ) -> bool :
	var arrSame = []
	var can_remove = _check_remove_pos( pos, arrSame )
	if can_remove:
		removeBlocks( arrSame, pos )
		print("can_remove")
	return can_remove

func fallCol( col ):
	var count = 0;
	var arrOri = [] 
	var nullCount = 0;
	var targetRow = maxRow - 1
	var tween
	for row in range( maxRow -1, -1, -1 ):
		if arrBlocks[row][col] == null:
			nullCount += 1
			continue;
			
		
		if row != targetRow:
			if tween == null:
				tween = get_tree().create_tween()
				tween.set_parallel( true )
				movingTween += 1
				var index = getTweenID()
				tween.finished.connect(_on_tween_finished.bind( "fal", index, col, row)) 
				
			arrBlocks[targetRow][col] = arrBlocks[row][col] 
			tween.tween_property(arrBlocks[row][col], "position", getPos( targetRow , col ), falltime).set_trans(Tween.TRANS_BOUNCE)
			arrBlocks[row][col] = null
		
		targetRow -= 1;

	return nullCount
			

func updateScore( score ):
	curScore += score
	emit_signal("update_score", curScore)
	print("Update socre:", score )

func updateSteps( step ):
	var oriStep = curStep
	curStep += step;
	print("Update steps:", step)
	if curStep > max_step:
		curStep = max_step
	else:
		if curStep < 0:
			curStep = 0
		
	if curStep != oriStep:
		emit_signal("update_step", curStep)
		
	if curStep <= 0 :
		print("Game Over")
		is_game_end = true
		var is_record = false
		if curScore > recordScore:
			recordScore = curScore;
			is_record = true
			save_record( )
		emit_signal("end_game", curScore, is_record )
	
#f
func removeBlocks( arrRemove: Array, oriPos: Vector2):
	
	var score = arrRemove.size() * arrBlocks[oriPos.x][oriPos.y].blockNum
	updateScore( score )
	emit_signal("remove_block")
	
	#remove these block
	for pos in arrRemove:	
		var block = get_block( pos )			
		if block:
			if pos == oriPos:
				block.setNum( block.blockNum + 1)
			else:
				block.onRemove()
				arrBlocks[pos.x][pos.y] = null
	
	#let the upper to fall
	var arrCount = [];
	for i in range( maxCol ):
		arrCount.append(0)
	
	for col in range( maxCol ):
		arrCount[col] = fallCol( col )
	
	# generate new blocks
	for col in range( maxCol ):
		generateBlocks( col, arrCount[col])
		show_fall_col_generated(col, arrCount[col] )
	
# check the map for remove	
func checkRemove( index ):
	for row in range(maxRow):
		for col in range(maxCol):
			var hasRemove = checkRemovePos( Vector2(row, col) )
			if hasRemove :
				updateSteps(1)
				return
	
func getPos( row, col )->Vector2 :
	var x = cell_size / 2 + cell_size * col
	var y = cell_size / 2 + cell_size * row
	return Vector2( x, y )

func getRandNum()->int:
	return randi() % GEN_NUM_MAX +1;

func getTweenID():
	tweenID+= 1;
	return tweenID
# generate count blocks at col, put their position, logic position
# and let them follow

func show_fall_col_generated( col, count):
	if count == 0 :
		return
			
	var tween = get_tree().create_tween()
	tween.set_parallel( true )
	var index = getTweenID()
	movingTween += 1
	tween.finished.connect(_on_tween_finished.bind( "gen", index, col, count) ) 
	
	for i in range( count ):
		var rowIndex = count - i -1 ;
		var block = arrBlocks[rowIndex][col]
		
		var pos = getPos(-i-1, col)
		block.position = pos
		
		tween.tween_property(block, "position", getPos( rowIndex , col ), falltime).set_trans(Tween.TRANS_BOUNCE)
		
		
	
	
func generateBlocks( col , count ): 
	if count <= 0 :
		return 
	
	var arr_nums = []

	for i in range( count ):
		var block = blockMod.instantiate()
		var rowIndex = count - i -1 ;
		arrBlocks[rowIndex][col] = block
		var num = getRandNum();
		block.setNum( num )
		add_child( block )

# remove all the blocks 
func clear():
	curScore = 0
	curStep = max_step
	for row in range( maxRow ):
		for col in range( maxCol ):
			var block = arrBlocks[row][col]
			if block != null:
				block.queue_free();
				arrBlocks[row][col] = null
				
func _on_tween_finished( type, index: int, col:int, count:int):
	#print("_on_tween_finished:", type ,"_", index,"_", col, "_", count)
	movingTween-=1;
	if movingTween == 0 :
		checkRemove( index )
		

		
func _on_button_restart():
	onNewGame()
	
func get_grid_pos( pos )-> Vector2:
	var local_pos = to_local( pos )
	
	var row = int(local_pos.y / cell_size)
	var col = int(local_pos.x / cell_size)
	#print("get_grid:", pos , "index:", row, "_", col)
	return Vector2( row, col)

func is_valid_cell( cell ) ->bool :
	if cell.x >= maxRow or cell.x < 0 :
		return false;
	if cell.y >= maxCol or cell.y < 0 :
		return false;
	return true;
	
func on_grid_cell_clicked( clicked_cell ):
	if draging_cell != null :
		on_grid_cell_released( draging_cell )
	
	draging_cell = clicked_cell
	arrBlocks[draging_cell.x][draging_cell.y].onChoose()
	print("click cell", clicked_cell) 
	#todo: show animation

func showFlyBlock( pos_from, pos_to , fly_num ):
	var pos_ori = getPos( pos_from.x, pos_from.y )
	var pos_target = getPos( pos_to.x, pos_to.y )
	$fly_block.show()
	$fly_block.position = pos_ori
	$fly_block.setNum( fly_num )
	
	var tween = get_tree().create_tween()
	tween.tween_property($fly_block, "position", pos_target, 0.2)
	tween.tween_callback( func():
		$fly_block.hide()
		var target_block = get_block( pos_to )
		target_block.setNum( target_block.blockNum + $fly_block.blockNum)
		
		var defer_tween = get_tree().create_tween()
		defer_tween.tween_interval(0.1)  # 延迟 0.1 秒
		defer_tween.tween_callback(func(): 		
			var hasRemove = checkRemovePos( pos_to )
			if !hasRemove:
				updateSteps(  -1 )
			)
		)
	
func release_choose():
	var draging_block = get_block( draging_cell )
	if draging_block:
		draging_block.onRelease()
	draging_cell = null
	
func on_grid_cell_released( clicked_cell ):
	print("release cell", clicked_cell) 
	if draging_cell == null:
		return
	
	if draging_cell == clicked_cell:
		release_choose()
		return
	
	if !is_nearby( draging_cell, clicked_cell ):
		release_choose()
		return
	
	#todo show flay animation
	var dragingBlock = get_block( draging_cell )
	var clickedBlock = get_block( clicked_cell )
	if clickedBlock == null:
		release_choose()
		return
	
	showFlyBlock( draging_cell, clicked_cell, dragingBlock.blockNum )		
	draging_cell = null
	dragingBlock.onRelease()
		
func is_nearby( pos1:Vector2, pos2: Vector2 )->bool:
	if abs( pos1.x - pos2.x ) <= 1 and abs( pos1.y-pos2.y) <= 1:
		return true;
	return false
	
func _input( event ):
	if is_game_end:
		return 
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = get_grid_pos( event.position )
		if !is_valid_cell( clicked_cell ):
			return
		else:
			on_grid_cell_clicked( clicked_cell)
		
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = get_grid_pos( event.position )
		on_grid_cell_released( clicked_cell)

func _unhandled_gui_input( event ):
	print("GridMgr:_unhandled_gui_input")
		
	
