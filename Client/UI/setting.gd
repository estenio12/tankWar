extends CenterContainer

signal closeSetting();

@onready var ref_input_ip: LineEdit = $VBoxContainer/INP_IP;
@onready var ref_input_port: LineEdit = $VBoxContainer/INP_PORT;
@onready var ref_btn_cancel: Button = $VBoxContainer/Cancelar;

func _ready() -> void:
	ref_btn_cancel.button_down.connect(Callable(self, "_on_cancel_button_down"));
	ref_input_ip.text   = Global.ServerIP;
	ref_input_port.text = str(Global.ServerPORT);

func _on_apply_button_down() -> void:
	if(ref_input_ip.text != Global.ServerIP || ref_input_port.text != str(Global.ServerPORT)):
		Global.UpdateConection(ref_input_ip.text, int(ref_input_port.text));
		
	closeSetting.emit();

func _on_cancel_button_down() -> void:
	closeSetting.emit();

	
