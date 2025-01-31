extends Camera2D

@export var ref_green_player: Player;
@export var ref_red_player: Player;
@export var ref_bullet: Area2D;

var player: Array[Player] = [];
var inBulletTarget: bool = false; 

func _ready() -> void:
	# Cria uma lista com os dois jogadores, que será acessada usando seus respectivos índices 
	# na enum EGlobalEnums.EPLAYER_TYPE.
	# GreenPlayer = índice 0
	# RedPlayer   = índice 1
	player.append(ref_green_player);
	player.append(ref_red_player);

func _process(_delta: float) -> void:
	if(!inBulletTarget):
		var current_player: Player = player[Global.GetCurrentPlayer()];

		if(current_player):
			position = current_player.global_position;
	else:
		if(ref_bullet):
			position = ref_bullet.global_position;

func EnableTargetInBullet(flag: bool) -> void:
	inBulletTarget = flag;