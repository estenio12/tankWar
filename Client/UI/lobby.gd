extends CanvasLayer

@onready var ref_setting = $Register/Setting;
@onready var ref_waiting = $Register/WaitContainer;
@onready var ref_form 	 = $Register/Form;
@onready var ref_input   = $Register/Form/nickname;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ref_setting.closeSetting.connect(Callable(self, "_on_close_setting"));
	Global.ReceiveDataFromServer.connect(Callable(self, "_on_server_confirm_queue"));

	if(Global.last_name_picked == "unnamed"):
		ref_input.text = "";
	else:
		ref_input.text = Global.last_name_picked;

func DisableAllHuds() -> void:
	ref_form.visible 	= false;
	ref_waiting.visible = false;
	ref_setting.visible = false;

func _on_close_setting() -> void:
	DisableAllHuds();
	ref_form.visible = true;

func _on_setting_button_down() -> void:
	DisableAllHuds();
	ref_setting.visible = true;

func _on_find_match_button_down() -> void:
	if(Global.socket.get_ready_state() != WebSocketPeer.STATE_OPEN):
		Global.RetryConnection();

	var input: String = ref_input.text;
	Global.last_name_picked = input;
	if(input.length() > 0):
		Global.SendToServer({"netcode": 11, "nickname": input});

func _on_server_confirm_queue(packet: Dictionary) -> void:
	if(packet["netcode"] == EGlobalEnums.NETCODE.WAIT_MATCH):
		DisableAllHuds();
		ref_waiting.visible = true;

	if(packet["netcode"] == EGlobalEnums.NETCODE.LOAD_GAME):
		Global.LoadPlayers(packet["idmatch"], packet["greenplayername"], packet["redplayername"], packet["my_tank"]);
		get_tree().change_scene_to_packed(Global.battle_scene);
