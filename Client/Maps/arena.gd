extends Node2D

signal placement_selected(global_position: Vector2);

# Refeências
@onready var ref_hud_choose_action: Control = $HUD/ChooseAction;
@onready var ref_hud_select_action: Control = $HUD/SelectAction;
@onready var ref_label_action_count: Label = $HUD/ChooseAction/Control/VBoxContainer/Control/amount;
@onready var ref_hud_apply_action: VBoxContainer = $HUD/ApplyAction;
@onready var ref_placement_green_player: SubViewportContainer = $PlacementGreenPlayer;
@onready var ref_placement_red_player: SubViewportContainer = $PlacementRedPlayer;
@onready var ref_green_player: Player = $GreenPlayer;
@onready var ref_red_player: Player = $RedPlayer;
@onready var ref_hud_change_player: CenterContainer = $HUD/ChangePlayer;
@onready var ref_hud_player_name: Label = $HUD/ChangePlayer/VBoxContainer/PlayerName
@onready var ref_hud_power_attack_container: HBoxContainer = $HUD/AttackForceContainer
@onready var ref_hud_power_attack: ProgressBar = $HUD/AttackForceContainer/ProgressBar
@onready var ref_hud_won_screen: CenterContainer = $HUD/WonScreen;
@onready var ref_hud_spec_won_screen: CenterContainer = $HUD/SpectatorWonScreen;
@onready var ref_hud_winner_name: Label = $HUD/WonScreen/VBoxContainer/WinnerName;
@onready var ref_hud_spec_winner_name: Label = $HUD/SpectatorWonScreen/VBoxContainer/WinnerName;
@onready var ref_hud_won_screen_close_game = $HUD/WonScreen/VBoxContainer/CloseGame;
@onready var ref_bullet: Area2D = $Bullet;
@onready var ref_camera: Camera2D = $Camera2D;
@onready var ref_hud_bar_screen: CenterContainer = $HUD/HUDGamplay;
@onready var ref_hud_timer_label: Label = $HUD/HUDGamplay/Label;
@onready var ref_hud_time_manager: Timer = $HUD/HUDGamplay/TimeManager;
@onready var ref_hud_turn_time: CenterContainer = $HUD/TurnTimer;
@onready var ref_hud_turn_time_counter: ProgressBar = $HUD/TurnTimer/ProgressBar;
@onready var ref_hud_turn_time_manager: Timer = $HUD/TurnTimer/TurnTimeManager;
@onready var ref_sfx_fire: AudioStreamPlayer = $SFX_Fire;
@onready var ref_loadscreen: Control = $HUD/LoadScreen;
@onready var ref_sfx_env: AudioStreamPlayer = $SFX_Env;
@onready var ref_hud_spectator: CenterContainer = $HUD/HUDSpectator;
@onready var ref_hud_spectator_p1_hp_bar: ProgressBar = $HUD/HUDSpectator/HBoxContainer/GreenPlayerBar/BPBar;
@onready var ref_hud_spectator_p2_hp_bar: ProgressBar = $HUD/HUDSpectator/HBoxContainer/RedPlayerBar/BPBar;
@onready var ref_hud_spectator_timer: Label = $HUD/HUDSpectator/HBoxContainer/Timer/Counter;

const MAX_ACTION_POINTS: int = 2;
const MAX_ATTACK_SECTION: int = 2;
var attack_section: int = 1;
var power_direction: int = 10;
var in_power_selection: bool = false;
var is_game_over: bool = false;
var winner_name: String = "Unnamed";
var spectator_hud_deactivate: bool = false;

var seconds: int = 59;
var minutes: int = 4;

var MAX_TURN_TIME_SECONDS: float = 30;
var turn_time_seconds: float = MAX_TURN_TIME_SECONDS;

var action_point: int = MAX_ACTION_POINTS;
var players: Array[CharacterBody2D] = [];
var placements: Array[SubViewportContainer] = [];
var current_action: EGlobalEnums.ACTION = EGlobalEnums.ACTION.SELECTION;
var powerup_acquired: EGlobalEnums.POWERUP = EGlobalEnums.POWERUP.NONE;

