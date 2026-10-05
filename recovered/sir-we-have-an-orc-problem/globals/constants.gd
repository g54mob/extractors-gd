@abstract
class_name Constants


const TECH_TREE_SCENE_PATH: = "res://tech_tree/tech_tree.tscn"
const BATTLE_SCENE_PATH: = "res://battle/battle.tscn"


const STARTING_UPGRADE_NAME: = &"gunner_unlock"
static var upgrade_tooltip_scene: PackedScene = null
const TECH_TREE_NODE_Z_INDEX: = 5
static var tower_stats_label_scene: PackedScene = null


static var music: AudioStream
const TOWER_AUDIO_RADIUS: = 150
static var gun_sound: AudioStream
static var gun_sound_10_rps: AudioStream
static var explosion_sound: AudioStream
static var machine_gun_sound: AudioStream
static var wrong_sound: AudioStream
static var missile_swoosh: AudioStream
static var new_game_boom: AudioStream
static var strafing_run_explosions_sound: AudioStream
static var bells_of_doom_sound: AudioStream
static var nuke_explosion_sound: AudioStream
static var nuke_ready_sound: AudioStream
static var cannon_sound: AudioStream
static var grenade_launcher_sound: AudioStream


static var mortar_shell_scene: PackedScene
static var grenade_scene: PackedScene
static var explosion_sprite_scene: PackedScene
static var strafing_run_plane_scene: PackedScene
static var missile_target_scene: PackedScene
static var nuke_target_scene: PackedScene


const TARGET_MIN_DISTANCE: = 20
const TARGET_MAX_DISTANCE: = 100

static func initialize() -> void :
	upgrade_tooltip_scene = load("res://tech_tree/tooltips/upgrade_tooltip.tscn")
	tower_stats_label_scene = load("res://tech_tree/hud/tower_stats/tower_stats_label.tscn")

	music = load("res://audio/music/nashman05.mp3")
	gun_sound = load("res://audio/sounds/gun.wav")
	gun_sound_10_rps = load("res://towers/gunner/gun_10_rps.wav")
	explosion_sound = load("res://audio/sounds/explosion.wav")
	machine_gun_sound = load("res://audio/sounds/machine_gun.wav")
	wrong_sound = load("res://audio/sounds/wrong.wav")
	missile_swoosh = load("res://abilities/missile/missile_launch.wav")
	new_game_boom = load("res://audio/sounds/cinematic_boom.mp3")
	strafing_run_explosions_sound = load("res://abilities/strafing_run/strafing_run_explosions.wav")
	bells_of_doom_sound = load("res://abilities/nuke/bells_of_doom.wav")
	nuke_explosion_sound = load("res://abilities/nuke/distant-fiery-explosion.wav")
	nuke_ready_sound = load("res://abilities/nuke/nuke_ready.wav")
	cannon_sound = load("res://audio/sounds/heavy_gun.wav")
	grenade_launcher_sound = load("res://towers/grenade_launcher/grenade_shot.wav")

	mortar_shell_scene = load("res://towers/mortar/mortar_shell.tscn")
	grenade_scene = load("res://towers/grenade_launcher/grenade.tscn")
	explosion_sprite_scene = load("res://battle/explosion_sprite.tscn")
	strafing_run_plane_scene = load("res://abilities/strafing_run/strafing_run_plane.tscn")
	missile_target_scene = load("res://abilities/missile/missile_target.tscn")
	nuke_target_scene = load("res://abilities/nuke/nuke_target.tscn")

const DAMAGE_REPORT_ID_GUNNER: int = 0
const DAMAGE_REPORT_ID_CANNON: int = 1
const DAMAGE_REPORT_ID_MORTAR: int = 2
const DAMAGE_REPORT_ID_FLAMETHROWER: int = 3
const DAMAGE_REPORT_ID_TESLA_COIL: int = 4
const DAMAGE_REPORT_ID_GRENADE_LAUNCHER: int = 5
const DAMAGE_REPORT_ID_LASER: int = 6

const DAMAGE_REPORT_ID_MISSILE: int = 16
const DAMAGE_REPORT_ID_STRAFING_RUN: int = 17
const DAMAGE_REPORT_ID_NUKE: int = 18
const DAMAGE_REPORT_ID_CRYO_BEAM: int = 19

const DAMAGE_REPORT_ID_EXPLODING_ORCS: int = 24
