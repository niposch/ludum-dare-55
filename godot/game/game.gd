class_name Game

extends Control

@onready var level_viewport := %LevelViewport
@onready var environment_viewport := %EnvironmentTexture/EnvironmentViewport
@onready var environment_texture: TextureRect = %EnvironmentTexture
@onready var level_texture: TextureRect = %LevelTexture
@onready var environment := %EnvironmentTexture/EnvironmentViewport/Environment
@onready var level := %Level
@onready var main_theme_sound = %MainThemeSound

@onready var health_bar_p1 = $UIOverlay/Grid/Player1/HealthBar
@onready var health_bar_p2 = $UIOverlay/Grid/Player2/HealthBar

@onready var post_processing_rect := $CanvasLayer/ColorRect

var game_timer
const max_game_time = 180.

const LEVEL_VIEW_MOVEMENT_SCALE = 0.9
const ENVIRONMENT_CAMERA_MOVEMENT_SCALE = 0.0005
const FREE_MOVEMENT_ZONE_WIDTH = 50

var delay = 0.0
var sec_since_last_magician_sfx = 0.0

signal show_lose_screen
signal show_win_screen

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			var scaled_mouse_pos = event.position / get_viewport_rect().size
			# scaled_mouse_pos = (scaled_mouse_pos) * 2.0 - Vector2(1.0, 1.0)
			
			var mouse_x = -level.get_level_view_x() + (scaled_mouse_pos.x * level_viewport.size.x)
			var mouse_y = scaled_mouse_pos.y * level_viewport.size.y
			level.move_indicator(Vector2(mouse_x, mouse_y))
			aim_laser(event.position)

func _process(delta):
	var x_offset = level.get_player_offset()
	
	if abs(x_offset) > FREE_MOVEMENT_ZONE_WIDTH:
		if x_offset > 0:
			x_offset -= FREE_MOVEMENT_ZONE_WIDTH
		else:
			x_offset += FREE_MOVEMENT_ZONE_WIDTH
		x_offset += x_offset
		environment.move_view(x_offset * delta * ENVIRONMENT_CAMERA_MOVEMENT_SCALE)
		level.move_view(x_offset * -delta * LEVEL_VIEW_MOVEMENT_SCALE)
	
	%CameraPosLabel.text = "Camera: " + str(environment.get_camera_position())
	%CalculatedCameraLabel.text = "Calc. Camera: " + str(get_environment_camera_pos_from_level_x(level.get_level_view_x()))
	%LevelViewLabel.text = "Level: " + str(level.get_level_view_x())
	%CalculatedLevelViewLabel.text = "Calc. Level: " + str(get_level_x_from_environment_camera_pos(environment.get_camera_position()))
	
	%Harbinger.update(level.viewport_size, get_level_position_from_normalized_screen_position(Vector2(0.5, 0.5)))
	
	sec_since_last_magician_sfx += delta
	if sec_since_last_magician_sfx > 5 && randi()%50 == 0:
		var sound: AudioStreamPlayer = %BoneRattleSound if randi()%2 == 0 else %WizardSounds
		sound.play()
		sec_since_last_magician_sfx = -sound.stream.get_length()

	var r = randi()%300
	if r > 0 and r <= 10:
		var player_pos = get_tree().get_nodes_in_group("player")[0].position
		var dir = (randi() % 2)
		var y = randi()%180
		if dir == 0:
			dir = -1
		#var x = (dir*600+player_pos.x+level.get_player_offset())
		var x = player_pos.x-level.get_player_offset()+dir*350
		var speed_x = -dir*(100+randi()%300)
		var speed_y = randi() % 200-200
		level._add_book(x, y, speed_x, speed_y)
		environment.feedback("spawn_object")
	
	environment.set_game_progress_ratio(1.-game_timer.time_left/max_game_time)
	
	if r == 0:
		var player_pos = get_tree().get_nodes_in_group("player")[0].position
		var dir = (randi() % 2)
		var y = randi()%180
		if dir == 0:
			dir = -1
		#var x = (dir*600+player_pos.x+level.get_player_offset())
		var x = player_pos.x-level.get_player_offset()+dir*350
		var speed_x = -dir*(50+randi()%150)
		var speed_y = randi() % 100-100
		var type = randi()%10
		if type == 0:
			level._add_powerup(x, y, speed_x, speed_y, level.PowerUps.HEALTH_BOOST)
		elif type == 1:
			level._add_powerup(x, y, speed_x, speed_y, level.PowerUps.DASH_INCREASE)
		elif type == 2:
			level._add_powerup(x, y, speed_x, speed_y, level.PowerUps.SPEED_BOOST)
		elif type == 3:
			level._add_powerup(x, y, speed_x, speed_y, level.PowerUps.INVULNERABILITY)
		else:
			level._add_powerup(x, y, speed_x, speed_y, level.PowerUps.HEAL)

