extends Control

@export var id_display: Label
@export var prompt_input: LineEdit

@export var audio_select_window: FileDialog
@export var file_loaded_label: Label

@export var prompt_list: VBoxContainer

var current_prompt_time: int

var current_audio_file_loaded: String

var dir: DirAccess
var prompt_item: PackedScene

func _ready() -> void:
	prompt_item = load("res://scenes/prompt_item.tscn")
	current_prompt_time = int(Time.get_unix_time_from_system())
	set_id_display(create_id(prompt_input.text))
	
	dir = DirAccess.open('res://prompts')
	
	refresh_prompts()

func _process(delta: float) -> void:
	if current_audio_file_loaded != "":
		$HBoxContainer/RemoveButton.show()
	else:
		$HBoxContainer/RemoveButton.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter-prompt"):
		save_prompt()

func create_id(text):
	return str(text.hash() + current_prompt_time)

func _on_file_selected(path):
	print("Selected file: ", path)

func display_prompts():
	dir.get_files()

func save_prompt():
	var entered_prompt = prompt_input.text
	var id = create_id(entered_prompt)
	print(entered_prompt)
	
	var prompt_resource: Prompt = Prompt.new()
	prompt_resource.id = id
	
	if current_audio_file_loaded != "":
		prompt_resource.prompt_audio = load(current_audio_file_loaded)
	
	prompt_resource.prompt_text = entered_prompt
	
	var path = 'res://prompts/'+id+".res"
	
	var result = ResourceSaver.save(prompt_resource,path)
	
	prompt_input.clear()
	file_loaded_label.set_text("No File Loaded")
	current_audio_file_loaded = ""
	current_prompt_time = int(Time.get_unix_time_from_system())
	set_id_display(create_id(prompt_input.text))
	display_prompts()

func set_id_display(id):
	var id_msg = "ID: "+id
	id_display.set_text(id_msg)

func _on_prompt_input_text_changed(new_text: String) -> void:
	var id = create_id(new_text)
	set_id_display(id)
	
func _on_open_audio_select_button_button_down() -> void:
	audio_select_window.popup_centered(Vector2i(800, 600))


func _on_audio_select_window_file_selected(path: String) -> void:
	print(path)
	current_audio_file_loaded = path
	var splitPath = path.split('/')
	file_loaded_label.set_text(splitPath[-1])


func _on_remove_button_button_down() -> void:
	if current_audio_file_loaded != "":
		current_audio_file_loaded = ""
		file_loaded_label.set_text("No File Loaded")


func _on_button_button_down() -> void:
	save_prompt()
	refresh_prompts()
	
func refresh_prompts():
	for child in prompt_list.get_children():
		child.queue_free()
	
	var files: Array[Prompt]
	var paths := dir.get_files()
	
	print(paths)
	
	for file in paths:
		
		var resource:= load('res://prompts/'+file)
		
		if resource is Prompt:
		
			var prompt_data: Prompt = resource
			var item: PromptItem = prompt_item.instantiate()
			var has_audio = prompt_data.prompt_audio != null
			item.setup(prompt_data.id, prompt_data.prompt_text, has_audio, file)
			prompt_list.add_child(item)
			
			
		
		
	print(files)
