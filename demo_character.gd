class_name DemoCharacter
extends StepCharacterBody3D


## Run speed
@export var run_speed := 5.0

## Run acceleration
@export var acceleration := 15.0

## Jump velocity
@export var jump_velocity := 5.0


func _ready() -> void:
	super()


# Handle physics servicing
func _physics_process(delta : float) -> void:
	# Handle player rotation
	if Input.is_key_pressed(KEY_A):
		rotate(up_direction, PI * delta)
	if Input.is_key_pressed(KEY_D):
		rotate(up_direction, -PI * delta)

	# Handle keyboard processing
	var control := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		control += Vector3.FORWARD * run_speed
	if Input.is_key_pressed(KEY_S):
		control += Vector3.BACK * run_speed

	# Apply control when on floor
	if is_on_floor:
		# Get velocity relative to floor
		var local_velocity := velocity - floor_velocity

		# Apply control velocity
		control = global_transform.basis * control
		local_velocity = local_velocity.lerp(control, acceleration * delta)

		# Transform foor velocity back to global
		velocity = floor_velocity + local_velocity

	# Handle jump
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor:
		velocity += up_direction * jump_velocity

	# Move the body
	move_character()
