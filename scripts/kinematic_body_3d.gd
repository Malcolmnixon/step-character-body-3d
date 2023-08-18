class_name KinematicBody3D
extends RigidBody3D


## This script provides an extremely simple emulation of the original
## KinematicBody from Godot 3.X - specifically adding support for
## move_and_slide


func _ready() -> void:
	# Freeze in kinematic mode
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true


## Moves the body along a vector. If the body collides with another, it will
## slide along the other body rather than stop immediately.
func move_and_slide(velocity : Vector3) -> Vector3:
	# Loop performing the move
	var motion := velocity * get_delta_time()
	for step in 4:
		var collision := move_and_collide(motion)
		if not collision:
			# No collision, so move has finished
			break

		# Calculate velocity to slide along the surface
		var normal = collision.get_normal()
		motion = collision.get_remainder().slide(normal)
		velocity = velocity.slide(normal)

	# Return final velocity
	return velocity


## Get the delta time for the current processing frame
func get_delta_time() -> float:
	if Engine.is_in_physics_frame():
		return get_physics_process_delta_time()

	return get_process_delta_time()
