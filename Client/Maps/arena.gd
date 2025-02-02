extends Node2D

signal placement_selected(global_position: Vector2);

# Refeências
@onready var ref_hud_choose_action: CenterContainer = $HUD/ChooseAction;
@onready var ref_label_action_count: Label = $HUD/ChooseAction/VBoxContainer/Control/amount;
@onready var ref_hud_apply_action: HBoxContainer = $HUD/ApplyAction;
@onready var ref_placement_green_player: SubViewportContainer = $PlacementGreenPlayer;
@onready var ref_placement_red_player: SubViewportContainer = $PlacementRedPlayer;
@onready var ref_green_player: CharacterBody2D = $GreenPlayer;
@onready var ref_red_player: CharacterBody2D = $RedPlayer;
@onready var ref_hud_change_player: CenterContainer = $HUD/ChangePlayer;
@onready var ref_hud_player_name: Label = $HUD/ChangePlayer/VBoxContainer/PlayerName
@onready var ref_hud_power_attack_container: HBoxContainer = $HUD/AttackForceContainer
@onready var ref_hud_power_attack: ProgressBar = $HUD/AttackForceContainer/ProgressBar
@onready var ref_hud_won_screen: CenterContainer = $HUD/WonScreen;
@onready var ref_hud_winner_name: Label = $HUD/WonScreen/VBoxContainer/WinnerName;
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

@onready var lobby_scene: PackedScene = preload("res://UI/lobby.tscn");

const MAX_ACTION_POINTS: int = 2;
const MAX_ATTACK_SECTION: int = 2;
var attack_section: int = 1;
var power_direction: int = 10;
var in_power_selection: bool = false;
var is_game_over: bool = false;
var winner_name: String = "Unnamed";
var is_player_change: bool = false;

var seconds: int = 0;
var minutes: int = 1;

var MAX_TURN_TIME_SECONDS: float = 30;
var turn_time_seconds: float = MAX_TURN_TIME_SECONDS;

var action_point: int = MAX_ACTION_POINTS;
var players: Array[CharacterBody2D] = [];
var placements: Array[SubViewportContainer] = [];
var current_action: EGlobalEnums.ACTION = EGlobalEnums.ACTION.SELECTION;
var powerup_acquired: EGlobalEnums.POWERUP = EGlobalEnums.POWERUP.NONE;

func _ready() -> void:
	# Signals
	self.placement_selected.connect(Callable(self, "_on_placement_selected"));
	self.ref_bullet.BulletStop.connect(Callable(self, "_on_bullet_stop"));
	Global.ReceiveDataFromServer.connect(Callable(self, "_on_receive_data_from_server"));
	self.ref_green_player.PlayerDead.connect(Callable(self, "_on_player_dead"));
	self.ref_red_player.PlayerDead.connect(Callable(self, "_on_player_dead"));

	ref_green_player.LoadPlayerNames();
	ref_red_player.LoadPlayerNames();

	self.players = [ref_green_player, ref_red_player];
	self.placements = [ref_placement_green_player, ref_placement_red_player];
	
	# Loads
	action_point = MAX_ACTION_POINTS;
	UpdateLabelActionCount();

	# Notifica o servidor de que está tudo carregado. 
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.READY, "PID": Global.my_tank}); 

func _physics_process(delta: float) -> void:
	# Sistema para escolher a pontência do canhão.
	if(in_power_selection):
		ref_hud_power_attack.value += (power_direction * delta) * 10;

		if(ref_hud_power_attack.value >= 100):
			power_direction = -10;

		if(ref_hud_power_attack.value <= 0):
			power_direction = 10;

	ref_hud_turn_time.visible = Global.IsMyTank();

func GetCurrentPlayer() -> CharacterBody2D:
	return players[Global.GetCurrentPlayer()];

func UpdateLabelActionCount() -> void:
	ref_label_action_count.text = str(action_point);

func UpdateLabelTimeManager() -> void:
	ref_hud_timer_label.text = str("%02d" % minutes) + ":" + str("%02d" % seconds);

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
				ref_hud_choose_action.visible = true;
		EGlobalEnums.ACTION.CHANGE_PLAYER:
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
	ref_hud_apply_action.visible  	   = false;
	ref_hud_choose_action.visible 	   = false;
	ref_placement_green_player.visible = false;
	ref_placement_red_player.visible   = false;
	ref_hud_change_player.visible      = false;
	ref_hud_won_screen.visible 		   = false;
	ref_hud_power_attack_container.visible = false;

