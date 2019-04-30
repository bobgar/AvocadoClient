extends Node

const GamestateProto = preload("res://gamestate.gd")
onready var Ship = preload("res://client/ships/Forward.tscn")
onready var Bullet = preload("res://client/Bullet.tscn")

onready var Login = preload("res://Login/Login.tscn");
onready var JoinRoom = preload("res://JoinRoom/JoinRoom.tscn");
#onready var chooseShip = preload("res://ChooseShip/ChooseShip.tscn");

enum CLIENT_STATE{
  LOGIN,
  JOIN_ROOM,
  CHOOSE_SHIP,
  IN_GAME
}


export(PoolColorArray) var colors = PoolColorArray()

var _ships = {}
var _bullets = {}

var _client = WebSocketClient.new()
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var _use_multiplayer = false
var last_connected_client = 0
var _isConnected = false
var _deltaAccumulate = 0
var _curState = CLIENT_STATE.LOGIN;

var _loginScreen

func _init():
	_client.connect("connection_established", self, "_client_connected")
	_client.connect("connection_error", self, "_client_disconnected")
	_client.connect("connection_closed", self, "_client_disconnected")
	_client.connect("data_received", self, "_client_received")

	_client.connect("peer_packet", self, "_client_received")
	_client.connect("peer_connected", self, "_peer_connected")
	_client.connect("connection_succeeded", self, "_client_connected", ["multiplayer_protocol"])
	_client.connect("connection_failed", self, "_client_disconnected")
	
	#Dev
	#connect_to_url("ws://localhost:8000/ws", [])
	#Bobgar.com
	connect_to_url("ws://127.0.0.1:8000/ws", [])
	
func _ready():
	Utils._log("READY CALLED")
	_showLogin();

func _peer_connected(id):
	Utils._log("%s: Client just connected" % id)
	last_connected_client = id

func _exit_tree():
	_client.disconnect_from_host()

func _process(delta):
	#For now its good enough to return if not yet in the game state.
	if _curState != CLIENT_STATE.IN_GAME or _client.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED:
		return
		
	_client.poll()
	_deltaAccumulate += delta
	if _deltaAccumulate > .05:
		_deltaAccumulate = 0
		#Try to create a ship update
		var shipUpdate = GamestateProto.ShipUpdate.new()
		var sendUserUpdate = false;
		if Input.is_action_pressed("up"):
			shipUpdate.set_thrust(true)
			sendUserUpdate = true;
		if Input.is_action_pressed("left"):
			shipUpdate.set_rotLeft(true)
			sendUserUpdate = true;
		if Input.is_action_pressed("right"):
			shipUpdate.set_rotRight(true)
			sendUserUpdate = true;
		if Input.is_action_pressed("fire"):
			shipUpdate.set_fire(true)
			sendUserUpdate = true;
		
		if sendUserUpdate == true :
			_encodeAndSend(shipUpdate)

func _encodeAndSend(update):
	var b = update.to_bytes()
	var message = GamestateProto.GenericMessage.new()
	message.set_messageType(GamestateProto.GenericMessage.MessageTypeEnum.SHIP_UPDATE)
	message.set_data(b)
	var messageBytes = message.to_bytes()
	
	send_data(messageBytes)
	
	
func send_data(data):
	#_client.get_peer(1).set_write_mode(_write_mode)	
	_client.get_peer(1).put_packet(Utils.encode_data(data, _write_mode))

func _client_connected(protocol):
	Utils._log("Client just connected with protocol: %s" % protocol)
	_client.get_peer(1).set_write_mode(_write_mode)
	_isConnected = true;
	
func _showLogin():
	_loginScreen = Login.instance();
	get_tree().get_root().call_deferred("add_child", _loginScreen);
	#get_tree().get_root().add_child(_loginScreen);

func _client_disconnected():
	Utils._log("Client just disconnected")
	_isConnected = false;

func _client_received(p_id = 1):
	
	var packet = _client.get_peer(1).get_packet()
	
	var message = GamestateProto.GenericMessage.new()
	var result_code = message.from_bytes(packet)	
	
	if result_code == 0:
		match message.get_messageType():			
			GamestateProto.GenericMessage.MessageTypeEnum.GAME_STATE_UPDATE:
				var keys = _ships.keys()
				var bulletKeys = _bullets.keys()
				var gs = GamestateProto.GameState.new()
				result_code = gs.from_bytes(packet)
				var ships = gs.get_ships();
				for ship in ships:
					var id = ship.get_id()
					if !_ships.has(id):
						spawnShip(id)
					else:
						keys.erase(id)
					var shipGameObj = _ships[id]
					shipGameObj.position.x = ship.get_xPos()
					shipGameObj.position.y = ship.get_yPos()
					shipGameObj.rotation = ship.get_rot()
					spawnOrUpdateBullets(id, ship, bulletKeys)
				
				for k in keys:
					_ships[k].get_parent().remove_child(_ships[k])
					_ships.erase(k)
				for k in bulletKeys:
					_bullets[k].get_parent().remove_child(_bullets[k])
					_bullets.erase(k)


func spawnOrUpdateBullets(shipId, ship, bulletKeys):
	for bullet in ship.get_bullets():
		var bulletId = bullet.get_id()
		if !_bullets.has(bulletId):
			spawnBullet(shipId, bulletId)
		else:
			bulletKeys.erase(bulletId)
		var bulletObj = _bullets[bulletId]
		bulletObj.position.x = bullet.get_xPos()
		bulletObj.position.y = bullet.get_yPos()

func spawnShip(id):
	_ships[id] = Ship.instance()
	_ships[id].get_child(0).color = colors[id % colors.size()]	
	get_tree().get_root().add_child(_ships[id])
	
func spawnBullet(shipId, bulletId):
	_bullets[bulletId] = Bullet.instance()
	_bullets[bulletId].get_child(0).color = colors[shipId % colors.size()]	
	get_tree().get_root().add_child(_bullets[bulletId])

func connect_to_url(host, protocols):
	return _client.connect_to_url(host, protocols)

func disconnect_from_host():
	_client.disconnect_from_host()