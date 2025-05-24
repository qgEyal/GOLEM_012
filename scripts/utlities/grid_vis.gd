extends Node2D

var tile_size: int = 0
@export var line_color: Color = Color(0.7, 1, 0.3, 0.2)
@export var line_width: float = 1.0
#@onready var main = get_node("../Main")
@onready var main: Main = $".."

func _ready():
	tile_size = main.tile_size
	#print("Grid size updated to: ", tile_size)
	queue_redraw()


func _draw():
	# Make sure viewport_size is in pixels
	var viewport_size: Vector2 = Vector2(main.world_width, main.world_height) * tile_size
	#print("Viewport size in pixels: ", viewport_size)

	# Calculate number of grid lines correctly
	var columns = ceil(viewport_size.x / tile_size)
	var rows = ceil(viewport_size.y / tile_size)
	#print("Columns:", columns, " Rows:", rows)

	# Draw vertical lines
	for x in range(columns + 1):
		var x_pos = x * tile_size
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, viewport_size.y), line_color, line_width)

	# Draw horizontal lines
	for y in range(rows + 1):
		var y_pos = y * tile_size
		draw_line(Vector2(0, y_pos), Vector2(viewport_size.x, y_pos), line_color, line_width)

# Ensure grid updates dynamically
func _on_GridSizeChanged(new_size: int):
	tile_size = new_size
	queue_redraw()

'''
extends Node2D


var cell_size: int = 0
#@export var grid_size: int = 32  # Size of each grid square (in pixels)
@export var line_color: Color = Color(0.7, 1, 0.3, 0.2)  # Color of the grid lines (white with some transparency)
@export var line_width: float = 1.0  # Thickness of the grid lines
@onready var main = get_node("/root/Main")

# This function is called when the scene is ready
func _ready():

	cell_size = main.cell_size
	print("Grid size updated to: ",cell_size)

	# Call the draw function to render the grid
	queue_redraw()

# This function is called whenever the node needs to be redrawn
func _draw():
	#var viewport_size = get_viewport_rect().size  # Get the size of the game world (viewport)
	var viewport_size: Vector2 = Vector2(main.world_width, main.world_height)
	print (viewport_size * cell_size)
	#print(get_viewport_rect().size)

	var columns = ceil(viewport_size.x)
	var rows = ceil(viewport_size.y)
	# Calculate the number of columns and rows based on the grid size and viewport dimensions
	#var columns = ceil(viewport_size.x / cell_size)
	#var rows = ceil(viewport_size.y / cell_size)
	print("columns ", columns, " rows ", rows)

	# Draw vertical lines for the columns
	for x in range(columns + 1):
		var x_pos = x * cell_size
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, viewport_size.y), line_color, line_width)
		# Call the draw function to render the grid
		queue_redraw()

	# Draw horizontal lines for the rows
	for y in range(rows + 1):
		var y_pos = y * cell_size
		draw_line(Vector2(0, y_pos), Vector2(viewport_size.x, y_pos), line_color, line_width)



# This function is called when the grid size needs to be updated dynamically
func _on_GridSizeChanged(new_size: int):
	cell_size = new_size  # Update the grid size
	queue_redraw()  # Redraw the grid with the new size
'''
