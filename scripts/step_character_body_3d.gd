class_name StepCharacterBody3D
extends KinematicBody3D


## This script provides basic character movement including the ability to
## walk up steps. 


## Prevent sliding down slopes
@export var stop_on_slope := true

## Maximum height for a step
@export var step_height_max := 0.3

## Minimum height for a step
@export var step_height_min := 0.03

## Depth to look forwards for step
@export var step_depth := 0.3

## Maximum angle (in radians) where a slope is still considered a floor
@export var floor_max_angle := 0.785398

## Rate the character orients to the local gravity field
@export var gravity_orient_rate := 0.0


## Current velocity vector
var velocity := Vector3.ZERO

## Up direction
var up_direction := Vector3.UP

## Floor normal
var floor_normal := Vector3.UP

## Floor angle
var floor_angle := 0.0

## Floor velocity
var floor_velocity := Vector3.ZERO

## Returns true if the body is on the floor
var is_on_floor := false


func _ready() -> void:
	super()


## Move the character
func move_character(add_gravity := true) -> void:
	# Get the delta time
	var delta := get_delta_time()

	# Get the local gravity
	var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
	var gravity := gravity_state.total_gravity

	# Handle reorienting body to local gravity field
	if gravity_orient_rate > 0.0 and gravity.length() > 0.1:
		# Get the old transform
		var old_transform := global_transform

		# Calculate the target transform
		var new_y := -gravity.normalized()
		var new_z := old_transform.basis.x.cross(new_y).normalized()
		var new_x = new_y.cross(new_z)
		var target_transform = Transform3D(new_x, new_y, new_z, old_transform.origin)

		# Reorient body
		global_transform = old_transform.interpolate_with(
			target_transform, 
			gravity_orient_rate * delta).orthonormalized()

	# Update the up direction
	up_direction = global_transform.basis.y

	# Perform initial floor check (just does contact)
	_floor_check()

	# Clear gravity if we don't want to apply it to moves
	if not add_gravity:
		gravity = Vector3.ZERO
	else:
		gravity *= delta

	# Handle moving in the air
	if not is_on_floor:
		_do_air_move(gravity)
	elif not _try_step():
		_do_slide_move(gravity)

	# If the floor is too steep then clear
	if floor_angle > floor_max_angle:
		_clear_floor()


# Performs the initial floor check. Note this does not care how steep the
# floor is, as we may be climbing steps and in contact with the corner of the
# step which will throw off the normal
func _floor_check() -> void:
	# Test if there is a floor beneath the body
	var collision := move_and_collide(up_direction * -0.1, true)
	if not collision:
		_clear_floor()
		return

	# Test if we are moving away from the floor
	if velocity.dot(collision.get_normal()) > 0.1:
		_clear_floor()
		return

	# Set the floor collision
	_set_floor(collision)


# Try performing a step-move
func _try_step() -> bool:
	# Split velocities
	var h_velocity := velocity.slide(up_direction)
	var v_velocity := velocity - h_velocity

	# Skip if moving too slowly
	if h_velocity.length() < 0.1:
		return false

	# Consider how far to cast the player
	var h_cast := h_velocity.normalized() * step_depth
	var v_cast := up_direction * step_height_max

	# Try moving up to clear the step
	var old_pos := global_position
	if move_and_collide(v_cast):
		global_position = old_pos
		return false

	# Try moving over above the step
	if move_and_collide(h_cast):
		global_position = old_pos
		return false

	# Try moving down onto the step
	var step := move_and_collide(-v_cast)
	if not step:
		global_position = old_pos
		return false

	# Save the distance to the step and restore starting position
	var step_dir := global_position - old_pos
	global_position = old_pos

	# Make sure we could land on a step
	if step.get_normal().angle_to(up_direction) > floor_max_angle:
		return false

	# Get the rise and run
	var rise := step_dir.dot(up_direction)
	var run := step_dir.slide(up_direction).length()

	# Ensure we rise up to a step
	if rise < step_height_min:
		return false

	# Ensure we move far enough for a step
	if run < step_depth * 0.5:
		return false

	# Ensure the step rise/run isn't too great
	var step_angle := atan2(rise, run)
	if step_angle > floor_max_angle:
		return false

	# Perform the step-friendly move
	move_and_collide(v_cast)
	velocity = move_and_slide(h_velocity)
	move_and_collide(-v_cast)
	return true


# Do a movement in the air
func _do_air_move(gravity : Vector3) -> void:
	velocity = move_and_slide(velocity + gravity)


# Do a movement on the ground
func _do_slide_move(gravity : Vector3) -> void:
	# Truncate up-move if the ground is too steep
	if floor_angle > floor_max_angle:
		# Split velocity into horizontal/vertical components
		var h_velocity := velocity.slide(up_direction)
		var v_velocity := velocity - h_velocity

		# Get the down direction
		var down_dir := floor_normal.slide(up_direction)
		var down_dot := down_dir.dot(h_velocity)
		if down_dot < 0:
			h_velocity -= down_dir * down_dot

		# Recombine velocities
		velocity = h_velocity + v_velocity
	elif stop_on_slope:
		# Bend gravity into the slope to prevent sliding down hill
		gravity = -floor_normal * gravity.length()

	# Move via sliding
	velocity = move_and_slide(velocity + gravity)


# Set floor information
func _set_floor(floor : KinematicCollision3D) -> void:
	floor_normal = floor.get_normal()
	floor_angle = floor_normal.angle_to(up_direction)
	floor_velocity = floor.get_collider_velocity()
	is_on_floor = true


# Clear floor information
func _clear_floor() -> void:
	floor_normal = up_direction
	floor_angle = 0.0
	floor_velocity = Vector3.ZERO
	is_on_floor = false
