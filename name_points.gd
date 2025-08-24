extends Control

@export var sceneRoot: Control

@export var player_points: Array[Node2D]
@export var names: Control

var players = []

func add_player(pname,id):
	players.append({"name":pname,"id":id})
	var new_name = load("res://scenes/player_name.tscn").instantiate()
	new_name.position = player_points[len(players)-1].position
	new_name.text = pname
	new_name.scale = Vector2(0,0)
	new_name.name = id
	new_name.id = id
	new_name.pressed.connect(Callable(self,"kick_player").bind(id))
	names.add_child(new_name)

func kick_player(id):
	remove_player(id)
	sceneRoot.kick_player(id, "You have been kicked by the room host")

func remove_player(id):
	var foundPlayer = false
	for each in players:
		if each.id == id:
			players.erase(each)
			names.get_node(id).queue_free()
			foundPlayer = true
			break
	if !foundPlayer:
		return
	await get_tree().process_frame
	var count = 0
	for each in names.get_children():
		print(each.name)
		var tween = get_tree().create_tween()
		tween.tween_property(each, "position", player_points[count].position, 0.5).set_trans(Tween.TRANS_SINE)
		count += 1
