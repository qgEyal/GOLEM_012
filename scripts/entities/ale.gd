class_name ALE
extends Node2D

const DIRECTIONS : Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

@onready var sprite : Sprite2D = $Sprite
#@onready var _fallback_definition : ALEdefinition = preload("res://assets/resources/ale_definition.tres")

## set ALE behavior
@export var behavior : ALEBehavior # set by ALEManager at spawn

@export var definition : ALEdefinition : set = set_definition   # injected by manager
@onready var main : Main
@onready var map  : Map

var assigned_team      : String
var assigned_archetype : String



'''
PHASE WORKFLOWS
The initial ALE base-loop begins with an INIT check (run once) and then proceeds
to SENSE -> PROC -> MOVE
The order can change depending on situational conditions.
The phase pipeline is driven by ALEdefinition
'''
var phase_pipeline: PackedStringArray
var phase_index: int

## check for INIT initialization
var _has_initialized: bool = false


## Testing core command behavior
var terrain_id: int
var initial_terrain_name: String
var assigned_command: String


# ───────────────────────────────── STATE MACHINE
enum State { MOVING, STOPPED, COLLIDING, IDLE }

var state        : State  = State.MOVING
var stop_timer   : float  = 0.0
var move_speed   : float
var move_timer   : float  = 1.0
var tile_size    : int
var grid_pos     : Vector2i
var prev_grid_pos : Vector2i
var symbol_grid_size : int = 3

var stop_turns : int
var visited_cells : Dictionary = {}
var body_color    : Color
var trail_color   : Color
var default_color : Color

var enable_visited_cells      : bool
var enable_trails             : bool
var enable_collision_handling : bool

var seal_symbol : SEALSymbol
var ale_id : int = -1

var last_sensed_terrain : int = -1      # used by behaviour
var trail_turns_left    : int = 0



# ───────────────────────────────── INITIALIZATION
func initialize(
		id                     : int,
		def                    : ALEdefinition,
		body_color_param       : Color,
		trail_color_param      : Color,
		size                   : int,
		start_pos              : Vector2,
		map_ref                : Map,
		main_ref               : Main,
		visited_cells_toggle   : bool,
		trails_toggle          : bool,
		collision_toggle       : bool,
		symbol                 : SEALSymbol
	) -> void:

	ale_id                = id
	seal_symbol           = symbol
	body_color            = body_color_param
	trail_color           = trail_color_param
	tile_size             = size
	map                   = map_ref
	main                  = main_ref
	enable_visited_cells  = visited_cells_toggle
	enable_trails         = trails_toggle
	enable_collision_handling = collision_toggle

	if not main:
		push_error("ALE initialise(): Main reference is null!")

	grid_pos = Grid.world_to_grid(int(start_pos.x), int(start_pos.y), tile_size)
	if not map.is_in_bounds(grid_pos):
		get_parent().respawn_ale(self)
		return

	position= Vector2(Grid.grid_to_world(grid_pos.x, grid_pos.y, tile_size)) \
				+ Vector2(tile_size / 2.0, tile_size / 2.0)

	## Assign definition (triggers _apply_definition_data)
	set_definition(def)

	# ─── INIT command log ───

	## Pick fixed test command from ALEdefinition
	var cmds := definition.core_instructions.duplicate()
	print("cmds ", cmds)
	# ensure INIT is first, withouth MOVE (speed optimization)
	phase_pipeline = ["INIT"]
	for c in cmds:
#		if c != "INIT" and c != "MOVE":
		if c != "INIT":
			phase_pipeline.append(c)
	phase_index = 0
	## phase_pipeline holds only INIT, SENSE, PROC, MEM, MOVE,COMM, EVOLVE
	## invoke INIT
	_handle_init()
	#assigned_command = cmds[randi() % cmds.size()]
	#print("ALE %d initialized at: %s. Assigned command %s" % [ale_id, str(grid_pos), assigned_command])


func set_definition(value : ALEdefinition) -> void:
	definition = value
	if is_inside_tree():
		_apply_definition_data()

func _ready() -> void:
	while not main:
		await get_tree().process_frame   # wait until injected into scene

	if definition == null:
		set_definition(definition)
	print("Phase pipeline: ", phase_pipeline)
	prev_grid_pos = grid_pos
	set_process_mode(PROCESS_MODE_PAUSABLE)

