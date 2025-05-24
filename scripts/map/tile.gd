class_name Tile
extends RefCounted  # Lightweight, GC-managed class

var coordinates: Vector2i
var terrain_type: Map.TerrainType
var has_resource: bool = false
var ale_presence: bool = false
var trail_intensity: float = 0.0

func _init(coords: Vector2i, type: Map.TerrainType = Map.TerrainType.STABLE):
	coordinates = coords
	terrain_type = type
