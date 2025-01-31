extends Node2D

@onready var ref_anim: AnimatedSprite2D = $AnimatedSprite2D;

func Active(ppos: Vector2) -> void:
	global_position = ppos;
	ref_anim.play("explosion");
