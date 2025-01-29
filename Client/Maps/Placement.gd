extends TextureButton

@export var ref_marker: Marker2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.button_up.connect(Callable(self, "_on_touch_event"));

func _on_touch_event() -> void:
	get_parent().get_parent().get_parent().placement_selected.emit(ref_marker.global_position)