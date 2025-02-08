extends CanvasLayer

@onready var ref_setting = $Register/Setting;
@onready var ref_waiting = $Register/WaitContainer;
@onready var ref_form 	 = $Register/Form;
@onready var ref_input   = $Register/Form/nickname;
@onready var ref_match_container: VBoxContainer = $Register/AssignSpectator/VScrollBar/VBoxContainer;
@onready var ref_assign_spec: Control = $Register/AssignSpectator;
@onready var ref_wait_spec: CenterContainer = $Register/WaitSpectator;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ref_setting.closeSetting.connect(Callable(self, "_on_close_setting"));
	Global.ReceiveDataFromServer.connect(Callable(self, "_on_server_process_packet"));

	if(Global.last_name_picked == "unnamed"):
		ref_input.text = "";
	else:
		ref_input.text = Global.last_name_picked;

func DisableAllHuds() -> void:
	ref_form.visible 	= false;
	ref_waiting.visible = false;
	ref_setting.visible = false;
	ref_assign_spec.visible  = false;
	ref_wait_spec.visible = false;

func AssignToMatch(IDMatch: String) -> void:
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.SPECTATOR_ASSIGN, "idmatch": IDMatch});
	DisableAllHuds();
	ref_waiting.visible = true;
	Global.id_match = int(IDMatch);

func ClearMatchList() -> void:
	for child in ref_match_container.get_children():
		child.queue_free();

func _on_close_setting() -> void:
	DisableAllHuds();
	ref_form.visible = true;
	ClearMatchList();

func _on_setting_button_down() -> void:
	DisableAllHuds();
	ref_setting.visible = true;

func _on_find_match_button_down() -> void:
	var input: String = ref_input.text;
	Global.last_name_picked = input;
	if(input.length() > 0):
		Global.SendToServer({"netcode": 11, "nickname": input});

func _on_server_process_packet(packet: Dictionary) -> void:
	var netcode = packet["netcode"];
	if(netcode == EGlobalEnums.NETCODE.WAIT_MATCH):
		DisableAllHuds();
		ref_waiting.visible = true;

	if(netcode == EGlobalEnums.NETCODE.LOAD_GAME):
		Global.LoadPlayers(packet["idmatch"], packet["greenplayername"], packet["redplayername"], packet["my_tank"]);
		get_tree().change_scene_to_packed(Global.battle_scene);
		
	if(netcode == EGlobalEnums.NETCODE.SPECTATOR_LIST):
		var matches = str(packet["matches"]).split("#") as PackedStringArray;

		# Remove todas opções carregadas antes.
		ClearMatchList();

		# Aguarda um frame para garantir que os nós foram removidos
		await get_tree().process_frame;

		if(!matches[0].is_empty() && matches.size() > 1):
			for it: String in matches:
				var chunks = it.split("-");
				var slot: MatchSlot = load("res://UI/match_slot.tscn").instantiate();
				slot.LoadMatchInfo(chunks[0], chunks[1], chunks[2]);
				slot.AssignMatch.connect(Callable(self, "AssignToMatch"));
				ref_match_container.add_child(slot);
			
		# Mostra a tela de opções.
		DisableAllHuds();
		ref_assign_spec.visible = true;
		
	if(netcode == EGlobalEnums.NETCODE.SPECTATOR_ASSIGN):
		var id_spectator = packet["idSpectator"];
		var current_turn = packet["current_turn"];
		var P1State		 = packet["p1"].split("-");
		var P2State		 = packet["p2"].split("-");
		var timer		 = packet["timer"].split("-");
		
		Global.id_spectator   = id_spectator;
		Global.current_player = current_turn;
		Global.my_tank		  = EGlobalEnums.PLAYER_TYPE.SPECTATOR;
		Global.timer_spectator_minute = int(timer[0]);
		Global.timer_spectator_second = int(timer[1]);
		Global.spectator_players_states.push_back({"nickname": P1State[0], "HP": float(P1State[1]), "position": str_to_var("Vector2"+P1State[2])})
		Global.spectator_players_states.push_back({"nickname": P2State[0], "HP": float(P2State[1]), "position": str_to_var("Vector2"+P2State[2])})
		
		get_tree().change_scene_to_packed(Global.battle_scene);

func _on_spectator_button_down() -> void:
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.SPECTATOR_LIST});
	DisableAllHuds();
	ref_wait_spec.visible = true;
	ClearMatchList();

func _on_assign_back_button_down() -> void:
	_on_close_setting();
