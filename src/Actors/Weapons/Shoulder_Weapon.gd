extends Weapon
class_name ShoulderWeapon

var is_attacking := false
var attack_duration := 0.45

func _ready() -> void:
	._ready()
	Event.listen("shot_lemon", self, "on_lemon_shot_created")

func on_lemon_shot_created(emitter, shot):
	if emitter != self:
		connect_shot_event(shot)

func add_projectile_to_scene(charge_level) -> void:
	var shot = .add_projectile_to_scene(charge_level)
	if charge_level < 1:
		Event.emit_signal("shot_lemon", self, shot)

func has_ammo() -> bool:
	return shots_currently_alive < max_shots_alive

func connect_charged_shot_event(_shot):
	_shot.connect("projectile_started", self, "on_charged_shot_created")
	_shot.connect("projectile_end", self, "on_charged_shot_end")
	if _shot.has_method("set_creator"):
		_shot.set_creator(arm_cannon.character)
	if _shot.has_method("initialize"):
		_shot.call_deferred("initialize", arm_cannon.character.get_facing_direction())

func position_shot(shot) -> void:
	shot.global_position = character.global_position
	shot.projectile_setup(character.get_facing_direction(), character.altfire_position.position)

func fire(charge_level := 0) -> void:
	if is_attacking:
		return
	
	is_attacking = true
	
	var character = get_parent().get_parent()
	
	# Lock player movement and freeze in midair
	character.stop_listening_to_inputs()
	character.set_horizontal_speed(0)
	character.set_vertical_speed(0)
	
	# Check if player is in the air (not on floor)
	if character.is_on_floor():
		# Ground animation
		character.play_animation_once("shot_strong")
	else:
		# Air animation
		character.play_animation_once("shot_strong_air")
	
	# Spawn the projectile
	.fire(charge_level)
	
	# Start timer to unlock
	Tools.timer(attack_duration, "_unlock_player", self)

func _unlock_player():
	is_attacking = false
	
	var character = get_parent().get_parent()
	character.start_listening_to_inputs()
	
	if character.is_on_floor():
		character.play_animation("idle")
	else:
		character.play_animation("fall")

# Keep the player frozen during the attack
func _physics_process(delta: float) -> void:
	if is_attacking:
		var character = get_parent().get_parent()
		character.set_vertical_speed(0)
		character.set_horizontal_speed(0)
