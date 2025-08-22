extends Control

@export var id_display: Label
@export var prompt_input: LineEdit

var current_prompt_time: int

func _ready() -> void:
	current_prompt_time = int(Time.get_unix_time_from_system())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter-prompt"):
		save_prompt()

func save_prompt():
	var entered_prompt = prompt_input.text
	print(entered_prompt)
	prompt_input.clear()

func _on_prompt_input_text_changed(new_text: String) -> void:
	var id = str(new_text.hash() + current_prompt_time)
	var id_msg = "ID: "+id
	id_display.set_text(id_msg)
	
