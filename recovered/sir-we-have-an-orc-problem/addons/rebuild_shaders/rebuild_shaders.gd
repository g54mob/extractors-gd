@tool
extends EditorPlugin

const MENU_ITEM_NAME: String = "Rebuild Shaders"

func _enter_tree():
	var button: = Button.new()
	add_tool_menu_item(MENU_ITEM_NAME, _on_rebuild_button_pressed)

func _exit_tree() -> void :
	remove_tool_menu_item(MENU_ITEM_NAME)

func _add_from_directory(dir_path: String, shader_files: PackedStringArray) -> void :
	var dir_access: DirAccess = DirAccess.open(dir_path)
	for file: String in dir_access.get_files():
		if file.ends_with(".glsl"):
			shader_files.append(dir_path + "/" + file)
	for dir: String in dir_access.get_directories():
		_add_from_directory(dir_path + "/" + dir, shader_files)

func _on_rebuild_button_pressed() -> void :
	var shader_files: = PackedStringArray()
	_add_from_directory("res://shaders", shader_files)

	print("Found %d shader files:" % shader_files.size())
	for shader_file: String in shader_files:
		print(shader_file)
	var fs: = EditorInterface.get_resource_filesystem()
	fs.reimport_files(shader_files)
