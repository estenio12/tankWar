extends Area2D

signal BulletStop(isPlayer: bool);

@onready var ref_green_bullet = $GreenPlayerBullet;
@onready var ref_red_bullet   = $RedPlayerBullet;

# Somente existirá um projétil no jogo.
var canMove: bool = false
var angle: float = 0
var force: float = 0
var direction: Vector2 = Vector2.ZERO
var gravidade: Vector2 = Vector2(0, 0.5)  # Gravidade em pixels/s² (ajuste conforme necessário)

const MAX_LIMIT_Y: float = 350;
const MAX_LIMIT_X: float = 1650;

const OUT_OF_BOUNDS_BULLET := Vector2(-109, 50);

func _physics_process(delta: float) -> void:
	if canMove:
		# Atualize a direção com o efeito da gravidade
		direction += gravidade * delta
		
		# Atualize a posição com a direção e força
		position += (direction.normalized() * delta) * force;
		
		# Atualize o ângulo da bala para refletir sua direção atual
		angle = direction.angle()
		rotation = angle

		if(global_position.y > MAX_LIMIT_Y || global_position.x > MAX_LIMIT_X):
			canMove = false;
			BulletStop.emit(false)

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
	if(area && area.is_in_group("Player")):
		BulletStop.emit(true)
	else:
		BulletStop.emit(false)
		
	global_position = OUT_OF_BOUNDS_BULLET;
	canMove = false;
