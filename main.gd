extends Control
@onready var client: SocketIO = $SocketIO

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	client.socket_connected.connect(_on_socket_connected)
	client.event_received.connect(_on_event_received)
	client.namespace_connection_error.connect(_on_namespace_connection_error)
	# Connect to /game with auth data
	client.connect_socket({"auth":"hamburgerandfries"})

func _on_socket_connected(ns: String) -> void:
	print("Connected to namespace: %s" % ns)
	client.emit("create-room", { "gamemode": "wisecrack" }, "/game")

func _on_event_received(event: String, data: Variant, ns: String) -> void:
	print("Event %s with %s as data received" % [event, data])

func _on_namespace_connection_error(ns: String, data: Variant) -> void:
	print("Connection error for %s: %s" % [ns, data])

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await client.disconnect_socket()
		get_tree().quit() # default behavior
