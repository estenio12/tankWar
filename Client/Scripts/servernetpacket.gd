extends Node

class_name ServerNetPacket

var _packet = {};

func _init(strPacket: String) -> void:
	_ParseStringPacket(strPacket);

func _ParseStringPacket(strPacket: String) -> void:
	var strPacketBlocks: PackedStringArray = strPacket.split('|');
	var net_code = int(strPacketBlocks[0]) as EGlobalEnums.NETCODE;

	# print("Parser: ", strPacket);

	match(net_code):
		EGlobalEnums.NETCODE.MOVIMENT:
			_packet = {"netcode": net_code, "position": str_to_var("Vector2"+strPacketBlocks[1]) as Vector2};
		EGlobalEnums.NETCODE.APPLY_MOVIMENT:
			_packet = {"netcode": net_code, "position": str_to_var("Vector2"+strPacketBlocks[1]) as Vector2};
		EGlobalEnums.NETCODE.RESET_MOVIMENT:
			_packet = {"netcode": net_code};
		EGlobalEnums.NETCODE.CHANGE_PLAYER:
			_packet = {"netcode": net_code, "current_player": int(strPacketBlocks[1]) as EGlobalEnums.PLAYER_TYPE, "state_p1": str(strPacketBlocks[2]), "state_p2": str(strPacketBlocks[3]) };
		EGlobalEnums.NETCODE.SELECTION:
			_packet = {"netcode": net_code};
		EGlobalEnums.NETCODE.ATTACK:
			_packet = {"netcode": net_code};
		EGlobalEnums.NETCODE.APPLY_ATTACK:
			_packet = {"netcode": net_code, "position": str_to_var("Vector2"+strPacketBlocks[1]) as Vector2, "angle": float(strPacketBlocks[2]), "power": int(strPacketBlocks[3])};
		EGlobalEnums.NETCODE.END_GAME:
			_packet = {"netcode": net_code, "player": strPacketBlocks[1]};
		EGlobalEnums.NETCODE.START_GAME:
			_packet = {"netcode": net_code, "player": strPacketBlocks[1]};
		EGlobalEnums.NETCODE.LOAD_GAME:
			_packet = {"netcode": net_code, "idmatch": int(strPacketBlocks[1]), "greenplayername": strPacketBlocks[2], "redplayername": strPacketBlocks[3], "my_tank": int(strPacketBlocks[4]) as EGlobalEnums.PLAYER_TYPE};
		EGlobalEnums.NETCODE.WAIT_MATCH:
			_packet = {"netcode": net_code};
		EGlobalEnums.NETCODE.READY:
			_packet = {"netcode": net_code};	
		EGlobalEnums.NETCODE.SPECTATOR_LIST:
			_packet = {"netcode": net_code, "matches": strPacketBlocks[1]};
		EGlobalEnums.NETCODE.SPECTATOR_ASSIGN:
			_packet = {"netcode": net_code, "idSpectator": int(strPacketBlocks[1]), "current_turn": int(strPacketBlocks[2]) as EGlobalEnums.PLAYER_TYPE, "timer": str(strPacketBlocks[3]), "p1": str(strPacketBlocks[4]), "p2": str(strPacketBlocks[5])};
		EGlobalEnums.NETCODE.SPECTATOR_EXIT:
			_packet = {"netcode": net_code};

func GetPacket() -> Dictionary:
	return _packet;
