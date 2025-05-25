class_name Main
extends Node2D

'''
────────────────────────────────────────────────────────────────────────────
G.O.L.E.M.
Artificial Life Simulator using Semiotic Emergent ALife Language protocols
────────────────────────────────────────────────────────────────────────────
'''
const GOLEM_VERSION : String = "0.2.4.7 – ALE hybrid method"

## SUB‑VIEWPORT
@onready var sub_viewport : SubViewport = $".."

# Managers & helpers
@onready var map         : Map         = $Map
@onready var ale_manager : ALEManager  = $ALEManager
@onready var nav_cam     : Camera2D    = $NavCam
@onready var grid_vis    : Node2D      = $GridVis
#@onready var stats_panel : StatsPanel  = $"../../../InfoBar/StatsPanelContainer/StatsPanel"
@onready var stats_panel: StatsPanel = %StatsPanel

@onready var simulation_menu : SimulationMenu = $"../SimulationMenu"
@onready var pause_label : Label = $"../CanvasLayer/PauseLabel"

# ───────────────────────────────── WORLD 🞄 BASELINE DEFAULTS
@export_category("World")
@export var world_width  : int = 60
@export var world_height : int = 40
@export var tile_size    : int = 16
@export var ale_count: int = 10
var grid_visible : bool = true               # run‑time toggle

@export_category("ALE Baseline Visuals")
@export var ale_color        : Color = Color.WHITE
@export var trail_color      : Color = Color.BEIGE
@export var collision_color  : Color = Color.CHARTREUSE

@export_category("ALE Baseline Motion")
@export var min_speed : float = 0.5
@export var max_speed : float = 2.0
@export var stop_turns : int  = 10            # turns to pause after collision

@export_category("Stigmergy")
@export var trail_duration : float = 5.0
@export var trail_fade     : float = 3.0

@export_category("Simulation")
@export var simulation_speed : float = 1.0
@export var max_turns        : int   = 0      # 0 = infinite

@export var ENABLE_VISITED_CELLS      : bool = true
@export var ENABLE_TRAILS             : bool = true
@export var ENABLE_COLLISION_HANDLING : bool = true

# Pre‑loaded base definition resource (duplicated & mutated by ALEManager)
var ale_definition : ALEdefinition = preload("res://assets/resources/ale_definition.tres")

# Turn & timing
var time_accumulator : float = 0.0
var current_turn     : int   = 0
var simulation_active : bool = true

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("MainNode")
	Engine.max_fps   = 0
	pause_label.visible = false

	grid_visible = false
	if grid_vis:
		grid_vis.visible = grid_visible
	else:
		push_error("GridVis node not found!")

	# ─── if this is a reset (we have saved params), skip menu ───
	if SessionManager.params.size() > 0:
		# re-apply the original user inputs and start immediately
		apply_simulation_settings(SessionManager.params)
		simulation_menu.visible = false
		return
	# UI → parameters round‑trip
	if simulation_menu:
		simulation_menu.populate_from_params({
			"world_width":  world_width,
			"world_height": world_height,
			"max_turns":    max_turns,
			"ale_count":    ale_count
		})
		simulation_menu.simulation_parameters_set.connect(apply_simulation_settings)
	else:
		push_error("SimulationMenu node not found!")

	simulation_active = false

	if stats_panel:
		stats_panel.update_stat(
			"G.O.L.E.M. Framework\nVERSION",
			GOLEM_VERSION,
			GameColors.TEXT_BLUE
		)

	randomize()


# ───────────────────────────────── FRAME LOOP
func _process(delta : float) -> void:
	if pause_label.visible:
		pause_label.visible = false

	if not simulation_active:
		return

	time_accumulator += delta * simulation_speed
	if time_accumulator >= 1.0:
		time_accumulator = 0.0
		current_turn += 1

		if max_turns > 0 and current_turn >= max_turns:
			MessageLog.send_message(
				"Simulation complete. Reached max turns (%d)" % max_turns,
				GameColors.TEXT_DEFAULT
			)
			end_simulation()

	if stats_panel:
		stats_panel.update_stat("FPS", str(Engine.get_frames_per_second()), GameColors.TEXT_INFO)
		stats_panel.update_stat("Turn", str(current_turn), GameColors.TEXT_DEFAULT)

# ───────────────────────────────── PARAM INPUT
func apply_simulation_settings(params : Dictionary) -> void:

	# load values from session manager
	SessionManager.params = params
	world_width  = params.get("world_width",  world_width)
	world_height = params.get("world_height", world_height)
	max_turns    = params.get("max_turns",    max_turns)
	ale_count    = params.get("ale_count",    ale_count)

	initialize_map()
	initialize_ale_manager()
	await get_tree().process_frame
	_center_camera()

	simulation_active = true

	#MessageLog.send_message("G.O.L.E.M. Framework\nVERSION %s" % GOLEM_VERSION,
							#GameColors.TEXT_DEFAULT)

	var summary := "Map: %dx%d | ALEs: %d" % [world_width, world_height, ale_count]
	MessageLog.send_message(summary, GameColors.TEXT_BLUE)

	if simulation_menu:
		simulation_menu.populate_from_params(params)

# ───────────────────────────────── HELPERS
func end_simulation() -> void:
	simulation_active = false
	for ale in ale_manager.get_children():
		if ale is ALE:
			ale.set_process_mode(PROCESS_MODE_DISABLED)

func initialize_map() -> void:
	map.initialize(world_width, world_height, tile_size, self)

func initialize_ale_manager() -> void:
	ale_manager.initialize(
		map,
		tile_size,
		ale_count,
		ale_color,
		trail_color,
		self,
		ENABLE_VISITED_CELLS,
		ENABLE_TRAILS,
		ENABLE_COLLISION_HANDLING
	)

func _center_camera() -> void:
	await get_tree().process_frame
	if nav_cam and nav_cam.has_method("update_bounds"):
		nav_cam.update_bounds()

func _input(event) -> void:
	if event.is_action_pressed("ui_up"):
		simulation_speed = min(simulation_speed + 0.1, 5.0)
		InfoLog.send_message(str("Simulation speed: ", simulation_speed), GameColors.TEXT_INFO)
		#print("Simulation Speed:", simulation_speed)
	elif event.is_action_pressed("ui_down"):
		simulation_speed = max(simulation_speed - 0.1, 0.1)
		InfoLog.send_message(str("Simulation speed: ", simulation_speed), GameColors.TEXT_INFO)
		#print("Simulation Speed:", simulation_speed)
	elif event.is_action_pressed("reset"):
		MessageLog.send_message("+-- RESET SIMULATION --+", GameColors.TEXT_NOTICE)
		#await get_tree().process_frame
		#get_tree().reload_current_scene()
		if SessionManager.params.size() > 0:
			ale_manager.clear_ales() # clear existing ales from memory
			map.trail_manager.clear_trails()
			apply_simulation_settings(SessionManager.params)

	elif event.is_action_pressed("restart"):
		MessageLog.send_message("Restart simulation.", GameColors.TEXT_BLUE)
		SessionManager.params.clear()
		await get_tree().process_frame
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event.is_action_pressed("toggle_grid"):
		toggle_grid_visibility()
		print("Toggled grid")
	elif Input.is_action_just_pressed("pause_simulation"):
		pause_game()

func toggle_grid_visibility() -> void:
	grid_visible = !grid_visible
	grid_vis.visible = grid_visible

func pause_game() -> void:
	pause_label.visible = true
	get_tree().paused = true
