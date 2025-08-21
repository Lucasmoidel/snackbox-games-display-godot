extends Control
@onready var client: SocketIO = $SocketIO

var players: Array[Player] = []
var client_connected: bool = false
func _ready() -> void:
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

var retried: bool = false

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


func _start_game_down() -> void:
	pass # Replace with function body.
