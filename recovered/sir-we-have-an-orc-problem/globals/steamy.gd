extends Node

signal initialized()

var has_steam: bool = false
var steam_initialized: bool = false

var app_id: int = -1
const APP_ID_MAIN: int = 4594150
const APP_ID_DEMO: int = 4671800
const APP_ID_PLAYTEST: int = 4652940

const STEAM_SUPPORTER_PACK_ID: int = 4981840
var has_supporter_pack: bool = false

var user_id: int = -1

func _ready() -> void :
	has_steam = OS.has_feature("steam")
	if !has_steam:
		return

	if OS.has_feature("demo"):
		app_id = APP_ID_DEMO
	elif OS.has_feature("playtest"):
		app_id = APP_ID_PLAYTEST
	else:
		app_id = APP_ID_MAIN

	initialize()

func _process(_delta: float) -> void :
	Steam.run_callbacks()

func initialize() -> void :
	var result: = Steam.steamInitEx(app_id)
	print("Steam-Init result: %s" % str(result))

	if result["status"] == 0:
		user_id = Steam.getSteamID()
		steam_initialized = true
		has_supporter_pack = Steam.isDLCInstalled(STEAM_SUPPORTER_PACK_ID)
		print("Steam ID: %d" % user_id)
		print("Has Supporter Pack: %s" % has_supporter_pack)
		initialized.emit()
	else:
		OS.alert(tr("Steam initialization failed. Make sure Steam is running and that you own the game."), tr("Error"))
		get_tree().quit()

func open_link_in_overlay(link: String) -> void :
	if has_steam:
		Steam.activateGameOverlayToWebPage(link)
	else:
		OS.shell_open(link)

func wishlist(call_location: String, extra: String = "") -> void :
	var link_format: String = "https://store.steampowered.com/app/4594150?utm_source=game&utm_campaign=%s"
	var link: String = link_format % [call_location]
	if !extra.is_empty():
		link += "&utm_content=" + extra
	open_link_in_overlay(link)
