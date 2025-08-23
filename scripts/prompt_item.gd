class_name PromptItem
extends Control

var id: String
var prompt_text: String
var has_audio_file: bool
var path: String

func setup(_id, _prompt_text,_has_audio_file, _path):
	id = _id
	prompt_text = _prompt_text
	has_audio_file = _has_audio_file
	path = _path

func _ready():
	$Background/PromptText.set_text(prompt_text)
