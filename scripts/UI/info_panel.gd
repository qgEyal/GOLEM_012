extends VBoxContainer
class_name InfoPanel

@export var default_color: Color = GameColors.TEXT_DEFAULT

var info_labels := {}

func _ready():
	# Optionally preload default font settings
	pass

func update_info(info_name: String, info_value, color: Color = default_color) -> void:
	var label: Label

	if info_name in info_labels:
		label = info_labels[info_name]
	else:
		label = Label.new()
		label.name = info_name
		label.label_settings = preload("res://assets/resources/message_label_settings.tres").duplicate()
		add_child(label)
		info_labels[info_name] = label

	label.label_settings.font_color = color
	label.text = "%s: %s" % [info_name, info_value]
