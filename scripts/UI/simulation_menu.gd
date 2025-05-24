extends CanvasLayer
class_name SimulationMenu

signal simulation_parameters_set(params: Dictionary)

@onready var map_width := $Panel/VBoxContainer/MapWidth
@onready var map_height := $Panel/VBoxContainer/MapHeight
#@onready var tile_size := $Panel/VBoxContainer/TileSize
@onready var max_turns: SpinBox = $Panel/VBoxContainer/MaxTurns
@onready var ale_count := $Panel/VBoxContainer/ALECount
@onready var start_button := $Panel/VBoxContainer/StartButton
@onready var restart_button := $Panel/VBoxContainer/RestartButton
@onready var main: Main = $"../Main"

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

# Setter to read values from main.gd
func populate_from_params(params: Dictionary) -> void:
	# Safely set SpinBox values from a dictionary
	if params.has("world_width"):
		$Panel/VBoxContainer/MapWidth.value  = params["world_width"]
	if params.has("world_height"):
		$Panel/VBoxContainer/MapHeight.value = params["world_height"]
	if params.has("max_turns"):
		$Panel/VBoxContainer/MaxTurns.value  = params["max_turns"]
	if params.has("ale_count"):
		$Panel/VBoxContainer/ALECount.value  = params["ale_count"]


func _on_start_pressed():
	var params = {
		"world_width": map_width.value,
		"world_height": map_height.value,
		"ale_count": ale_count.value,
		"max_turns": max_turns.value
	}
	simulation_parameters_set.emit(params)
	visible = false  # Hide menu after starting

func _on_restart_pressed():
	await get_tree().process_frame  # Ensures input is fully processed
	get_tree().reload_current_scene()
