extends Control

class_name MatchSlot

signal AssignMatch(IDMatch);

@onready var ref_id_math: Label = $HBoxContainer/IDMatch;
@onready var ref_p1_nickname: Label = $HBoxContainer/P1Nickname;
@onready var ref_p2_nickname: Label = $HBoxContainer/P2Nickname;

var IDMatch: String    = "000";
var P1Nickname: String = "0";
var P2Nickname: String = "0";

func LoadMatchInfo(pIDMatch: String, pP1Nickname: String, pP2Nickname) -> void:
	IDMatch = pIDMatch;
	P1Nickname = pP1Nickname;
	P2Nickname = pP2Nickname;

func _on_assign_button_down() -> void:
	AssignMatch.emit(IDMatch);