func _ready() -> void:
	# Signals
	Global.ReceiveDataFromServer.connect(Callable(self, "_on_receive_data_from_server"));
	self.ref_bullet.BulletStop.connect(Callable(self, "_on_bullet_stop"));
	self.ref_green_player.PlayerDead.connect(Callable(self, "_on_player_dead"));
	self.ref_red_player.PlayerDead.connect(Callable(self, "_on_player_dead"));
	self.placement_selected.connect(Callable(self, "_on_placement_selected"));
	
	if(Global.IsSpectator()):
		var p1_state = Global.spectator_players_states[0];
		var p2_state = Global.spectator_players_states[1];
		ref_green_player.player_name = p1_state["nickname"];
		ref_green_player.currentHP   = p1_state["HP"];
		ref_green_player.global_position = p1_state["position"];
		ref_green_player.UpdateBarrier();
		ref_red_player.player_name = p2_state["nickname"];
		ref_red_player.currentHP   = p2_state["HP"];
		ref_red_player.global_position = p2_state["position"];
		ref_red_player.UpdateBarrier();
		ref_loadscreen.visible = false;
		ref_hud_spectator.visible = true;
		minutes = Global.timer_spectator_minute;
		seconds = Global.timer_spectator_second;
		ref_hud_time_manager.start(1);
		UpdateHUDSpectator();

	if(!Global.IsSpectator()):
		ref_green_player.LoadPlayerNames();
		ref_red_player.LoadPlayerNames();

	self.players = [ref_green_player, ref_red_player];
	
	if(!Global.IsSpectator()):
		self.placements = [ref_placement_green_player, ref_placement_red_player];	
		action_point = MAX_ACTION_POINTS;
		UpdateLabelActionCount();

	# Notifica o servidor de que está tudo carregado. 
	if(!Global.IsSpectator()):
		Global.SendToServer({"netcode": EGlobalEnums.NETCODE.READY, "PID": Global.my_tank});

func _physics_process(delta: float) -> void:
	# Sistema para escolher a pontência do canhão.
	if(in_power_selection):
		ref_hud_power_attack.value += (power_direction * delta) * 10;

		if(ref_hud_power_attack.value >= 100):
			power_direction = -10;

		if(ref_hud_power_attack.value <= 0):
			power_direction = 10;

	if(ref_hud_turn_time):
		ref_hud_turn_time.visible = Global.IsMyTank() && !is_game_over;

func GetCurrentPlayer() -> CharacterBody2D:
	return players[Global.GetCurrentPlayer()];

func UpdateLabelActionCount() -> void:
	ref_label_action_count.text = str(action_point);

func UpdateLabelTimeManager() -> void:
	var time: String = str("%02d" % minutes) + ":" + str("%02d" % seconds);
	ref_hud_timer_label.text = time;

	if(Global.IsSpectator()):
		ref_hud_spectator_timer.text = time;

func ActionManager() -> void:
	if(is_game_over):
		ShowWinnerScreen();
		return;
	
	DisableAllHUDs();

	match(current_action):
		EGlobalEnums.ACTION.MOVIMENT:
			if(Global.IsMyTank()):
				ref_hud_apply_action.visible = true;
				placements[Global.GetCurrentPlayer()].visible = true;
		EGlobalEnums.ACTION.SELECTION:
			if(Global.IsMyTank()):
				UpdateLabelActionCount();
				HUDSelectAction(true);
		EGlobalEnums.ACTION.CHANGE_PLAYER:
			if(!is_game_over):
				action_point = MAX_ACTION_POINTS;
				UpdateLabelActionCount();
				ref_hud_change_player.visible = true;
		EGlobalEnums.ACTION.ATTACK:
			if(Global.IsMyTank()):
				ref_hud_apply_action.visible = true;
				if(attack_section == 2):
					GetCurrentPlayer().select_angle_active = false;
					ref_hud_power_attack_container.visible = true;

func DisableAllHUDs() -> void:
	if(Global.IsSpectator() && is_game_over && !spectator_hud_deactivate):
		spectator_hud_deactivate = true;
	
	if(Global.IsSpectator() && is_game_over && spectator_hud_deactivate):
		return;

	HUDSelectAction(false);
	ref_hud_apply_action.visible  	   = false;
	ref_placement_green_player.visible = false;
	ref_placement_red_player.visible   = false;
	ref_hud_change_player.visible      = false;
	ref_hud_won_screen.visible 		   = false;
	ref_hud_power_attack_container.visible = false;

