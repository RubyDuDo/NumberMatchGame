extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$UI.updateRecord( $GridContainer/SubViewport/GridMgr.recordScore )


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input( event ):
	if event is InputEventMouseButton:
		print("Main get _input")
		
func _gui_input(event):
	if event is InputEventMouseButton:
		print("Main get gui_input")
	pass

func _unhandled_gui_input( event ):
	print("Main:_unhandled_gui_input")


func _on_grid_mgr_remove_block() -> void:
	$remove_sound.play()
