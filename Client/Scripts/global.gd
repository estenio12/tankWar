extends Node

signal ReceiveDataFromServer(packet: Dictionary);

@onready var battle_scene = preload("res://Maps/Arena.tscn");
@onready var lobby_scene: PackedScene = preload("res://UI/lobby.tscn");

var last_name_picked: String = "unnamed";

var current_player: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
var my_tank: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
var nicknames: Array[String] = ["GreenPlayer", "RedPlayer"]
var id_match: int = 0;

var id_spectator: int = 0;
var timer_spectator_minute: int = 0;
var timer_spectator_second: int = 0;
var spectator_players_states: Array[Dictionary];

# Dados de conexão

var ServerIP: String = "192.168.15.8";
var ServerPORT: int = 8080;

var socket: WebSocketPeer;

func _ready() -> void:
	#var url = JavaScript.eval("window.location.href")  # Obtém a URL completa
	var hostname = JavaScriptBridge.eval("window.location.hostname");  # Obtém o domínio/IP
	var port = JavaScriptBridge.eval("window.location.port");  # Obtém a porta
	ServerIP = hostname;
	ServerPORT = port;

func _process(_delta: float) -> void:
	if(socket != null):
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
	CreateConnection();

func RetryConnection() -> void:
	CreateConnection();

func CreateConnection() -> void:
	socket = WebSocketPeer.new();
	socket.connect_to_url(BuildURL());

func BuildURL() -> String:
	return "wss://%s:%d" % [ServerIP, ServerPORT];

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

func IsSpectator() -> bool:
	return my_tank == EGlobalEnums.PLAYER_TYPE.SPECTATOR;

func SendToServer(packet: Dictionary) -> void:
	if(socket == null || socket.get_ready_state() != WebSocketPeer.STATE_OPEN):
		CreateConnection();
	
	var package = ConvertToServerPackege(packet);
	if(IsValidPackage(package) && IsValidRequestSpectator(packet)):
		socket.send_text(package);

func ConvertToServerPackege(packet: Dictionary) -> String:
	var pack: String = "";

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
			pack += str(EGlobalEnums.NETCODE.CHANGE_PLAYER) + "|";
			pack += str(packet["current_player"]) + "|";
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
		EGlobalEnums.NETCODE.SPECTATOR_LIST:
			pack += str(EGlobalEnums.NETCODE.SPECTATOR_LIST);
		EGlobalEnums.NETCODE.SPECTATOR_ASSIGN:
			pack += str(EGlobalEnums.NETCODE.SPECTATOR_ASSIGN) + "|";
			pack += str(packet["idmatch"]);

	return pack + "|" + str(id_match);

func IsValidPackage(package: String) -> bool:
	# if(socket.get_ready_state() == WebSocketPeer.STATE_OPEN):
	if(package.length() > 0 && package[0] != '|'):
		return true;

	return false;

func IsValidRequestSpectator(packet: Dictionary) -> bool:
	var netcode = packet["netcode"] as EGlobalEnums.NETCODE;
	if(my_tank != EGlobalEnums.PLAYER_TYPE.SPECTATOR):
		return true;
	
	if(my_tank == EGlobalEnums.PLAYER_TYPE.SPECTATOR && \
	   (netcode == EGlobalEnums.NETCODE.SPECTATOR_LIST || \
		netcode == EGlobalEnums.NETCODE.SPECTATOR_ASSIGN || \
		netcode == EGlobalEnums.NETCODE.SPECTATOR_EXIT) ):
		return true;
		
	return false;
