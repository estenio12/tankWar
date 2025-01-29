extends Camera2D

@export var ref_green_player: Player;
@export var ref_red_player: Player;

var player: Array[Player] = [];

func _ready() -> void:
	# Cria uma lista com os dois jogadores, que será acessada usando seus respectivos índices 
	# na enum EGlobalEnums.EPLAYER_TYPE.
	# GreenPlayer = índice 0
	# RedPlayer   = índice 1
	player.append(ref_green_player);
	player.append(ref_red_player);

func _process(_delta: float) -> void:
	var current_player: Player = player[Global.GetCurrentPlayer()];

	if(current_player):
		position = current_player.global_position;
