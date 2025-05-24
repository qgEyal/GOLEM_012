extends Camera2D
class_name NavCam
###############################################################################
#  NAVIGATION CAMERA
#  Keeps the GOLEM map centred and clamps panning to world edges.
#  Works for any rectangular map + any SubViewport size (tested 1280×720).
###############################################################################

@export var velocity   : int   = 300    # pan speed (pixels / sec)
@export var zoom_speed : float = 0.25   # mouse-wheel zoom increment
@export var min_zoom   : float = 0.75   # most-zoom-in ( < 1 = zoom in )
@export var max_zoom   : float = 2.0    # most-zoom-out ( > 1 = zoom out )

@onready var map : Map = $"../Map"      # assumes NavCam & Map share same parent
# Utility class for grid <-> world conversion
#const Grid = preload("res://scripts/utlities/grid.gd") # called already as a class


var screen_size : Vector2            # SubViewport pixel size (updated in _ready)
var _last_zoom  : Vector2 = Vector2.ONE

# Pan limits (in world pixels). They update whenever zoom or map size changes.
var left_bound  : float
var right_bound : float
var top_bound   : float
var bottom_bound: float
var boundaries_set : bool = false     # used to avoid clamping before ready
var zoom_limited_movement : bool = false   # true = map fits fully, camera locked

func _ready() -> void:
	# Fetch the *actual* size of the SubViewport this camera renders into.
	screen_size = get_viewport_rect().size     # e.g. 1280×720

	# Place camera at map centre and compute initial pan bounds.
	position = _map_center_world()
	update_bounds()

	# Start at minimum zoom so we see whole map if it fits.
	zoom = Vector2(min_zoom, min_zoom)
	_last_zoom = zoom


func _process(delta: float) -> void:
	_handle_movement(delta)

	# If zoom was changed elsewhere (e.g. mouse-wheel), recompute bounds.
	if zoom != _last_zoom:
		_last_zoom = zoom
		update_bounds()

###############################################################################
##  INPUT - movement + zoom
###############################################################################
func _unhandled_input(event: InputEvent) -> void:
	# Mouse-wheel zoom. UP = zoom in, DOWN = zoom out
	if event is InputEventMouseButton and event.pressed and event.button_index in \
		[MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var zoom_change := zoom_speed if event.button_index == MOUSE_BUTTON_WHEEL_UP else -zoom_speed
		var new_zoom : float = clamp(zoom.x + zoom_change, min_zoom, max_zoom)
		zoom = Vector2(new_zoom, new_zoom)     # uniform zoom
		update_bounds()                        # keep map centred
		_last_zoom = zoom
		get_viewport().set_input_as_handled()

###############################################################################
##  MOVEMENT helper
###############################################################################
func _handle_movement(delta: float) -> void:
	if zoom_limited_movement:                  # whole map visible, no panning
		return

	var dir := Vector2.ZERO
	if Input.is_action_pressed("map_left"):  dir.x -= 1
	if Input.is_action_pressed("map_right"): dir.x += 1
	if Input.is_action_pressed("map_up"):    dir.y -= 1
	if Input.is_action_pressed("map_down"):  dir.y += 1

	if dir != Vector2.ZERO:
		position += dir.normalized() * velocity * delta
		# Clamp so we never scroll past the map edges
		position.x = clamp(position.x, left_bound,  right_bound)
		position.y = clamp(position.y, top_bound,   bottom_bound)

###############################################################################
##  BOUNDS & CENTERING
###############################################################################
func update_bounds() -> void:
	"""
	Re-evaluate which axes the map fits on, set camera bounds accordingly,
	and (re)centre the camera when appropriate.
	Runs at _ready() and every time zoom changes.
	"""
	var world_tl : Vector2 = Grid.grid_to_world(0, 0, map.tile_size)
	var world_br : Vector2 = Grid.grid_to_world(map.width, map.height, map.tile_size)
	var map_width  : float   = world_br.x - world_tl.x
	var map_height  : float   = world_br.y - world_tl.y

	# Visible span in world units after zoom
	var screen_width : float = screen_size.x / zoom.x
	var screen_height : float = screen_size.y / zoom.y

	var fits_horizontal : bool = map_width <= screen_width
	var fits_vertical : bool = map_height <= screen_height

	# Default: assume fully locked (map fits both axes)
	zoom_limited_movement = false
	position = _map_center_world()
	left_bound   = position.x
	right_bound  = position.x
	top_bound    = position.y
	bottom_bound = position.y


	# Map exceeds viewport on at least one axis → allow panning where needed
	if !fits_horizontal or !fits_vertical:
		zoom_limited_movement = false

		if !fits_horizontal:
			left_bound  = world_tl.x + screen_width * 0.5
			right_bound = world_br.x - screen_width * 0.5

		if !fits_vertical:
			top_bound    = world_tl.y + screen_height * 0.5
			bottom_bound = world_br.y - screen_height * 0.5

		# Clamp camera after recalculating bounds
		position.x = clamp(position.x, left_bound,  right_bound)
		position.y = clamp(position.y, top_bound,   bottom_bound)

	boundaries_set = true
	# Debug print — comment out if noisy
	#print("Bounds updated | fits_horizontal:", fits_horizontal, " fits_vertical:", fits_vertical)

###############################################################################
##  UTILS
###############################################################################
func _map_center_world() -> Vector2:
	"""
	Returns the exact pixel-centre of the map in world coordinates.
	"""
	return Vector2(map.width * map.tile_size, map.height * map.tile_size) * 0.5
