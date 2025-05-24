class_name Grid
extends Object

static func grid_to_world(grid_x: int, grid_y: int, tile_size: int) -> Vector2:
	return Vector2(grid_x * tile_size, grid_y * tile_size)



static func world_to_grid(world_x: float, world_y: float, tile_size: int) -> Vector2i:
	return Vector2i(round(world_x / tile_size), round(world_y / tile_size))  # Ensures correct grid alignment



"""
Old variants of static function
"""
#static func world_to_grid(world_width: int, world_height: int, tile_size: int) -> Vector2i:
	#return Vector2i(world_width / tile_size, world_height / tile_size)

#static  func grid_to_world(world_width: int, world_height:int, tile_size: int) -> Vector2i:
	#var grid_pos := Vector2i(world_width, world_height)
	#var world_pos: Vector2i = grid_pos * tile_size
	#return world_pos

#static func world_to_grid(world_width: int, world_height:int, tile_size: int) -> Vector2i:
	#var world_pos := Vector2i(world_width, world_height)
	#var grid_pos: Vector2i = world_pos / tile_size
	#return grid_pos
