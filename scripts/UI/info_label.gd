class_name InfoLabel
extends Label

const base_settings := preload("res://assets/resources/message_label_settings.tres")

func _ready():
	var custom_settings := base_settings.duplicate()
	custom_settings.font_color = GameColors.TEXT_BLUE
	label_settings = custom_settings
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func update_info(words: String, color: Color = GameColors.TEXT_BLUE) -> void:
	self.text = words

	# Create and assign a fresh LabelSettings each time (if needed)
	if label_settings:
		label_settings.font_color = color
	else:
		var new_settings := base_settings.duplicate()
		new_settings.font_color = color
		label_settings = new_settings
