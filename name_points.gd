extends Control

@export var sceneRoot: Control

@export var player_points: Array[Node2D]
@export var writing_points: Array[Node2D]
#@export var name_points: Control

var using_points: Array[Node2D]

var players = []

func add_player(pname,id, kickable=true):
	players.append({"name":pname,"id":id})
	var new_name = load("res://scenes/player_name.tscn").instantiate()
	new_name.global_position = using_points[len(players)-1].global_position
	new_name.text = pname
	new_name.scale = Vector2(0,0)
	new_name.name = id
	new_name.id = id
	if kickable:
		new_name.pressed.connect(Callable(self,"kick_player").bind(id))
	add_child(new_name)

func set_points_to_use(vartouse:String):
	if vartouse == "lobby":
		using_points = player_points
	elif vartouse == "writing":
		using_points = writing_points

func kick_player(id):
	remove_player(id)
	sceneRoot.kick_player(id, "You have been kicked by the room host")

func remove_player(id):
	var foundPlayer = false
	for each in players:
		if each.id == id:
			players.erase(each)
			get_node(id).reparent(sceneRoot)
			sceneRoot.get_node(id).remove()
			foundPlayer = true
			break
	if !foundPlayer:
		return
	await get_tree().process_frame
	var count = 0
	for each in self.get_children():
		print(each.name)
		each.move_to(player_points[count].global_position, 0.5, 0.5)
		count += 1

func clear_all():
	players = []
	for each in self.get_children():
		each.reparent(sceneRoot)
		each.remove()
