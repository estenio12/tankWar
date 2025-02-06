extends CharacterBody2D

class_name Player

signal PlayerDead(player_type: EGlobalEnums.PLAYER_TYPE);

@onready var ref_green_tank: Node2D = $GreenTank;
@onready var ref_red_tank: Node2D   = $RedTank;
@onready var ref_green_tank_cannon  = $GreenTank/Cannon;
@onready var ref_red_tank_cannon  	= $RedTank/Cannon;
@onready var ref_green_tank_hp_bar  = $GreenHPBarContainer/GreenPlayer/bar;
@onready var ref_green_tank_hp_value  = $GreenHPBarContainer/GreenPlayer/value;
@onready var ref_red_tank_hp_bar 	  = $RedHPBarContainer/RedPlayer/bar;
@onready var ref_red_tank_hp_value 	  = $RedHPBarContainer/RedPlayer/value;
@onready var ref_green_tank_hp_container = $GreenHPBarContainer;
@onready var ref_red_tank_hp_container   = $RedHPBarContainer;

@onready var ref_spawn_bullet_green_player = $GreenTank/Cannon/SpawnBullet;
@onready var ref_spawn_bullet_red_player = $RedTank/Cannon/SpawnBullet;
@onready var ref_hurt_box = $HurtBox;

@export var player_type: EGlobalEnums.PLAYER_TYPE = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;

var start_position: Vector2 = Vector2.ZERO;
var recording_last_postion: bool = false;
var player_name: String = "unnamed";
const MAX_HP: float = 5;
var currentHP: float = MAX_HP;

# Variável de rotação dos canhões.
const GREEN_PLAYER_MAX_ANGLE: float 	= -90.0;
const RED_PLAYER_MAX_ANGLE: float 		= 90.0;
const CANNON_ROTATION_SPEED: float 		= 1.5;
var green_player_current_direction: int = -1;
var red_player_current_direction: int 	= 1;
var select_angle_active: bool 			= false;

func _ready() -> void:
	ref_hurt_box.player_type = player_type;
	# Mostra sprite de acordo com o player_type.
	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		LoadGreenPlayer();
	else:
		LoadRedPlayer();

	# Armazena a última posição do jogador.
	start_position = self.global_position;

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta;

	# Sistema angulação dos canhões.
	if(select_angle_active):
		if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
			GreenPlayerCannonRotation(delta);
		else:
			RedPlayerCannonRotation(delta);

	move_and_slide()

func GreenPlayerCannonRotation(delta: float) -> void:
	if(ref_green_tank_cannon.rotation_degrees <= GREEN_PLAYER_MAX_ANGLE):
		green_player_current_direction = 1;
	elif(ref_green_tank_cannon.rotation_degrees >= 0):
		green_player_current_direction = -1;

	# Aplica a rotação
	ref_green_tank_cannon.rotate(CANNON_ROTATION_SPEED * green_player_current_direction * delta)

func RedPlayerCannonRotation(delta: float) -> void:
	if(ref_red_tank_cannon.rotation_degrees >= RED_PLAYER_MAX_ANGLE):
		red_player_current_direction = -1;
	elif(ref_red_tank_cannon.rotation_degrees <= 0):
		red_player_current_direction = 1;

	# Aplica a rotação
	ref_red_tank_cannon.rotate(CANNON_ROTATION_SPEED * red_player_current_direction * delta)

func LoadGreenPlayer() -> void:
	ref_green_tank.visible = true;
	ref_red_tank.visible   = false;
	ref_green_tank_hp_container.visible = true;
	ref_red_tank_hp_container.visible   = false;
	
func LoadRedPlayer() -> void:
	ref_red_tank.visible   = true;
	ref_green_tank.visible = false;
	ref_green_tank_hp_container.visible = false;
	ref_red_tank_hp_container.visible   = true;

func LoadPlayerNames() -> void:
	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		player_name = Global.nicknames[EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER];
	else:
		player_name = Global.nicknames[EGlobalEnums.PLAYER_TYPE.RED_PLAYER];

func SetPosition(newPos: Vector2) -> void:
	if(!recording_last_postion):
		start_position = self.global_position;
		recording_last_postion = true;

	self.global_position = newPos;

func ResetPosition() -> void:
	self.global_position = start_position;
	recording_last_postion = false;

func ApplyPosition() -> void:
	start_position = self.global_position;
	recording_last_postion = false;

func GetFireProperty() -> Dictionary:
	return {
		"position": GetSpawnBulletPosition(),
		"angle": GetSpawnBulletAngle()
	};

func GetSpawnBulletPosition() -> Vector2:
	if(Global.GetCurrentPlayer() == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		return ref_spawn_bullet_green_player.global_position;

	return ref_spawn_bullet_red_player.global_position;

func GetSpawnBulletAngle() -> float:
	if(Global.GetCurrentPlayer() == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		return ref_green_tank_cannon.rotation_degrees;

	return ref_red_tank_cannon.rotation_degrees;

func ApplyDamage() -> void:
	currentHP = clamp(currentHP - 1, 0, 5);
	UpdateBarrier();

	if(currentHP <= 0):
		PlayerDead.emit(player_type);

func GetHPBarrier() -> float:
	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		return ref_green_tank_hp_value.value;
	else:
		return ref_red_tank_hp_value.value;

func SetCannonRotation(angle: float) -> void:
	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		ref_green_tank_cannon.rotation_degrees = angle;
	else:
		ref_red_tank_cannon.rotation_degrees = angle;

func UpdateShadowBarrier(percent: float) -> void:
	await get_tree().create_timer(1).timeout;

	var tween = create_tween();

	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		tween.tween_property(ref_green_tank_hp_bar, "value", percent, 0.5);
	else:
		tween.tween_property(ref_red_tank_hp_bar, "value", percent, 0.5);

func UpdateBarrier() -> void:
	var percent: float = (currentHP * 100) / MAX_HP;

	if(player_type == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		ref_green_tank_hp_value.value = percent	
	else:
		ref_red_tank_hp_value.value = percent

	UpdateShadowBarrier(percent);
