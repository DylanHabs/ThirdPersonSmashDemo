extends Node3D

@export var speed: float
@export var damage: int
@export var knock: float
var dir = Vector3.ZERO
var p

func _on_timer_timeout():
	queue_free()
	#visible = false

func _physics_process(delta):
	if is_multiplayer_authority():
		global_position = global_position.move_toward(global_position + dir, delta * speed)

func _on_area_3d_body_entered(body):
	if body.name != p: 
		if is_multiplayer_authority():
			body.rpc("hurtRPC", damage, knock, global_position.direction_to(body.global_position) + Vector3(0, 0.5, 0))
		queue_free()
		#visible = false
