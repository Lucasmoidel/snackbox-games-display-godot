extends Control

@export var player_points: Array[Node2D]

var players = []

func add_player(pname,id):
	players.append({"name":pname,"id":id})
