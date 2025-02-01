extends Node

class_name ServerNetPacket

var _packet = {};

func _init(strPacket: String) -> void:
	_ParseStringPacket(strPacket);

func _ParseStringPacket(strPacket: String) -> void:
	var strPacketBlocks: PackedStringArray = strPacket.split('|');
	var net_code = int(strPacketBlocks[0]) as EGlobalEnums.NETCODE;

	print("Parser: ", strPacket);

	match(net_code):
		EGlobalEnums.NETCODE.MOVIMENT:
			_packet = {"netcode": net_code, "position": str_to_var("Vector2"+strPacketBlocks[1]) as Vector2};
		EGlobalEnums.NETCODE.APPLY_MOVIMENT:
			_packet = {"netcode": net_code, "position": str_to_var("Vector2"+strPacketBlocks[1]) as Vector2};
		EGlobalEnums.NETCODE.RESET_MOVIMENT:
			_packet = {"netcode": net_code};
		EGlobalEnums.NETCODE.CHANGE_PLAYER:
			_packet = {"netcode": net_code, "player": int(strPacketBlocks[1]) as EGlobalEnums.PLAYER_TYPE};
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
			_packet = {"netcode": net_code, "greenplayername": strPacketBlocks[1], "redplayername": strPacketBlocks[2], "my_tank": int(strPacketBlocks[3]) as EGlobalEnums.PLAYER_TYPE};
		EGlobalEnums.NETCODE.POWERUP:
			_packet = {"netcode": net_code, "powerup": strPacketBlocks[1]};

func GetPacket() -> Dictionary:
	return _packet;