# ───────────────────────────────── APPLY DEFINITION → AGENT STATE
func _apply_definition_data() -> void:
	if definition == null or sprite == null:
		return

	# Colour
	if body_color == Color():
		body_color = definition.body_color
	sprite.modulate = body_color
	sprite.modulate.a = 1.0
	default_color    = sprite.modulate

	# Speed
	move_speed = randf_range(definition.min_speed, definition.max_speed)
	# display speed of individual Ales in Info window
	var speed_msg : String = ("Speed of ALE %d: %f " % [ale_id, move_speed])
	InfoLog.send_message(speed_msg, GameColors.TEXT_DEFAULT)


	# Grid size (SEAL)
	symbol_grid_size = definition.seal_grid_size

	# Texture & scaling
	sprite.texture = definition.texture
	var tex_size : Vector2 = sprite.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		sprite.scale = Vector2(tile_size / tex_size.x, tile_size / tex_size.y)
	else:
		push_error("Invalid texture size for ALE sprite!")

# ───────────────────────────────── PROCESS LOOP
func _physics_process(delta: float) -> void:
	## set MOVE in it's own process
	move_timer -= delta * move_speed * main.simulation_speed
	if move_timer <= 0.0:
		move_randomly()
		move_timer = 1.0



func _process(delta : float) -> void:
	if not main or not main.simulation_active:
		return

	if stop_turns > 0:
		stop_timer -= delta * main.simulation_speed
		if stop_timer <= 0:
			stop_turns = 0
			sprite.modulate = default_color
			state = State.MOVING
		return

	if main.max_turns > 0 and main.current_turn >= main.max_turns:
		return

	#move_timer -= delta * move_speed * main.simulation_speed
	#if move_timer <= 0:
		#move_randomly()
		#move_timer = 1.0


	## PHASES
	if phase_index >= phase_pipeline.size():
		# full cycle is complete (INIT + any additional commands)
		# jump back to SENSE (index 1) for the next loop
		phase_index = 1

	var cmd := phase_pipeline[phase_index]
	match cmd:
		"INIT":
			# INIT only runs once per session
			# has been called already in initialize()
			phase_index += 1

		"SENSE":
			_handle_sense()
			#print("SENSE phase")
			phase_index += 1

		"PROC":
			_handle_proc()
			#print("PROC phase")
			phase_index += 1
		## IMPLEMENT REST OF CORE COMMANDS BELOW

		# END match
		_:
			phase_index += 1

	'''
		"MOVE":
			move_timer -= delta * move_speed * main.simulation_speed
			if move_timer <= 0:
				move_randomly()
				move_timer = 1.0
			# after MOVE, loop back to SENSE
			#print("MOVE phase")
			phase_index += 1
		'''

# ───────────────────────────────── MOVEMENT
func move_randomly() -> void:
	if state == State.STOPPED:
		return

	var dirs := DIRECTIONS.duplicate()
	dirs.shuffle()
	for direction in dirs:
		var new_pos: Vector2i = grid_pos + direction
		if enable_collision_handling and check_collision(new_pos):
			handle_collision(new_pos)
			return

		if map.is_in_bounds(new_pos) and map.is_tile_walkable(new_pos):
			var last_pos := grid_pos
			grid_pos = new_pos
			position = Vector2(Grid.grid_to_world(grid_pos.x, grid_pos.y, tile_size)) \
					 + Vector2(tile_size / 2.0, tile_size / 2.0)

			if enable_visited_cells:
				visited_cells[grid_pos] = true
			if enable_trails:
				leave_trail(last_pos)
			return

	state = State.STOPPED
	stop_turns = main.stop_turns

# ───────────────────────────────── COLLISION
func check_collision(new_pos : Vector2i) -> ALE:
	for child in get_parent().get_children():
		if child is ALE and child != self and child.grid_pos == new_pos:
			return child
	return null

