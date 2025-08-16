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
	if Time.get_ticks_msec() > 5000 and !client_connected:
		$Label2.hide()
		$Button.hide()
		$Button2.show()
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
			if i.name == data["username"]:
				i.connected = true
				player_exists = true
				break
		if !player_exists:
			players.append(Player.new(data["username"], data["id"]))
		$Label3.set_text("players:")
		for i in players:
			if i.connected:
				$Label3.set_text(str($Label3.text, " ", i.name))
	if event == "player-left":
		for i in players:
			if i.name == data["username"]:
				i.connected = false
		

func _on_namespace_connection_error(ns: String, data: Variant) -> void:
	print("Connection error for %s: %s" % [ns, data])
	$Label2.set_text("Connection error for %s: %s" % [ns, data])
	$Button.hide()
	$Label2.show()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await client.disconnect_socket()
		get_tree().quit() # default behavior



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
