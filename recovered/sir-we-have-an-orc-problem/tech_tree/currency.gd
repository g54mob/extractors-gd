class_name Currency

enum Type{
	UPGRADE_MARKS, 
	LEVEL_FINISHED, 
	ALL_KILLED_CHALLENGE
}

const COLORS: Dictionary[Type, Color] = {
	Type.UPGRADE_MARKS: Color(0.144, 0.452, 0.79, 1.0), 
	Type.LEVEL_FINISHED: Color(0.781, 0.231, 0.026, 1.0), 
	Type.ALL_KILLED_CHALLENGE: Color(0.729, 0.004, 0.42, 1.0), 
}


static var ICONS: Dictionary[Type, Texture2D] = {
	Type.UPGRADE_MARKS: load("res://tech_tree/hud/upgrade_mark.png"), 
	Type.LEVEL_FINISHED: load("res://tech_tree/hud/level_finished_mark.png"), 
	Type.ALL_KILLED_CHALLENGE: load("res://tech_tree/hud/all_killed_mark.png"), 
}