func ApplyAction() -> void:
	action_point = clamp(action_point - 1, 0, MAX_ACTION_POINTS);

func CheckActionPointCount() -> void:
	if(action_point <= 0):
		if(Global.IsMyTank()):
			Global.SendToServer(\
			{
				"netcode": EGlobalEnums.NETCODE.CHANGE_PLAYER, 
				"current_player": Global.GetCurrentPlayer(),
				"state_p1": str(ref_green_player.currentHP) + "-" + str(ref_green_player.global_position),
				"state_p2": str(ref_red_player.currentHP) + "-" + str(ref_red_player.global_position)
			});
		
		if(Global.IsSpectator() && !is_game_over):
			current_action = EGlobalEnums.ACTION.CHANGE_PLAYER;

	UpdateLabelActionCount();
	ActionManager();

func ShowWinnerScreen() -> void:
	DisableAllHUDs();

	if(Global.IsSpectator() && winner_name == "Unnamed"):
		ref_hud_winner_name.text = GetSpectatorWinner();
		ref_hud_spec_winner_name.text = GetSpectatorWinner();
	else:
		ref_hud_winner_name.text = winner_name;
		ref_hud_spec_winner_name.text = winner_name;

	ref_hud_bar_screen.visible = false;
	ref_hud_turn_time.visible  = false;
	ref_hud_spectator.visible  = false;
	ref_hud_turn_time_manager.stop();

	if(Global.IsSpectator()):
		ref_hud_spec_won_screen.visible = true;
	else:
		ref_hud_won_screen.visible = true;

	await get_tree().create_timer(2).timeout;
	ref_hud_won_screen_close_game.visible = true;

	if(!Global.IsSpectator()):
		Global.SendToServer({"netcode": EGlobalEnums.NETCODE.CLOSE_GAME, "PID": Global.my_tank});

func TimeIsOver() -> void:
	if(!is_game_over):
		ref_hud_time_manager.stop();
		#is_game_over = true;

func EnableTurnTime() -> void:
	if(!is_game_over):
		ref_hud_turn_time_counter.value = 100;
		turn_time_seconds = MAX_TURN_TIME_SECONDS;
		var turn_time = 1;

		if(minutes <= 1):
			turn_time = 0.4;

		ref_hud_turn_time_manager.start(turn_time);

func TurnTimeOver() -> void:
	if(!is_game_over):
		ref_green_player.select_angle_active = false;
		ref_red_player.select_angle_active = false;
		action_point = 0;
		await get_tree().create_timer(1.5).timeout;
		CheckActionPointCount();

func UpdateHUDSpectator() -> void:
	ref_hud_spectator_p1_hp_bar.value = ref_green_player.GetHPBarrier();
	ref_hud_spectator_p2_hp_bar.value = ref_red_player.GetHPBarrier();

func GetWinner() -> EGlobalEnums.PLAYER_TYPE:
	var green_player_hp: float = ref_green_player.currentHP;
	var red_player_hp: float = ref_red_player.currentHP;

	if(green_player_hp > red_player_hp):
		return EGlobalEnums.PLAYER_TYPE.RED_PLAYER;
	elif(green_player_hp < red_player_hp):
		return EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
	else:
		return EGlobalEnums.PLAYER_TYPE.BOTH;

