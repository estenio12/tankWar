extends Node

signal ReceiveDataFromServer(packet: Dictionary);

@onready var battle_scene = preload("res://Maps/Arena.tscn");
@onready var lobby_scene: PackedScene = preload("res://UI/lobby.tscn");

var last_name_picked: String = "unnamed";

var current_player: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
var my_tank: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
var nicknames: Array[String] = ["GreenPlayer", "RedPlayer"]
var id_match: int = 0;

# Dados de conexão

var ServerIP: String = "192.168.15.8";
var ServerPORT: int = 7080;

var socket = WebSocketPeer.new()

func _ready() -> void:
	CreateConnection();

func _process(_delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var strPacket = socket.get_packet().get_string_from_utf8();
			ReceiveDataFromServer.emit(ServerNetPacket.new(strPacket).GetPacket());
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func UpdateConection(pIP: String, pPORT: int) -> void:
	ServerIP   = pIP;
	ServerPORT = pPORT
	socket.close();
	CreateConnection();

func RetryConnection() -> void:
	CreateConnection();

func CreateConnection() -> void:
	socket.connect_to_url(BuildURL());

func BuildURL() -> String:
	return "ws://%s:%d" % [ServerIP, ServerPORT];

func LoadPlayers(pid_match: int, p1_nickname: String, p2_nickname: String, pmy_tank: EGlobalEnums.PLAYER_TYPE) -> void:
	id_match  = pid_match;
	my_tank   = pmy_tank;
	nicknames = [p1_nickname, p2_nickname];

func ChangePlayer(player: EGlobalEnums.PLAYER_TYPE) -> void:
	current_player = player;

func GetCurrentPlayer() -> EGlobalEnums.PLAYER_TYPE:
	return current_player;

func IsMyTank() -> bool:
	return my_tank == current_player;

func SendToServer(packet: Dictionary) -> void:
	var package = ConvertToServerPackege(packet);
	if(IsValidPackage(package)):
		socket.send_text(package);

func ConvertToServerPackege(packet: Dictionary) -> String:
	var pack: String = "";
	
	#print("Debug pack: ", packet);

	match(packet["netcode"] as EGlobalEnums.NETCODE):
		EGlobalEnums.NETCODE.MOVIMENT:
			pack += str(EGlobalEnums.NETCODE.MOVIMENT) + "|";
			pack += str(packet["position"]);
		EGlobalEnums.NETCODE.APPLY_MOVIMENT:
			pack += str(EGlobalEnums.NETCODE.APPLY_MOVIMENT) + "|";
			pack += str(packet["position"]);
		EGlobalEnums.NETCODE.RESET_MOVIMENT:
			pack += str(EGlobalEnums.NETCODE.RESET_MOVIMENT);
		EGlobalEnums.NETCODE.CHANGE_PLAYER:
			var playerID = packet["current_player"];
			
			if(playerID == 0):
				playerID = 1;
			else:
				playerID = 0;

			pack += str(EGlobalEnums.NETCODE.CHANGE_PLAYER) + "|";
			pack += str(playerID) + "|";
			pack += str(packet["state_p1"]) + "|";
			pack += str(packet["state_p2"]);
		EGlobalEnums.NETCODE.ATTACK:
			pack += str(EGlobalEnums.NETCODE.ATTACK);
		EGlobalEnums.NETCODE.APPLY_ATTACK:
			pack += str(EGlobalEnums.NETCODE.APPLY_ATTACK) + "|";
			pack += str(packet["position"]) + "|";
			pack += str(packet["angle"]) + "|";
			pack += str(packet["power"]);
		EGlobalEnums.NETCODE.END_GAME:
			pack += str(EGlobalEnums.NETCODE.END_GAME) + "|";
			pack += str(packet["player"]);
		EGlobalEnums.NETCODE.START_GAME:
			pack += str(EGlobalEnums.NETCODE.START_GAME) + "|";
			pack += str(packet["player"]);
		EGlobalEnums.NETCODE.LOAD_GAME:
			pack += str(EGlobalEnums.NETCODE.LOAD_GAME) + "|";
			pack += str(packet["greenplayername"]) + "|";
			pack += str(packet["redplayername"]) + "|";
			pack += str(packet["my_tank"]);
		EGlobalEnums.NETCODE.REGISTER:
			pack += str(EGlobalEnums.NETCODE.REGISTER) + "|";
			pack += str(packet["nickname"]);
		EGlobalEnums.NETCODE.READY:
			pack += str(EGlobalEnums.NETCODE.READY) + "|";
			pack += str(packet["PID"]);

	return pack + "|" + str(id_match);

func IsValidPackage(package: String) -> bool:
	if(socket.get_ready_state() == WebSocketPeer.STATE_OPEN):
		if(package.length() > 0 && package[0] != '|'):
			return true;

	return false;
