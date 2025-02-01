extends Area2D

signal BulletStop(isPlayer: bool, position: Vector2, player_target: EGlobalEnums.PLAYER_TYPE);

@onready var ref_green_bullet = $GreenPlayerBullet;
@onready var ref_red_bullet   = $RedPlayerBullet;
@onready var ref_sfx_hit_tank: AudioStreamPlayer = $SFX_hit_tank;
@onready var ref_sfx_hit_wall: AudioStreamPlayer = $SFX_hit_wall;

@export var ref_explosion: Node2D;

# Somente existirá um projétil no jogo.
var canMove: bool = false
var angle: float = 0
var force: float = 0
var direction: Vector2 = Vector2.ZERO
var gravidade: Vector2 = Vector2(0, 0.5)  # Gravidade em pixels/s² (ajuste conforme necessário)

const MAX_LIMIT_Y: float = 350;
const MAX_LIMIT_X: float = 1220;

const OUT_OF_BOUNDS_BULLET := Vector2(-109, 50);

func _physics_process(delta: float) -> void:
	visible = canMove;

	if canMove:
		# Atualiza a direção com o efeito da gravidade
		direction += gravidade * delta
		
		# Atualiza a posição com a direção e força
		position += (direction.normalized() * delta) * force;
		
		# Atualiza o ângulo da bala para refletir sua direção atual
		angle = direction.angle()
		rotation = angle

		if(global_position.y > MAX_LIMIT_Y || global_position.x > MAX_LIMIT_X):
			canMove = false;
			await get_tree().create_timer(2).timeout;
			BulletStop.emit(false, 0)

func fire(pposition: Vector2, pangle: float, pforce: int) -> void:
	global_position = pposition;
	force = pforce * 10;
	angle = deg_to_rad(pangle)
	direction = Vector2(cos(angle), sin(angle));
	canMove = true
	checkForce();
	changeBulletOwnner();

func checkForce() -> void:
	if(force < 100):
		gravidade = Vector2(0, 1);
		force = 50;

func changeBulletOwnner() -> void:
	if(Global.GetCurrentPlayer() == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		ref_green_bullet.visible = true;
		ref_red_bullet.visible = false;
	else:
		ref_green_bullet.visible = false;
		ref_red_bullet.visible = true;
		direction *= -1;

func _on_area_entered(area:Area2D) -> void:
	ref_explosion.Active(global_position);
	canMove = false;

	if(area && area.is_in_group("Player")):
		ref_sfx_hit_tank.play()
	else:
		ref_sfx_hit_wall.play()

	await get_tree().create_timer(2).timeout;

	# Aplica reset e emite para fora.
	global_position = OUT_OF_BOUNDS_BULLET;
	if(area && area.is_in_group("Player")):
		BulletStop.emit(true, area.player_type)
	else:
		BulletStop.emit(false, 0)
		