func GetSpectatorWinner() -> String:
	if(GetWinner() == EGlobalEnums.PLAYER_TYPE.RED_PLAYER):
		return ref_green_player.player_name;
	if(GetWinner() == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		return ref_red_player.player_name;
	else:
		return "Empate"

func UpdateTimerFromServer(pmin: int, psec: int) -> void:
	minutes = pmin;
	seconds = psec;
	_on_time_second_pass();
	ref_hud_time_manager.start(1);

func HUDSelectAction(flag: bool) -> void:
	ref_hud_select_action.visible = flag;
	ref_hud_choose_action.visible = flag;

#------------------------- DATA SERVER PROCESSING 

func _on_receive_data_from_server(packet: Dictionary) -> void:
	if(Global.IsSpectator() && is_game_over):
		ShowWinnerScreen();
		return;			

	match(packet["netcode"] as EGlobalEnums.NETCODE):
		EGlobalEnums.NETCODE.SELECTION:
			current_action = EGlobalEnums.ACTION.SELECTION;
			ActionManager();
			EnableTurnTime();
		EGlobalEnums.NETCODE.CHANGE_PLAYER:
			if(!is_game_over):
				UpdateTimerFromServer(packet["min"], packet["sec"]);
				var player_target = packet["current_player"];
				var state_p1 = packet["state_p1"].split("-");
				var state_p2 = packet["state_p2"].split("-");
				ref_green_player.currentHP = state_p1[0];
				ref_green_player.global_position = str_to_var("Vector2"+state_p1[1]);
				ref_red_player.currentHP = state_p2[0];
				ref_red_player.global_position = str_to_var("Vector2"+state_p2[1]);
				Global.ChangePlayer(player_target);
				action_point = MAX_ACTION_POINTS;
				ref_hud_player_name.text = packet["nickname"];

				if(!Global.IsMyTank()):
					current_action = EGlobalEnums.ACTION.CHANGE_PLAYER;
					ActionManager();
					await get_tree().create_timer(2).timeout;
				
				if(Global.IsSpectator()):
					UpdateHUDSpectator();

				current_action = EGlobalEnums.ACTION.SELECTION;
				ActionManager();
				EnableTurnTime();
		EGlobalEnums.NETCODE.APPLY_MOVIMENT:
			GetCurrentPlayer().SetPosition(packet["position"]);
			GetCurrentPlayer().ApplyPosition();
			current_action = EGlobalEnums.ACTION.SELECTION;
			ApplyAction();
			CheckActionPointCount();
		EGlobalEnums.NETCODE.RESET_MOVIMENT:
			GetCurrentPlayer().ResetPosition();
			current_action = EGlobalEnums.ACTION.SELECTION;
			ActionManager();
		EGlobalEnums.NETCODE.MOVIMENT:
			GetCurrentPlayer().SetPosition(packet["position"]);
			current_action = EGlobalEnums.ACTION.MOVIMENT;
			ActionManager();
		EGlobalEnums.NETCODE.ATTACK:
			GetCurrentPlayer().select_angle_active = true;
			current_action = EGlobalEnums.ACTION.ATTACK;
			ActionManager();
		EGlobalEnums.NETCODE.APPLY_ATTACK:
			# print("Debug Apply Attack: ", packet);
			ref_camera.EnableTargetInBullet(true);
			GetCurrentPlayer().select_angle_active = false;
			GetCurrentPlayer().SetCannonRotation(packet["angle"]);
			ref_bullet.fire(packet["position"], packet["angle"], packet["power"]);
			ref_sfx_fire.play();
			ref_hud_turn_time_manager.stop();
			ApplyAction();
		EGlobalEnums.NETCODE.END_GAME:
			ref_hud_turn_time_manager.stop();
			ref_hud_turn_time.visible = false;
			is_game_over = true;
			winner_name = packet["player"];
			ShowWinnerScreen();
		EGlobalEnums.NETCODE.START_GAME:
			ref_hud_bar_screen.visible = true;
			ref_hud_turn_time.visible = true;
			ref_hud_time_manager.start(1);
			Global.ChangePlayer(packet["player"] as EGlobalEnums.PLAYER_TYPE);
			current_action = EGlobalEnums.ACTION.SELECTION;
			ActionManager();
			EnableTurnTime();
			ref_loadscreen.visible = false;
			ref_sfx_env.play();
		EGlobalEnums.NETCODE.POWERUP:
			pass

#------------------------- SIGNALS CONNECT 

func _on_moviment_action_button_down() -> void:
	current_action = EGlobalEnums.ACTION.MOVIMENT;
	ActionManager();

func _on_attack_action_button_down() -> void:
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.ATTACK});
	ActionManager();

func _on_placement_selected(new_place: Vector2) -> void:
	current_action = EGlobalEnums.ACTION.WAIT_SERVER;
	ActionManager();
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.MOVIMENT, "current_player": Global.GetCurrentPlayer(), "position": new_place});

