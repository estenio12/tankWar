extends Node

signal ReceiveDataFromServer(packet: String);

var current_player: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;

func ChangePlayer(player: EGlobalEnums.PLAYER_TYPE) -> void:
	current_player = player;

func GetCurrentPlayer() -> EGlobalEnums.PLAYER_TYPE:
	return current_player;

func SendToServer(packet: Dictionary) -> void:
	FakeServer(packet);

func ConvertTransform2D_to_String(target: Transform2D) -> String:
	var vec_x = target.x;
	var vec_y = target.y;
	var vec_o = target.origin;
	return str(vec_x) + "#" + str(vec_y) + "#" + str(vec_o);

func ConvertString_to_Transform2D(target: String) -> Transform2D:
	var chunks = target.split("#");
	var vec_x = str_to_var("Vector2"+chunks[0]);
	var vec_y = str_to_var("Vector2"+chunks[1]);
	var vec_o = str_to_var("Vector2"+chunks[2]);
	return Transform2D(vec_x, vec_y, vec_o); 

#region FAKE SERVER

func FakeServer(packet: Dictionary) -> void:
	var pack: String = "";

	# print("Debug Packet: ", packet);

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
			pack += str(playerID);
		EGlobalEnums.NETCODE.ATTACK:
			pack += str(EGlobalEnums.NETCODE.ATTACK);
		EGlobalEnums.NETCODE.APPLY_ATTACK:
			pack += str(EGlobalEnums.NETCODE.APPLY_ATTACK) + "|";
			pack += str(packet["position"]) + "|";
			pack += str(packet["angle"]) + "|";
			pack += str(packet["power"]);

	ReceiveDataFromServer.emit(pack);

#endregion
