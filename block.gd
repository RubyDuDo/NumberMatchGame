extends Sprite2D

@export  var block_size:int = 64
@export  var blockNum:int = 0;
@export var maxNum = 15
var basic_scale

var cur_tween = null

var is_choosed= false
var is_hover = false
var is_removing = false

var light_colors = [
	Color(0.9, 0.7, 0.8),  # 浅粉色
	Color(0.8, 0.9, 0.7),  # 浅黄绿色
	Color(0.7, 0.8, 0.9),  # 浅蓝色
	Color(0.9, 0.8, 0.7),  # 浅橙色
	Color(0.7, 0.9, 0.8),  # 浅青色
	Color(0.85, 0.75, 0.9), # 浅紫色
	Color(0.75, 0.85, 0.9), # 浅天蓝
	Color(0.9, 0.85, 0.75), # 浅金色
	Color(0.8, 0.7, 0.9),  # 淡紫色
	Color(0.9, 0.75, 0.85), # 浅玫瑰色
	Color(0.75, 0.9, 0.85), # 浅绿松石色
	Color(0.85, 0.9, 0.75), # 浅橄榄色
	Color(0.8, 0.85, 0.9), # 浅灰蓝色
	Color(0.9, 0.8, 0.85), # 浅珊瑚色
	Color(0.85, 0.9, 0.8)  # 浅薄荷绿
]


func setNum( num ):
	blockNum = num;
	updateNum( num )
	
func updateNum( num ):
	if num > maxNum:
		num = maxNum
	$Label.text = str( num )
	self.modulate = light_colors[num-1]

func set_sprite_size(target_size: Vector2):
	if texture:
		var texture_size = texture.get_size()
		scale = target_size / texture_size
		
func _ready() -> void:
	set_sprite_size(Vector2(block_size, block_size))
	basic_scale = scale
	
func onChoose() -> void :
	is_choosed = true
	if is_removing:
		return 
		
	if cur_tween:
		cur_tween.kill()
		
	cur_tween = get_tree().create_tween()
	cur_tween.set_parallel(false)
	var larger_scale = basic_scale * 0.8
	cur_tween.tween_property(self, "scale", larger_scale, 0.05)

func onRelease():
	is_choosed = false
	onRecover()
	
func onHoverEnd():
	is_hover = false
	if is_choosed:
		return 
	onRecover()
	
func onRecover():
	if is_removing:
		return 
		
	if cur_tween:
		cur_tween.kill()
	cur_tween = get_tree().create_tween()
	cur_tween.set_parallel(false)
	cur_tween.tween_property(self, "scale", basic_scale, 0.05)

func onHover():
	is_hover = true
	if is_choosed or is_removing:
		return
		
	if cur_tween:
		cur_tween.kill()
	
	is_hover = true
	cur_tween = get_tree().create_tween()
	cur_tween.set_parallel(false)
	var larger_scale = basic_scale * 0.8
	cur_tween.tween_property(self, "scale", larger_scale, 0.05)

func onRemove():
	is_removing = true
	if cur_tween:
		cur_tween.kill()
		
	cur_tween = get_tree().create_tween()
	cur_tween.set_parallel(false)
	var larger_scale = basic_scale * 1.2
	cur_tween.tween_property(self, "scale", larger_scale, 0.05)
	cur_tween.tween_property(self, "scale", Vector2(0, 0), 0.25)
	
	cur_tween.tween_callback(queue_free)  # 动画完成后自动删除自己

	
