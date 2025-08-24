extends Button

var id: String

func _ready():
	$Animator.play("pop_in")

func remove():
	$Animator.play("pop_out")


func _on_animator_animation_finished(anim_name):
	if anim_name == "pop_out":
		queue_free()

func move_to(pos: Vector2, time: float, delay: float = 0):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", pos, time).set_trans(Tween.TRANS_SINE).set_delay(delay)
