extends Control

var client = SocketIOClient
var backendURL: String

func _ready():
	backendURL = "http://games-server:4009/socket.io"
	client = SocketIOClient.new(backendURL, {"token": "hamburgerandfries"})
	client.on_engine_connected.connect(on_socket_ready)
	client.on_connect.connect(on_socket_connect)
	client.on_event.connect(on_socket_event)
	add_child(client)

func _exit_tree():
	client.socketio_disconnect()

func on_socket_ready(_sid: String):
	client.socketio_connect()

func on_socket_connect(_payload: Variant, _name_space, error: bool):
	if error:
		push_error("Failed to connect to backend!")
	else:
		print("Socket connected")
		client.socketio_send("create-room", "wisecrack", "/game");

func on_socket_event(event_name: String, payload: Variant, _name_space):
	print (event_name, payload)
	#if event_name == "create-room":
		#print(payload)
