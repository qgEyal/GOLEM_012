# init_config.gd
# Handles INIT role assignment for GOLEM ALEs via Dirichlet sampling

extends Node
# because it's autoloaded, can't use the classname
# change if assigned at runtime via preload()
class_name InitConfig

# ─── Roguelike role‑assignment parameters ───
const TEAMS: PackedStringArray = ["Pathfinders", "Lorekeepers", "Heralds", "Wardens"]

const TEAM_ALPHA: Dictionary = {
	"Pathfinders": 1.0,
	"Lorekeepers": 1.0,
	"Heralds": 1.0,
	"Wardens": 1.0
}

const ARCHETYPE_ALPHA: Dictionary = {
	"Pathfinders": {"Scout": 1.0, "Explorer": 1.0},
	"Lorekeepers": {"Archivist": 1.0, "Scribe": 1.0},
	"Heralds": {"Courier": 1.0, "Glyphweaver": 1.0},
	"Wardens": {"Sentinel": 1.0, "Alchemist": 1.0}
}

const ARCHETYPE_COMMAND_BIAS: Dictionary = {
	"Scout": "MOVE",
	"Explorer": "MOVE",
	"Archivist": "MEM",
	"Scribe": "MEM",
	"Courier": "COMM",
	"Glyphweaver": "COMM",
	"Sentinel": "SENSE",
	"Alchemist": "PROC"
}

# ─── Assigns a team, archetype, and command bias atomically ───
static func assign_init_role() -> Dictionary:
	var result: Dictionary = {
		"team":      "",
		"archetype": "",
		"command":   ""
	}

	# 1) Sample each team's weight via Γ(α,1) ≈ pow(randf(), 1/α)
	var team_weights: Dictionary = {}
	var team_sum: float       = 0.0
	for team_name in TEAMS:
		var alpha_val: float    = TEAM_ALPHA[team_name]
		var sample_val: float   = pow(randf(), 1.0 / alpha_val)
		team_weights[team_name]  = sample_val
		team_sum                += sample_val

	# 2) Pick one team proportionally
	var pick: float        = randf() * team_sum
	var cumulative: float  = 0.0
	for team_name in TEAMS:
		cumulative += team_weights[team_name]
		if pick <= cumulative:
			result["team"] = team_name
			break

	# 3) Sample archetype within the chosen team
	var arch_weights: Dictionary = {}
	var arch_sum: float         = 0.0
	for arch_name in ARCHETYPE_ALPHA[result["team"]].keys():
		var alpha_val2: float   = ARCHETYPE_ALPHA[result["team"]][arch_name]
		var sample2: float      = pow(randf(), 1.0 / alpha_val2)
		arch_weights[arch_name] = sample2
		arch_sum               += sample2

	pick       = randf() * arch_sum
	cumulative = 0.0
	for arch_name in arch_weights.keys():
		cumulative += arch_weights[arch_name]
		if pick <= cumulative:
			result["archetype"] = arch_name
			break

	# 4) Map chosen archetype to core‑command bias
	result["command"] = ARCHETYPE_COMMAND_BIAS[result["archetype"]]

	return result
