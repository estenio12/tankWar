extends Node

class_name ClientNetPacket

var net_code: EGlobalEnums.NETCODE = EGlobalEnums.NETCODE.SELECTION;
var player_position: Vector2 = Vector2.ZERO;
var HP: float = 100;
var actions: int = 2;
var powerup_acquired: EGlobalEnums.POWERUP = EGlobalEnums.POWERUP.NONE;