func ApplyAction() -> void:
	action_point = clamp(action_point - 1, 0, MAX_ACTION_POINTS);

func CheckActionPointCount() -> void:
	if(action_point <= 0):
		action_point = MAX_ACTION_POINTS;
		Global.SendToServer({"netcode": EGlobalEnums.NETCODE.CHANGE_PLAYER, "current_player": Global.GetCurrentPlayer()});

	UpdateLabelActionCount();
	ActionManager();

func ShowWinnerScreen() -> void:
	DisableAllHUDs();
	ref_hud_bar_screen.visible = false;
	ref_hud_turn_time.visible = false;
	ref_hud_turn_time_manager.stop();
	ref_hud_winner_name.text = winner_name;
	ref_hud_won_screen.visible = true;
	await get_tree().create_timer(2).timeout;
	ref_hud_won_screen_close_game.visible = true;
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.CLOSE_GAME, "PID": Global.my_tank});

func TimeIsOver() -> void:
	ref_hud_time_manager.stop();
	var green_player_hp: int = ref_green_player.currentHP;
	var red_player_hp: int = ref_red_player.currentHP;

	if(green_player_hp > red_player_hp):
		_on_player_dead(EGlobalEnums.PLAYER_TYPE.RED_PLAYER);
	elif(green_player_hp < red_player_hp):
		_on_player_dead(EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER);
	else:
		_on_player_dead(EGlobalEnums.PLAYER_TYPE.BOTH);

func EnableTurnTime() -> void:
	ref_hud_turn_time_counter.value = 100;
	turn_time_seconds = MAX_TURN_TIME_SECONDS;
	ref_hud_turn_time_manager.start(1);

func TurnTimeOver() -> void:
	action_point = 0;
	CheckActionPointCount();

#------------------------- DATA SERVER PROCESSING 

func _on_receive_data_from_server(packet: Dictionary) -> void:

	match(packet["netcode"] as EGlobalEnums.NETCODE):
		EGlobalEnums.NETCODE.SELECTION:
			current_action = EGlobalEnums.ACTION.SELECTION;
			ActionManager();
		EGlobalEnums.NETCODE.CHANGE_PLAYER:
			var player_target = packet["player"];
			Global.ChangePlayer(player_target);
			action_point = MAX_ACTION_POINTS;
			current_action = EGlobalEnums.ACTION.CHANGE_PLAYER;
			ref_hud_player_name.text = GetCurrentPlayer().player_name;
			ActionManager();
			await get_tree().create_timer(2).timeout;
			current_action = EGlobalEnums.ACTION.SELECTION;
			ActionManager();
			EnableTurnTime();
			is_player_change = true;
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

			var player_won = packet["player"] as EGlobalEnums.PLAYER_TYPE;
			
			if(player_won == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
				winner_name = ref_green_player.player_name;
			elif(player_won == EGlobalEnums.PLAYER_TYPE.RED_PLAYER):
				winner_name = ref_red_player.player_name;
			else:
				winner_name = "Empate";
				
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
		
		# Tempo para voltar o target da câmera para os jogadores.
		await get_tree().create_timer(2).timeout;
		ref_camera.EnableTargetInBullet(false);
		
		if(action_point <= 1):
			await get_tree().create_timer(1).timeout;
		else:
			ref_hud_turn_time_manager.start(1);

		current_action = EGlobalEnums.ACTION.SELECTION;
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
	seconds = clamp(seconds - 1, 0, 59);

	if(seconds <= 0 && minutes <= 0):
		TimeIsOver();
	elif(seconds <= 0):
		minutes = clamp(minutes - 1, 0, 3);
		seconds = 59;
	
	UpdateLabelTimeManager();

func _on_turn_timer_second_pass() -> void:
	turn_time_seconds = clamp(turn_time_seconds - 1, 0, MAX_TURN_TIME_SECONDS);

	if(turn_time_seconds <= 0):
		ref_hud_turn_time_manager.stop();
		TurnTimeOver();
	else:
		ref_hud_turn_time_counter.value = (turn_time_seconds * 100) / MAX_TURN_TIME_SECONDS;

func _on_close_game_button_down() -> void:
	var lobby_instance = lobby_scene.instantiate()
	print(lobby_instance);
	get_tree().change_scene_to_packed(lobby_instance);
