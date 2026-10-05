extends CanvasLayer


func _ready() -> void :
	var format_dict: Dictionary = {
		"MOUSE_LEFT": "[img=center,center,height=48]res://tech_tree/hud/left_click.png[/img]", 
		"MISSILE": "[img=center,center,height=48]res://abilities/missile/missile.png[/img]", 
		"KEY_SPACE": "[img=center,center,height=112]res://tech_tree/hud/key_space.png[/img]", 
		"GUNNER": "[img=center,center,width=48]res://towers/gunner/gunner.png[/img]", 
		"KEY_ONE": "[img=center,center,width=48]res://tech_tree/hud/key_1.png[/img]"
	}
	%Label.text = tr( %Label.text).format(format_dict)
