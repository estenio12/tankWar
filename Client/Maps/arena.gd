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
@onready var ref_bullet: Area2D = $Bullet;

const MAX_ACTION_POINTS: int = 2;
const MAX_ATTACK_SECTION: int = 2;
var attack_section: int = 1;
var power_direction: int = 10;
var in_power_selection: bool = false;

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

	self.players = [ref_green_player, ref_red_player];
	self.placements = [ref_placement_green_player, ref_placement_red_player];
	
	# Loads
	action_point = MAX_ACTION_POINTS;
	UpdateLabelActionCount();

func _physics_process(delta: float) -> void:
	# Sistema para escolher a pontência do canhão.
	if(in_power_selection):
		ref_hud_power_attack.value += (power_direction * delta) * 10;

		if(ref_hud_power_attack.value >= 100):
			power_direction = -10;

		if(ref_hud_power_attack.value <= 0):
			power_direction = 10;

func GetCurrentPlayer() -> CharacterBody2D:
	return players[Global.GetCurrentPlayer()];

func UpdateLabelActionCount() -> void:
	ref_label_action_count.text = str(action_point);

func ActionManager() -> void:
	DisableAllHUDs();

	match(current_action):
		EGlobalEnums.ACTION.MOVIMENT:
			ref_hud_apply_action.visible = true;
			placements[Global.GetCurrentPlayer()].visible = true;
		EGlobalEnums.ACTION.SELECTION:
			UpdateLabelActionCount();
			ref_hud_choose_action.visible = true;
		EGlobalEnums.ACTION.CHANGE_PLAYER:
			UpdateLabelActionCount();
			ref_hud_change_player.visible = true;
		EGlobalEnums.ACTION.ATTACK:
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
	ref_hud_power_attack_container.visible = false;

func ApplyAction() -> void:
	action_point = max(0, action_point - 1);

	if(action_point <= 0):
		Global.SendToServer({"netcode": EGlobalEnums.NETCODE.CHANGE_PLAYER, "current_player": Global.GetCurrentPlayer()});

	UpdateLabelActionCount();
	ActionManager();

func ShowWinnerScreen(pwinner: String) -> void:
	DisableAllHUDs();

#------------------------- DATA SERVER PROCESSING 

func _on_receive_data_from_server(strPacket: String) -> void:
	var packet = ServerNetPacket.new(strPacket).GetPacket();

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
		EGlobalEnums.NETCODE.APPLY_MOVIMENT:
			GetCurrentPlayer().SetPosition(packet["position"]);
			GetCurrentPlayer().ApplyPosition();
			current_action = EGlobalEnums.ACTION.SELECTION;
			ApplyAction();
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
			ref_bullet.fire(packet["position"], packet["angle"], packet["power"]);
		EGlobalEnums.NETCODE.END_GAME:
			var player_won = packet["position"] as EGlobalEnums.PLAYER_TYPE;
			var winner_name: String = "Unnamed";
			if(player_won == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
				winner_name = ref_green_player.player_name;
			else:
				winner_name = ref_red_player.player_name;
				
			ShowWinnerScreen(winner_name);
		EGlobalEnums.NETCODE.POWERUP:
			pass

#------------------------- SIGNALS CONNECT 

func _on_moviment_action_button_down() -> void:
	current_action = EGlobalEnums.ACTION.MOVIMENT;
	ActionManager();

func _on_attack_action_button_down() -> void:
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.ATTACK});
	# current_action = EGlobalEnums.ACTION.WAIT_SERVER;
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

func _on_bullet_stop(isPlayer: bool) -> void:
	if(isPlayer):
		if(Global.GetCurrentPlayer() == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER):
			ref_red_player.ApplyDamage();
		else:
			ref_green_player.ApplyDamage();
	
	current_action = EGlobalEnums.ACTION.SELECTION;
	ApplyAction();

func _on_player_dead(pplayer: EGlobalEnums.PLAYER_TYPE) -> void:
	var player_won = EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER if(pplayer == EGlobalEnums.PLAYER_TYPE.GREEN_PLAYER) else EGlobalEnums.PLAYER_TYPE.RED_PLAYER;
	Global.SendToServer({"netcode": EGlobalEnums.NETCODE.END_GAME, "player": player_won})
		
