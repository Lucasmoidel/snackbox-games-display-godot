extends Control

@export var id_display: Label
@export var prompt_input: LineEdit

var current_prompt_time: int

func _ready() -> void:
	current_prompt_time = int(Time.get_unix_time_from_system())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter-prompt"):
		save_prompt()

func create_id(text):
	return str(text.hash() + current_prompt_time)

func _on_file_selected(path):
	print("Selected file: ", path)

func save_prompt():
	var entered_prompt = prompt_input.text
	var id = create_id(entered_prompt)
	print(entered_prompt)
	
	var prompt_resource: Prompt = Prompt.new()
	prompt_resource.id = id
	prompt_resource.prompt_text = entered_prompt
	
	var path = 'res://prompts/'+id+".res"
	
	var result = ResourceSaver.save(prompt_resource,path)
	
	prompt_input.clear()

func _on_prompt_input_text_changed(new_text: String) -> void:
	var id = create_id(new_text)
	var id_msg = "ID: "+id
	id_display.set_text(id_msg)
	
