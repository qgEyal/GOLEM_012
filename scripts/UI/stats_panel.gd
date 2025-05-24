# StatsPanel.gd
extends VBoxContainer
class_name StatsPanel

@export var default_color: Color = GameColors.TEXT_DEFAULT

var stat_labels := {}

func _ready():
	# Optionally preload default font settings
	pass

func update_stat(stat_name: String, stat_value, color: Color = default_color) -> void:
	var label: Label

	if stat_name in stat_labels:
		label = stat_labels[stat_name]
	else:
		label = Label.new()
		label.name = stat_name
		label.label_settings = preload("res://assets/resources/message_label_settings.tres").duplicate()
		add_child(label)
		stat_labels[stat_name] = label

	label.label_settings.font_color = color
	label.text = "%s: %s" % [stat_name, stat_value]
