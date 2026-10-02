extends Node

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
const PORT: int = 7000
const MAX_PLAYERS: int = 5
const SPAWN_X_OFFSETS := [0.0, 0.7, -0.7, 1.4, -1.4]

@onready var players: Node3D = $Players
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var movement_camera: Camera3D = $"../CameraRig/Camera3D"
@onready var address_field: LineEdit = $DebugUI/PanelContainer/VBoxContainer/Address
@onready var host_button: Button = $DebugUI/PanelContainer/VBoxContainer/Buttons/HostButton
@onready var join_button: Button = $DebugUI/PanelContainer/VBoxContainer/Buttons/JoinButton
@onready var status_label: Label = $DebugUI/PanelContainer/VBoxContainer/Status

var slots_by_peer: Dictionary = {}
var session_active: bool = false


func _ready() -> void:
	spawner.spawn_function = _create_network_player
	host_button.pressed.connect(_host)
	join_button.pressed.connect(_join)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_PLAYERS - 1)
	if error != OK:
		status_label.text = "Host failed (error %s)" % error
		return

	_remove_offline_player()
	multiplayer.multiplayer_peer = peer
	_set_carryables_networked(true, true)
	session_active = true
	_set_controls_enabled(false)
	_spawn_player(1)
	_update_host_status()


func _join() -> void:
	var address: String = address_field.text.strip_edges()
	if address.is_empty():
		status_label.text = "Enter a host IP address."
		return

	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, PORT)
	if error != OK:
		status_label.text = "Join failed (error %s)" % error
		return

	_remove_offline_player()
	multiplayer.multiplayer_peer = peer
	_set_carryables_networked(true, false)
	session_active = true
	_set_controls_enabled(false)
	status_label.text = "Connecting to %s:%d..." % [address, PORT]


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server() or slots_by_peer.has(peer_id):
		return
	_spawn_player(peer_id)
	_update_host_status()


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	_drop_objects_held_by(peer_id)
	slots_by_peer.erase(peer_id)
	var player: Node = players.get_node_or_null(str(peer_id))
	if player != null:
		player.queue_free()
	_update_host_status()


func _on_connected_to_server() -> void:
	status_label.text = "Connected as peer %d" % multiplayer.get_unique_id()


func _on_connection_failed() -> void:
	_restore_offline_player("Connection failed. Offline solo.")


func _on_server_disconnected() -> void:
	_restore_offline_player("Host disconnected. Offline solo.")


func _spawn_player(peer_id: int) -> void:
	var slot: int = _first_open_slot()
	if slot == -1:
		push_error("The multiplayer test is limited to five players.")
		return

	slots_by_peer[peer_id] = slot
	var player: Node = spawner.spawn({"peer_id": peer_id, "slot": slot})
	if player == null:
		slots_by_peer.erase(peer_id)
		push_error("Could not spawn a network player for peer %d." % peer_id)


func _first_open_slot() -> int:
	for slot in range(MAX_PLAYERS):
		if not slots_by_peer.values().has(slot):
			return slot
	return -1


func _create_network_player(data: Variant) -> Node:
	var peer_id: int = int(data["peer_id"])
	var slot: int = int(data["slot"])
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = str(peer_id)
	player.position = Vector3(float(SPAWN_X_OFFSETS[slot]), 0.0, 0.0)
	player.set("movement_camera", movement_camera)
	player.set_multiplayer_authority(peer_id, true)
	return player


func _remove_offline_player() -> void:
	var offline_player: Node = get_parent().get_node_or_null("Player")
	if offline_player == null:
		return

	_drop_objects_held_by(1)
	offline_player.free()


func _restore_offline_player(message: String) -> void:
	if not session_active:
		return

	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_carryables_networked(false)
	for player in players.get_children():
		player.free()
	slots_by_peer.clear()
	session_active = false

	var offline_player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	offline_player.name = "Player"
	offline_player.set("movement_camera", movement_camera)
	get_parent().add_child(offline_player)
	_set_controls_enabled(true)
	status_label.text = message


func _drop_objects_held_by(peer_id: int) -> void:
	for node in get_tree().get_nodes_in_group("carryables"):
		var object: CarryableObject = node as CarryableObject
		if object != null and object.holder_peer_id == peer_id:
			object.drop()


func _set_carryables_networked(active: bool, server_simulates_physics: bool = true) -> void:
	for node in get_tree().get_nodes_in_group("carryables"):
		var object: CarryableObject = node as CarryableObject
		if object == null:
			continue
		if active:
			object.begin_network_session(players, server_simulates_physics)
		else:
			object.end_network_session()


func _set_controls_enabled(enabled: bool) -> void:
	host_button.disabled = not enabled
	join_button.disabled = not enabled
	address_field.editable = enabled
	host_button.release_focus()
	join_button.release_focus()
	address_field.release_focus()


func _update_host_status() -> void:
	status_label.text = "Hosting %d/%d on UDP %d" % [
		slots_by_peer.size(), MAX_PLAYERS, PORT
	]
