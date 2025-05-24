extends Node2D
class_name TrailManager

var trails = {}  # Dictionary to store active trails {grid_pos: {time_left, color}}
@onready var map: Map
#@onready var ale_definition: ALEdefinition = preload("res://assets/resources/ale_definition.tres")

var trail_color: Color
func _ready():
	"""
	Ensures the trail manager properly resets its stored colors.
	"""
	trails.clear()  # Clear all trails before adding new ones
	print("TrailManager Reset: Trails Cleared")


func add_trail(grid_pos: Vector2i, color: Color, duration: float, fade_speed: float):
	"""
	Adds a new trail at the given grid position.
	Ensures the trail color does not override ALE colors.
	"""

	trail_color = color
	#if not trail_color:
		#trail_color = ale_definition.trail_color



	trail_color.a = 1.0  # Keep color fully opaque when applied

	trails[grid_pos] = {
		"time_left": duration,
		"color": trail_color,
		"fade_speed": fade_speed
	}

	queue_redraw()  # Redraw when a new trail is added




func _process(delta):
	"""
	Updates and fades trails over time while ensuring ALEs are not affected.
	"""
	var to_remove = []

	for grid_pos in trails.keys():
		trails[grid_pos]["time_left"] -= delta
		if trails[grid_pos]["time_left"] <= 0:
			to_remove.append(grid_pos)

	# **Remove expired trails without affecting ALEs**
	for pos in to_remove:
		if trails.has(pos):
			trails.erase(pos)

	queue_redraw()  # Redraw after updates

'''
func modify_base_layer():
	"""
	Modifies the BaseLayer if trails exceed a threshold.
	"""
	var trail_counts = {}

	# Count trail occurrences per tile
	for grid_pos in trails.keys():
		if not trail_counts.has(grid_pos):
			trail_counts[grid_pos] = 0
		trail_counts[grid_pos] += 1

	# Modify terrain if a threshold is exceeded
	for grid_pos in trail_counts.keys():
		if trail_counts[grid_pos] >= 5:  # Example threshold
			map.base_layer.set_cell(grid_pos, 0, Vector2i(2, 0))  # Change terrain type
'''

func _draw():
	"""
	Draws trails with fading transparency, ensuring ALEs remain fully opaque.
	"""
	for grid_pos in trails.keys():
		var data = trails[grid_pos]

		# **Ensure only trails fade, not ALEs**
		var trail_alpha = max(0.2, data["time_left"] / data["fade_speed"])
		trail_color = data["color"]
		trail_color.a = clamp(trail_alpha, 0.2, 1.0)  # Only fade trails, not ALEs

		# **Check if an ALE exists in this position**
		if map and map.map_data.has(grid_pos):
			var tile = map.map_data[grid_pos]
			if tile:
				continue  # Skip drawing a trail if an ALE is present

		# **Draw only trails, preserving ALE visibility**
		var world_pos = Grid.grid_to_world(grid_pos.x, grid_pos.y, 16)
		draw_rect(Rect2(world_pos, Vector2(16, 16)), trail_color, true)
