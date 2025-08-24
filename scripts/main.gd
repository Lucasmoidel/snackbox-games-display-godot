extends Control
@onready var client: SocketIO = $SocketIO

@export_subgroup("Scenes")
@export var lobby: Control
@export var writing: Control

@export_subgroup("Lobby")
@export var create_game_button: Button
@export var start_game_button: Button
@export var room_code_label: Label

@export var lobby_things: Control

@export var player_list: Control

var players: Array[Player] = []
var client_connected: bool = false

var dir: DirAccess

enum GameState {
	INACTIVE,
	LOBBY,
	INSTRUCTION,
	WRITING,
	VOTING,
	LEADERBOARD,
}

var gameState: GameState = GameState.INACTIVE

var all_responses = {}
var waiting_for = []

var voting_round: int = 0

var prompt_one_votes: int = 0
var prompt_two_votes: int = 0

func _ready() -> void:
	player_list.set_points_to_use('lobby')
	dir = DirAccess.open('res://prompts')
	get_tree().set_auto_accept_quit(false)
	
	client.socket_connected.connect(_on_socket_connected)
	client.event_received.connect(_on_event_received)
	client.namespace_connection_error.connect(_on_namespace_connection_error)
	# Connect to /game with auth data
	client.connect_socket({"auth":"hamburgerandfries"})

func _on_socket_connected(ns: String) -> void:
	print("Connected to namespace: %s" % ns)
	client_connected = true
	create_game_button.show()

func handle_player_connect(data):
	var id = data["id"]
	var username = data["username"]
	
	var player_exists: bool = false
	
	for i in players:
		if i.id == id:
			i.name = username
			i.connected = true
			player_exists = true
			break
	if !player_exists:
		players.append(Player.new(username, id))
	player_list.add_player(username,id)

func handle_player_disconnect(data):
	var id = data["id"]
	
	for i in players:
		if i.id == id:
			i.connected = false
			print(i.name, "disconnected")
	player_list.remove_player(id)

func _on_event_received(event: String, data: Variant, ns: String) -> void:
	print("Event %s with %s as data received" % [event, data])
	print(data)
	data = data[0]
	if event == "created-room":
		room_started(data)
	if event == "player-joined":
		handle_player_connect(data)
	if event == "player-left":
		handle_player_disconnect(data)
	if event == "prompt-response":
		received_response(data)
	if event == "player-finished":
		player_finished(data.id)
	if event == "player-vote":
		pass

# Start the game
func _on_create_game_button_pressed():
	client.emit("create-room", { "gamemode": "wisecrack" }, "/game")

func room_started(data):
	var roomcode: String = data["roomcode"]
	
	room_code_label.set_text(roomcode)
	lobby_things.show()
	create_game_button.hide()
	
	gameState = GameState.LOBBY

# Receive a response to a prompt
func received_response(data):
	var response = data.response
	var prompt_id = data.prompt_id
	var player_id = data.id
	
	all_responses[prompt_id].responses.append({"id":player_id,"text":response})
	
	print(all_responses)

var retried: bool = false

func player_finished(id):
	waiting_for.erase(id)
	for each: Player in players:
		if each.id == id:
			player_list.add_player(each.name,id,false)
			break
	
	if len(waiting_for) == 0:
		print("ending start voting")
		start_voting()
		gameState = GameState.VOTING

func _on_namespace_connection_error(ns: String, data: Variant) -> void:
	print("Connection error for %s: %s" % [ns, data])

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await client.disconnect_socket()
		get_tree().quit() # default behavior
		
		
func kick_player(id: String, message: String):
	print("kick ", id, " because ", message)
	for i in range(len(players)):
		if players[i].id == id:
			players.pop_at(i)
			break
	client.emit("kick-player", { "id": id, "reason":  message}, "/game")
	

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
	player_list.clear_all()
	var prompts_to_vote_on = send_vote()


func _on_timer_timeout():
	gameState = GameState.VOTING
	print("Time up!")
	client.emit('times-up', {}, "/game")
	start_voting()


func _on_start_game_button_pressed():
	if gameState == GameState.LOBBY:
		lobby.hide()
		writing.show()
		player_list.clear_all()
		player_list.set_points_to_use('writing')
		pick_random_prompts()
		gameState = GameState.WRITING
