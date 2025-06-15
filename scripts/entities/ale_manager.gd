class_name ALEManager
extends Node

# ────────────────────────────────────────────────────────────────────────────
#  GOLEM · ALEManager  – spawning & respawn logic (hybrid defaults ready)
# ────────────────────────────────────────────────────────────────────────────
@export var ale_scene      : PackedScene     # ALE.tscn
@export var ale_definition : ALEdefinition   # baseline .tres


const ARCHETYPE_BEHAVIORS :Dictionary[String, ALEBehavior]= {
	"Scout": preload("res://assets/resources/behaviors/scout_bhv.tres"),
	# …
}
#const InitConfig = preload("res://scripts/config/init_config.gd")

var rng := RandomNumberGenerator.new()


# Injected from Main
var map  : Map
var main : Main

var tile_size        : int
var ale_count        : int
var ale_body_color   : Color
var default_trail_color : Color

var enable_visited_cells      := true
var enable_trails             := true
var enable_collision_handling := true

var ales      : Dictionary = {}   # name → ALE
var occupancy : Dictionary = {}   # Vector2i → ALE

func _ready() -> void:
	rng.randomize()


# ───────────────────────────────── PUBLIC API
func initialize(
		map_node              : Map,
		ts_init               : int,
		ac_init               : int,
		body_color            : Color,
		trail_color           : Color,
		main_ref              : Main,
		visited_cells_toggle  : bool,
		trails_toggle         : bool,
		collision_toggle      : bool
	) -> void:

	if not map_node or not ale_scene or not ale_definition:
		push_error("ALEManager.initialize(): missing references")
		return

	map                        = map_node
	main                       = main_ref
	tile_size                  = ts_init
	ale_count                  = ac_init
	ale_body_color             = body_color
	default_trail_color        = trail_color
	enable_visited_cells       = visited_cells_toggle
	enable_trails              = trails_toggle
	enable_collision_handling  = collision_toggle

	spawn_ales()

func get_ale_at(grid_pos : Vector2i) -> ALE:
	return occupancy.get(grid_pos, null)

# ───────────────────────────────── INTERNAL HELPERS
func _create_definition_for_spawn(base : ALEdefinition) -> ALEdefinition:
	var def_copy := base.duplicate(false) as ALEdefinition
	# Inject baseline values from Main (hybrid pattern)
	def_copy.body_color = ale_body_color
	def_copy.min_speed  = main.min_speed
	def_copy.max_speed  = main.max_speed
	return def_copy

# ───────────────────────────────── SPAWNING
func spawn_ales() -> void:
	if map.walkable_positions.is_empty():
		push_error("ALEManager.spawn_ales(): no walkable positions")
		return

	var positions := map.walkable_positions.duplicate()
	positions.shuffle()

	var spawned := 0
	for grid_pos in positions:
		if spawned >= ale_count:
			break

		var world_pos := Grid.grid_to_world(grid_pos.x, grid_pos.y, tile_size) \
					   + Vector2(tile_size * 0.5, tile_size * 0.5)

		var ale : ALE = ale_scene.instantiate()
		ale.name   = "ALE_%d" % spawned
		ale.ale_id = spawned
		add_child(ale)

		var def_instance  := _create_definition_for_spawn(ale_definition)
		var seed_symbol   := SEALSymbol.create_random(3)  # 3×3 starter

		ale.initialize(
			spawned,
			def_instance,
			def_instance.body_color,
			default_trail_color,
			tile_size,
			world_pos,
			map,
			main,
			enable_visited_cells,
			enable_trails,
			enable_collision_handling,
			seed_symbol
		)
		# ─── NEW: attach behaviour **after** initialize so archetype is known ───
		var arch := ale.assigned_archetype           # set inside ale.initialize()
		var beh: ALEBehavior= ARCHETYPE_BEHAVIORS.get(arch)
		if beh:
			ale.behavior = beh                      # export var in ale.gd
			beh.on_init(ale)                        # prime per-agent counters



		ales[ale.name]      = ale
		occupancy[grid_pos] = ale
		spawned += 1

# Respawn logic identical but now calls _create_definition_for_spawn()
func respawn_ale(old_ale : ALE) -> void:
	occupancy.erase(old_ale.grid_pos)
	ales.erase(old_ale.name)

	var id_cache   := old_ale.ale_id
	var name_cache := old_ale.name
	var body_col   := old_ale.body_color
	var trail_col  := old_ale.trail_color

	old_ale.queue_free()

	var positions := map.walkable_positions.duplicate()
	positions.shuffle()
	if positions.is_empty():
		push_error("ALEManager.respawn_ale(): no walkable positions")
		return

	var spawn_grid_pos : Vector2i = positions[0]
	var world_pos := Grid.grid_to_world(spawn_grid_pos.x, spawn_grid_pos.y, tile_size) \
				   + Vector2(tile_size * 0.5, tile_size * 0.5)

	var ale : ALE = ale_scene.instantiate()
	ale.name   = name_cache
	ale.ale_id = id_cache
	add_child(ale)

	var def_instance  := _create_definition_for_spawn(ale_definition)
	var seed_symbol   := SEALSymbol.create_random(3)

	ale.initialize(
		id_cache,
		def_instance,
		body_col,
		trail_col,
		tile_size,
		world_pos,
		map,
		main,
		enable_visited_cells,
		enable_trails,
		enable_collision_handling,
		seed_symbol
	)

	ales[ale.name]           = ale
	occupancy[spawn_grid_pos] = ale

func clear_ales() -> void:
	for ale in get_children():
		ale.queue_free()
