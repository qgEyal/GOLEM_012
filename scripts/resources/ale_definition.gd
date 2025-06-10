class_name ALEdefinition
extends Resource

# ────────────────────────────────────────────────────────────────────────────
#  Static definition data (duplicated & mutated per agent)
# ────────────────────────────────────────────────────────────────────────────
# SEAL symbol parameters
var _seal_grid_size : int = 3
@export var seal_grid_size : int : set = _set_grid_size

@export var core_instructions : PackedStringArray = [
	"INIT", "SENSE","PROC", "MEM", "MOVE", "COMM", "EVOLVE"
]

@export var symbol_id      : int   = 0
@export var symmetry_mode  : int   = 0       # 0–6
@export var mutation_rate  : float = 0.6     # demo knob

# Visuals & motion (baseline injected by ALEManager)
@export var body_color : Color = Color.WHITE
@export var min_speed  : float = 0.5
@export var max_speed  : float = 2.0

# Sprite
@export var texture : Texture2D
@export var size    : Vector2 = Vector2(16, 16)

# ─────────────────────────────────
func _set_grid_size(value : int) -> void:
	_seal_grid_size = clamp(value, 3, 8)
