extends Node

var fullscreen: bool:
	set(value):
		fullscreen = value
		if fullscreen:



			get_tree().root.mode = Window.MODE_FULLSCREEN
		else:
			get_tree().root.mode = Window.MODE_WINDOWED

signal crt_effect_changed(is_enabled: bool)
var crt_effect_enabled: = true:
	set(value):
		crt_effect_enabled = value
		crt_effect_changed.emit(crt_effect_enabled)

var show_tech_tree_controls: = true
var show_battle_controls: = true
var edge_scrolling: = false
var tech_tree_camera_pos: = Vector2(1418, 709)
var tech_tree_camera_zoom: = 1.0
var decimal_separator: String = "."

var supporter_flames_enabled: = false
var supporter_orcs_enabled: = false
var supporter_background_enabled: = false

func load_data(data: Dictionary) -> void :
	var options_dict: Dictionary = data.get("options", {})
	for key: StringName in options_dict.keys():
		self.set(key, options_dict[key])

	if data.is_empty() or options_dict.is_empty():
		fullscreen = true


	if !GameManager.has_supporter_pack:
		supporter_flames_enabled = false
		supporter_orcs_enabled = false
		supporter_background_enabled = false

	if edge_scrolling:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	var locale: String = options_dict.get("locale", "")
	var supported_locales: PackedStringArray = PackedStringArray(["en"]) + TranslationServer.get_loaded_locales()
	var locale_to_test: String = locale if !locale.is_empty() else OS.get_locale()
	if supported_locales.has(locale_to_test):
		set_locale(locale_to_test)
	elif locale_to_test.contains("_"):
		locale_to_test = locale_to_test.split("_")[0]
		if supported_locales.has(locale_to_test):
			set_locale(locale_to_test)
		else:
			set_locale("en")
	else:
		set_locale("en")


func save(data: Dictionary) -> void :
	var options_dict: = {}
	options_dict["fullscreen"] = fullscreen
	options_dict["crt_effect_enabled"] = crt_effect_enabled
	options_dict["show_tech_tree_controls"] = show_tech_tree_controls
	options_dict["show_battle_controls"] = show_battle_controls
	options_dict["edge_scrolling"] = edge_scrolling
	options_dict["tech_tree_camera_pos"] = tech_tree_camera_pos
	options_dict["tech_tree_camera_zoom"] = tech_tree_camera_zoom
	options_dict["locale"] = TranslationServer.get_locale()
	options_dict["supporter_flames_enabled"] = supporter_flames_enabled
	options_dict["supporter_orcs_enabled"] = supporter_orcs_enabled
	options_dict["supporter_background_enabled"] = supporter_background_enabled
	data["options"] = options_dict

func set_locale(locale: String) -> void :
	TranslationServer.set_locale(locale)

	if ["en", "ja", "ko", "zh_CN", "zh_TW"].find(locale) >= 0:
		decimal_separator = "."
	else:
		decimal_separator = ","
