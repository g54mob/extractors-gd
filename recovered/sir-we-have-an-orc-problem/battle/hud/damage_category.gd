class_name DamageCategory
extends HBoxContainer

var tooltip: String
var icon: Texture2D

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var damage_label: Label = %DamageLabel
@onready var icon_texture_rect: TextureRect = %IconTextureRect

func _ready() -> void :
	icon_texture_rect.tooltip_text = tooltip
	icon_texture_rect.texture = icon
	damage_label.text = "0"
