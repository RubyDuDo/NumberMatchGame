extends Control

@onready var grid_mgr = get_node("../GridContainer/SubViewport/GridMgr")
@onready var restartBtn = $Restart
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$EndGame.hide()
	if grid_mgr:
		restartBtn.pressed.connect( grid_mgr._on_button_restart)
		grid_mgr.end_game.connect( _on_grid_mgr_end_game )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_grid_mgr_end_game( score : int, is_record: bool ) -> void:
	$EndGame.show()
	if is_record:
		print("show game record")
		showGameRecord( score )
		updateRecord( score )
	else:
		showGameOver( score )
		print("show normal game over")

func updateRecord( score : int ):
	$record/record_score.text = str( score )

func _on_grid_mgr_update_score(score: Variant) -> void:
	$Score.text = str( score )


func _on_grid_mgr_update_step(step_count: Variant) -> void:
	$pinky_bg/left_num.text = str(step_count)

func showGameOver( score ):
	$EndGame/end_info.text = "Game Over!"
	$EndGame/score_info.text = str( score )

func showGameRecord( record_score):
	$EndGame/end_info.text = "New Record!\n" 
	$EndGame/score_info.text = str( record_score )

func showHelp():
	pass

func _on_help_pressed() -> void:
	showHelp()


func _on_restart_pressed() -> void:
	$EndGame.hide()