func _on_btn_apply_action_accept_button_up() -> void:
	match(current_action):
		EGlobalEnums.ACTION.MOVIMENT:
			Global.SendToServer({"netcode": EGlobalEnums.NETCODE.APPLY_MOVIMENT, "current_player": Global.GetCurrentPlayer(), "position": GetCurrentPlayer().global_position});
		EGlobalEnums.ACTION.ATTACK:
			if(attack_section == 1):
				attack_section = 2;
				in_power_selection = true;
				current_action = EGlobalEnums.ACTION.ATTACK;
				ActionManager();
			else:
				attack_section = 1;
				in_power_selection = false;
				var fireProperty = GetCurrentPlayer().GetFireProperty();
				var power = ref_hud_power_attack.value;
				Global.SendToServer({"netcode": EGlobalEnums.NETCODE.APPLY_ATTACK, "current_player": Global.GetCurrentPlayer(), "position": fireProperty["position"], "angle": fireProperty["angle"], "power": power});
				current_action = EGlobalEnums.ACTION.WAIT_SERVER;
				ActionManager();

func _on_btn_apply_action_back_button_up() -> void:
	match(current_action):
		EGlobalEnums.ACTION.MOVIMENT:
			Global.SendToServer({"netcode": EGlobalEnums.NETCODE.RESET_MOVIMENT, "current_player": Global.GetCurrentPlayer()});
		EGlobalEnums.ACTION.ATTACK:
			attack_section = 1;
			current_action = EGlobalEnums.ACTION.SELECTION;
			GetCurrentPlayer().select_angle_active = false;
			ActionManager();

func _on_bullet_stop(isPlayer: bool, player_target: EGlobalEnums.PLAYER_TYPE) -> void:
	if(!is_game_over):
		if(isPlayer):
			var current_p = Global.GetCurrentPlayer();
			if(player_target == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER && current_p != EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
				ref_green_player.ApplyDamage();
				
			if(player_target == EGlobalEnums.PLAYER_TYPE.RED_PLAYER && current_p != EGlobalEnums.PLAYER_TYPE.RED_PLAYER):
				ref_red_player.ApplyDamage();
				
		if(Global.IsSpectator()):
			UpdateHUDSpectator();
		
		# Tempo para voltar o target da câmera para os jogadores.
		await get_tree().create_timer(2).timeout;

		if(!is_game_over):
			ref_camera.EnableTargetInBullet(false);
		
		if(action_point < 1):
			await get_tree().create_timer(1).timeout;
		else:
			EnableTurnTime();

		if(!Global.IsSpectator() && !is_game_over):
			current_action = EGlobalEnums.ACTION.SELECTION;

		if(!is_game_over):
			ActionManager();
			CheckActionPointCount();

func _on_player_dead(pplayer: EGlobalEnums.PLAYER_TYPE) -> void:
	is_game_over = true;
	var player_won: EGlobalEnums.PLAYER_TYPE;
	
	if(pplayer == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
		player_won = EGlobalEnums.PLAYER_TYPE.RED_PLAYER;
	elif(pplayer == EGlobalEnums.PLAYER_TYPE.RED_PLAYER):
		player_won = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER;
	else:
		player_won = EGlobalEnums.PLAYER_TYPE.BOTH;
		
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.END_GAME, "player": player_won});

func _on_time_second_pass() -> void:
	if(!is_game_over):
		seconds = clamp(seconds - 1, 0, 59);

		if(seconds <= 0 && minutes <= 0):
			TimeIsOver();
		elif(seconds <= 0):
			minutes = clamp(minutes - 1, 0, 3);
			seconds = 59;
		
		UpdateLabelTimeManager();

func _on_turn_timer_second_pass() -> void:
	if(!is_game_over):
		turn_time_seconds = clamp(turn_time_seconds - 1, 0, MAX_TURN_TIME_SECONDS);

		if(turn_time_seconds <= 0):
			ref_hud_turn_time_manager.stop();
			TurnTimeOver();
		else:
			ref_hud_turn_time_counter.value = (turn_time_seconds * 100) / MAX_TURN_TIME_SECONDS;

func _on_close_game_button_down() -> void:
	get_tree().change_scene_to_packed(Global.lobby_scene);
