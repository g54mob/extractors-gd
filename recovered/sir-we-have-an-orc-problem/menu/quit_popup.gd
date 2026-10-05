extends Control


func _on_back_button_pressed() -> void :
	queue_free()


func _on_wishlist_button_pressed() -> void :
	Steamy.wishlist("quit_popup")


func _on_quit_button_pressed() -> void :
	get_tree().quit()