func handle_collision(_collision_pos : Vector2i) -> void:
	state = State.STOPPED
	sprite.modulate = main.collision_color
	sprite.scale = Vector2(tile_size / sprite.texture.get_size().x,
						   tile_size / sprite.texture.get_size().y)

	if not map or not map.is_in_bounds(grid_pos):
		main.ale_manager.respawn_ale(self)
		return

	var base_stop_turns := randi_range(5, 15)
	if map.is_high_energy_zone(grid_pos):
		stop_turns = base_stop_turns + 5
	elif map.is_stable_zone(grid_pos):
		stop_turns = max(3, base_stop_turns - 5)
	else:
		stop_turns = base_stop_turns

	stop_timer = stop_turns
	'''
	# ──────────────────────────────────────────────────────────────────
	Establish collisions and core commands
	# ──────────────────────────────────────────────────────────────────
	'''
	var other := get_colliding_ale(_collision_pos)
	if other:
		var msg := "ALE %d collided with ALE %d" % [ale_id, other.ale_id]
		msg += "\nALE %d initialized on terrain type %s" % [ale_id, initial_terrain_name]
		msg += "\nALE %d initialized on terrain type %s" % [other.ale_id, other.initial_terrain_name]

		SignalBus.message_sent.emit(msg, main.collision_color)
	else:
		var msg := "ALE %d COLLIDED at %s" % [
			ale_id,
			str(grid_pos)
		]
		SignalBus.message_sent.emit(msg, main.collision_color)

	SignalBus.message_sent.emit("Stopping for: %d turns\n" % stop_turns,
								main.collision_color)


func get_colliding_ale(target_pos : Vector2i) -> ALE:
	for ale in get_parent().get_children():
		if ale is ALE and ale != self and ale.grid_pos == target_pos:
			return ale
	return null


'''
# ──────────────────────────────────────────────────────────────────
CORE COMMAND HANDLERS
# ──────────────────────────────────────────────────────────────────
'''
func _handle_init() -> void:
	if _has_initialized:
		return
	# Announce
	print("ALE %d INIT at %s" % [ale_id, str(grid_pos)])

	# SENSE terrain at INIT (testing  <========)
	terrain_id = map.map_data[grid_pos].terrain_type # get terrain id number
	initial_terrain_name = map.get_terrain_name(terrain_id)

	# ─── Delegate role‑assignment to config module ───
	'''
	When using a singleton(autoload)
	#var init_conf = preload("res://scripts/config/init_config.gd")
	#var init_data : Dictionary = init_conf.assign_init_role()
	'''

	var init_data: Dictionary = InitConfig.assign_init_role()
	assigned_team      = init_data["team"]
	assigned_archetype = init_data["archetype"]
	assigned_command   = init_data["command"]
	seal_symbol = InitConfig.get_init_symbol(assigned_archetype)

	## plug behavior
	if behavior:
		behavior.on_init(self)

	# Debug
	#definition.init_symbol = InitConfig.get_init_symbol(assigned_archetype)
	print("ALE %d → Team %s, Archetype %s, Command %s, Symbol %s"
		  % [ale_id, assigned_team, assigned_archetype, assigned_command, seal_symbol])

	# ─── End role‑assignment ───


	_has_initialized = true

# -------------------------------------------------------------------
# Called once per update while phase == SENSE
func _handle_sense() -> void:
	# 1. Read the terrain ID of the tile the ALE is on
	terrain_id = map.map_data[grid_pos].terrain_type # get terrain id number

	# 2. Forward to the behaviour (if any) so it can decide
	if behavior:
		behavior.on_sense(self, terrain_id)

	# 3. (Optional) — add any future perception logic here
	#
	#    e.g. scan neighbouring tiles, update local buffers, etc.
	#
	# 4. Finally, advance to the next phase in your FSM
	phase_index += 1        # or whatever your pipeline uses


func _handle_proc() -> void:
	# TODO: process sensed data
	pass

# ───────────────────────────────── TRAILS
func leave_trail(prev_pos : Vector2i) -> void:
	if not map or prev_pos == Vector2i.ZERO or not map.is_in_bounds(prev_pos):
		return

	if not trail_color:
		trail_color = main.trail_color

	var adjusted := trail_color
	adjusted.a = 1.0
	map.trail_manager.add_trail(prev_pos, adjusted,	main.trail_duration, main.trail_fade)
