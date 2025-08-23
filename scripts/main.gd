extends Control
@onready var client: SocketIO = $SocketIO

var players: Array[Player] = []
var client_connected: bool = false

var dir: DirAccess

enum GameState {
	INACTIVE,
	LOBBY,
	WRITING,
	VOTING,
	LEADERBOARD,
}

var gameState: GameState = GameState.INACTIVE

var all_responses = {}
var waiting_for = []

var voting_round: int = 0

func _ready() -> void:
	dir = DirAccess.open('res://prompts')
	get_tree().set_auto_accept_quit(false)
	
	client.socket_connected.connect(_on_socket_connected)
	client.event_received.connect(_on_event_received)
	client.namespace_connection_error.connect(_on_namespace_connection_error)
	# Connect to /game with auth data
	client.connect_socket({"auth":"hamburgerandfries"})
	$AnimationPlayer.play("connecting")

func _process(delta: float):
	if !client_connected and Time.get_ticks_msec() > int(Time.get_ticks_msec()) % 2500:
		if retried:
			$Label2.hide()
			$Button.hide()
			$Button2.show()
		if not retried:
			retried = true
			print('hfiehifihfwihfih')
			client.base_url = 'http://localhost:4009'
			client.connect_socket({"auth":"hamburgerandfries"})
			
func _on_socket_connected(ns: String) -> void:
	print("Connected to namespace: %s" % ns)
	client_connected = true
	$AnimationPlayer.stop()
	$Label2.hide()
	$Button.show()
	$Button2.hide()


func _on_event_received(event: String, data: Variant, ns: String) -> void:
	print("Event %s with %s as data received" % [event, data])
	print(data)
	data = data[0]
	if event == "created-room":
		$Button.hide()
		$Label2.set_text(str("room code: ", data["roomcode"]))
		$Label2.show()
		$Button2.hide()
		gameState = GameState.LOBBY
	if event == "player-joined":
		var player_exists: bool = false
		for i in players:
			if i.id == data["id"]:
				i.name = data["username"]
				i.connected = true
				player_exists = true
				break
		if !player_exists:
			players.append(Player.new(data["username"], data["id"]))
		update_user_list()
	if event == "player-left":
		for i in players:
			if i.id == data["id"]:
				i.connected = false
				print(i.name, "disconnected")
		update_user_list()
	if event == "prompt-response":
		received_response(data)
	if event == "player-finished":
		player_finished(data.id)
	if event == "player-vote":
		pass

func received_response(data):
	var response = data.response
	var prompt_id = data.prompt_id
	var player_id = data.id
	
	all_responses[prompt_id].responses.append({"id":player_id,"text":response})
	
	print(all_responses)

var retried: bool = false

func player_finished(id):
	waiting_for.erase(id)
	
	if len(waiting_for) == 0:
		print("ending start voting")
		start_voting()
		gameState = GameState.VOTING

func _on_namespace_connection_error(ns: String, data: Variant) -> void:
	print("Connection error for %s: %s" % [ns, data])
	$Label2.set_text("Connection error for %s: %s" % [ns, data])
	$Button.hide()
	$Label2.show()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await client.disconnect_socket()
		get_tree().quit() # default behavior

func update_user_list():
	for i in $HBoxContainer.get_children():
		i.queue_free()
	for i in players:
		var button = Button.new()
		button.set_text(i.name)
		button.theme = load("res://button_theme.tres")
		button.pressed.connect(kick_player.bind(i.id, "idk ;]"))
		$HBoxContainer.add_child(button)
		
		
func kick_player(id: String, message: String):
	print("kick ", id, " because ", message)
	for i in range(len(players)):
		if players[i].id == id:
			players.pop_at(i)
			break
	update_user_list()
	client.emit("kick-player", { "id": id, "reason":  message}, "/game")
	



func _on_create_session_down() -> void:
	client.emit("create-room", { "gamemode": "wisecrack" }, "/game")

class Player:
	var score: int = 0
	var name: String = ""
	var id: String = ""
	var connected: bool = true
	var answer: String = ""
	func _init(character_name: String, character_id: String):
		self.name = character_name
		self.id = character_id

func _on_reconnect_pressed() -> void:
	client.connect_socket({"auth":"hamburgerandfries"})

# [{"prompt":"A disgusting name for a dog.", "id":1},{"prompt":"What you don't want to find in your bedroom closet.", "id":2}]

func get_active_players():
	var active_players: Array[Player]
	for each:Player in players:
		if each.connected:
			active_players.append(each)
	return active_players

func pick_random_prompts():
	#responses = {}
	var options = dir.get_files()
	
	print(options)
	
	var final_data = []
	
	for x in get_active_players():
		var prompt_num: int = randi_range(0, options.size() - 1)
		var picked_prompt : Prompt = load("res://prompts/"+options[prompt_num])
		options.remove_at(prompt_num)
		print("PROMPT ID",picked_prompt.id)
		all_responses[picked_prompt.id] = { "prompt":picked_prompt.prompt_text, "audio":picked_prompt.prompt_audio, "responses":[] }
		final_data.append({"prompt":picked_prompt.prompt_text, "id":picked_prompt.id})
	
	var active_player_ids: Array
	
	for x:Player in get_active_players():
		active_player_ids.append(x.id)
		waiting_for.append(x.id)
	
	client.emit('send-prompts', {"prompts":final_data,"players":active_player_ids}, '/game')
	
	$Timer.start()
	
	print(all_responses)

func send_vote():
	waiting_for = []
	
	var keys = all_responses.keys()
	
	var data = all_responses[keys[voting_round]]
	
	var responses = []
	
	var authors = []
	
	print("Voting on "+data.prompt)
	print(data.responses)
	
	for each in data.responses:
		authors.append(each.id)
		responses.append(each.text)
	
	var voters = []
	
	for x:Player in get_active_players():
		if x.id not in authors:
			voters.append(x.id)
			waiting_for.append(x.id)
			
	#print(responses)
	#print(authors)
	#print(voters)
			
	client.emit('send-vote', {"responses":responses, "authors":authors, "voters":voters}, "/game")

func start_voting():
	send_vote()
	
	

func _start_game_down() -> void:
	if gameState == GameState.LOBBY:
		gameState = GameState.WRITING
		pick_random_prompts()


func _on_timer_timeout():
	gameState = GameState.VOTING
	print("Time up!")
	client.emit('times-up', {}, "/game")
	start_voting()
