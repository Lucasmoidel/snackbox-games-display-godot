class_name PromptItem
extends Panel

var id: String
var prompt_text: String
var has_audio_file: bool
var path: String

func setup(_id, _prompt_text,_has_audio_file, _path):
	id = _id
	prompt_text = _prompt_text
	has_audio_file = _has_audio_file
	path = _path
	
	if has_audio_file:
		$HasAudioLabel.set_text("HAS AUDIO")

func _ready():
	$PromptText.set_text(prompt_text)
