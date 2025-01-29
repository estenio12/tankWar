extends Node

signal ReceiveDataFromServer(packet: String);

var current_player: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;

func ChangePlayer(player: EGlobalEnums.PLAYER_TYPE) -> void:
	current_player = player;

func GetCurrentPlayer() -> EGlobalEnums.PLAYER_TYPE:
	return current_player;

func SendToServer(packet: Dictionary) -> void:
	FakeServer(packet);

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
		EGlobalEnums.NETCODE.END_GAME:
			pack += str(EGlobalEnums.NETCODE.END_GAME) + "|";
			pack += str(packet["player"]);

	ReceiveDataFromServer.emit(pack);

#endregion