func get_level_x_from_environment_camera_pos(camera_pos: float):
	return -(camera_pos / ENVIRONMENT_CAMERA_MOVEMENT_SCALE) * LEVEL_VIEW_MOVEMENT_SCALE

func get_environment_camera_pos_from_level_x(level_x: float):
	return -(level_x / LEVEL_VIEW_MOVEMENT_SCALE) * ENVIRONMENT_CAMERA_MOVEMENT_SCALE


func get_level_position_from_normalized_screen_position(scaled_pos: Vector2):
	var level_x = -level.get_level_view_x() + (scaled_pos.x * level_viewport.size.x)
	var level_y = scaled_pos.y * level_viewport.size.y
	return Vector2(level_x, level_y)

func get_level_position_from_screen_pixel_coords(pixel_coords : Vector2):
	var scaled_pos = pixel_coords / get_viewport_rect().size
	return get_level_position_from_normalized_screen_position(scaled_pos)

func _ready():
	#_on_window_size_changed()
	#get_tree().get_root().size_changed.connect(_on_window_size_changed)
	level.viewport_size = level_viewport.size
	level.total_level_width = abs(get_level_x_from_environment_camera_pos(1.0))
	%TotalLevelWidthLabel.text = "Total level width: " + str(get_level_x_from_environment_camera_pos(1.0))
	
	var players = get_tree().get_nodes_in_group("player")
	var health_bars = [health_bar_p1, health_bar_p2]
	var player_count = 1

	environment.set_game_progress_ratio(0.)
	
	for i in range(player_count):
		print("Activating player "+str(i+1))
		players[i].set_active(true)
		health_bars[i].set_player(players[i])
		players[i].set_health(players[i]._max_health)
	
	for i in range(player_count, len(health_bars)):
		print("Deactivating player "+str(i+1))
		players[i].set_active(false)
		health_bars[i].set_player(null)
	
	for player in players:
		player.died.connect(_on_player_death)
	
	game_timer = Timer.new()
	add_child(game_timer)

	game_timer.start(max_game_time)
	game_timer.timeout.connect(on_game_timeout)
	
	for i in range(player_count):
		players[i].health_changed.connect(environment.on_player_health_changed)
		players[i].health_changed.connect(music_switcher)
	environment.uniform_changed.connect(on_post_processing_uniform_changed)

func on_game_timeout():
	print("you win")
	game_timer.queue_free()
	show_win_screen.emit()

func music_switcher(_old_health, new_health):
	if new_health < 200 && %MainThemeSound.playing:
		%MainThemeSound.stop()
		%ThreatensToLoseSound.play()

func _on_player_death():
	var player_alive_count = 0
	for player in get_tree().get_nodes_in_group("player"):
		if player._active:
			player_alive_count += 1
	if player_alive_count <= 0:
		game_timer.stop()
		print("you lose")
		show_lose_screen.emit()

func project_screen_to_world(screen_pos: Vector2) -> Vector3:
	var camera = environment_viewport.get_camera_3d()
	var viewport_size = camera.get_viewport().get_visible_rect().size
	var nx = (screen_pos.x / viewport_size.x) * 2.0 - 1.0
	var ny = (1.0 - screen_pos.y / viewport_size.y) * 2.0 - 1.0  # Invert Y

	# NDC to 3D point in camera space
	# var near_plane_z = -camera.near  # Use negative near plane distance
	var p_ndc = Vector4(nx, ny, -1, 1.0)

	# Get the projection matrix and its inverse
	var projection = camera.get_camera_projection()
	var inv_projection = projection.inverse()

	# Transform the NDC point by the inverse projection matrix
	var p_camera = inv_projection * p_ndc

	# Divide by w to get correct coordinates (perspective divide)
	p_camera /= p_camera.w

	# Transform the camera space point to world space
	var world_point = camera.global_transform * Vector3(p_camera.x, p_camera.y, p_camera.z)

	return world_point

func aim_laser(screen_space: Vector2):
	var environment_dimensions = Vector2(environment_viewport.size)
	var environment_coords = screen_space * environment_dimensions / get_viewport_rect().size
	var coords = project_screen_to_world(environment_coords)
	print("Coords: ", coords)

	# rotate the laser to point at the click
	environment.laser.look_at(coords)

func _on_window_size_changed():
	environment_viewport.size = get_tree().get_root().size

func on_post_processing_uniform_changed(name: String, value: Variant):
	post_processing_rect.material.set_shader_parameter(name,value)
