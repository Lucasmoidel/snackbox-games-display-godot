extends Control

@export var prompt_label: Label
@export var response_one: Label
@export var response_two: Label

@export var response_one_result: Label
@export var response_two_result: Label

func set_values(prompt,responses):
	response_one_result.hide()
	response_two_result.hide()
	
	prompt_label.set_text(prompt)
	response_one.set_text(responses[0])
	response_two.set_text(responses[1])

func show_results(number_one,number_two):
	response_one_result.show()
	response_two_result.show()
	
	var percentage = int(number_one/(number_one+number_two)*100)
	
	response_one_result.set_text(str(percentage)+"%")
	response_two_result.set_text(str(100-percentage)+"%")
