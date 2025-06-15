@tool
extends Resource
class_name ALEBehavior
# ───────────────────────────────────────────────────────────────────
#  Generic behaviour strategy shared by **all** archetypes.
#  Tunables live in the .tres; run-time values are refined from the
#  agent’s own `seal_symbol` so no extra signals are required.
# ───────────────────────────────────────────────────────────────────

@export var enable_trails_default : bool  = false   # Scouts start OFF
@export var trail_turns_default   : int   = 7       # moves to leave trails
@export var base_trail_duration   : float = 2.0     # s  (can be tweaked)
@export var base_trail_fade       : float = 0.5     # fade speed

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
# ------------ helper ----------------------------------------------------------------
static func _bit_density(bitmask:int, grid:int) -> float:
	var on_bits := 0
	for idx in range(grid * grid):
		on_bits += (bitmask >> idx) & 1
	return float(on_bits) / float(grid * grid)          # 0…1

# ------------ public hooks -----------------------------------------------------------
func on_init(agent: ALE) -> void:
	# prime per-agent counters & flags
	agent.trail_turns_left   = 0
	agent.enable_trails      = enable_trails_default
	agent.last_sensed_terrain = -1

	# derive initial trail parameters from the symbol already assigned
	_configure_from_symbol(agent)


func on_sense(agent: ALE, terrain_id:int) -> void:
	# Early-exit if the terrain didn’t change
	if terrain_id == agent.last_sensed_terrain:
		return

	# Record new terrain & start a fresh 7-turn trail run
	agent.last_sensed_terrain = terrain_id
	agent.trail_turns_left    = trail_turns_default
	agent.enable_trails       = true

	# Randomised colour keyed to mirror_type so Scouts of the same
	# archetype still look different across mirror rules

	## assign random color to trail
	agent.trail_color = Color.from_hsv(_rng.randf(),_rng.randf(),_rng.randf())
	#var hsv_h := float(agent.seal_symbol.mirror_type) / 7.0
	#agent.trail_color = Color.from_hsv(hsv_h, 0.9, 1.0)

	# Ensure Main’s global numbers match Scout spec
	agent.main.trail_duration = base_trail_duration
	agent.main.trail_fade     = base_trail_fade


func on_move(agent: ALE) -> void:
	if agent.trail_turns_left <= 0:
		agent.enable_trails = false
		return

	agent.trail_turns_left -= 1
	# (actual trail drop happens in ALE.leave_trail – already called
	#  elsewhere when enable_trails == true)


# Called once at INIT and can be called again manually if the symbol mutates
func _configure_from_symbol(agent: ALE) -> void:
	var sym := agent.seal_symbol
	if sym == null:
		return

	# Example:  larger grid  → longer trails; denser bitmask → slower fade
	var gs   : int   = sym.grid_size                # 3…8
	var dens : float = _bit_density(sym.bitmask, gs)

	base_trail_duration = clamp(1.0 + gs * 0.3, 1.0, 4.0)      # 1.9–3.4 s
	base_trail_fade     = clamp(0.2 + (1.0 - dens) * 0.6,      # 0.2–0.8
								0.2, 0.8)
