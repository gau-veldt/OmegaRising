
extends Panel

signal Dismiss()

onready var caption=get_node("./title")
onready var message=get_node("./msg")
onready var dismiss=get_node("./dismiss")

func set_caption(title):
	caption.set_text(title)

func set_message(txt):
	message.set_text(txt)

func set_dismiss(st,msg="Dismiss"):
	dismiss.set_hidden(!st)
	dismiss.set_text(msg)

func onDismiss():
	emit_signal("Dismiss")

func _ready():
	dismiss.set_hidden(true)

