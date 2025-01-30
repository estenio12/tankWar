extends Node2D

@onready var ref_anim: AnimatedSprite2D = $AnimatedSprite2D;

func Active(position: Vector2) -> void:
	global_position = position;
	ref_anim.play("explosion");
