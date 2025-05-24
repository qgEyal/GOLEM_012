class_name InfoLog
extends ScrollContainer
var last_message: Message = null

#@onready var message_list: VBoxContainer = $"%MessageList"
@onready var info_panel: VBoxContainer = $"%InfoPanel"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.info_sent.connect(add_message)

static func send_message(text: String, color: Color) -> void:
	SignalBus.info_sent.emit(text, color)


func add_message(text:String, color: Color) -> void:
	# check if message exists. If it's identical to last message, increase count by 1
	# otherwise create a new message
	if (
		last_message != null and
		last_message.plain_text == text
	):
		last_message.count += 1
	else:
		var message := Message.new(text, color)
		last_message = message
		info_panel.add_child(message)
		# keep proper frame update to stack messages in order
		await get_tree().process_frame
		ensure_control_visible(message)
