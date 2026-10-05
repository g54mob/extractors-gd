@tool
extends EditorPlugin


const LOCA_PATH: = "res://localization"


var menu: = PopupMenu.new()
var create_po_dialog: ConfirmationDialog = null
var custom_parser: CustomLocaParser = null


func _enter_tree():
	menu.name = "Localization"
	menu.add_item("Create PO Files", 0)
	menu.add_item("Update From POT", 1)
	menu.add_item("Convert To MO", 2)
	menu.add_item("Convert To CSV", 3)
	menu.add_item("Convert To XLSX", 4)
	menu.add_item("Convert CSV To PO", 5)
	menu.id_pressed.connect(on_id_pressed)
	add_tool_submenu_item("Localization", menu)

	init_po_dialog()


	custom_parser = CustomLocaParser.new()
	add_translation_parser_plugin(custom_parser)


const STANDARD_LANGUAGES: = ["de", "es", "fr", "it", "ja", "ko", "nl", "pl", "pt_BR", "ru", "zh_CN", "zh_TW"]
func init_po_dialog() -> void :
	create_po_dialog = ConfirmationDialog.new()
	create_po_dialog.title = "Create PO Files"
	create_po_dialog.popup_centered()

	var vbox: = VBoxContainer.new()

	for l: String in STANDARD_LANGUAGES:
		var cb: = CheckBox.new()
		cb.text = l
		vbox.add_child(cb)

	create_po_dialog.add_child(vbox)

	create_po_dialog.confirmed.connect( func() -> void :
		var selected: Array[String] = []
		for cb: CheckBox in vbox.get_children():
			if cb.button_pressed:
				selected.append(cb.text)
		create_po_files(selected)
	)

	EditorInterface.get_base_control().add_child(create_po_dialog)


func _exit_tree() -> void :
	remove_translation_parser_plugin(custom_parser)

	if create_po_dialog:
		create_po_dialog.queue_free()

	remove_tool_menu_item("Localization")


func on_id_pressed(id: int) -> void :
	match id:
		0: show_create_po_dialog()
		1: update_po_files_from_pot()
		2: convert_po_files_to_mo()
		3: convert_to_csv()
		4: convert_to_xlsx()
		5: convert_csv_to_po()


func show_create_po_dialog() -> void :
	create_po_dialog.popup_centered()


func create_po_files(languages: Array[String]) -> void :
	if !DirAccess.dir_exists_absolute(LOCA_PATH):
		DirAccess.make_dir_absolute(LOCA_PATH)

	for l: String in languages:
		var path: = LOCA_PATH + "/" + l + ".po"
		if FileAccess.file_exists(path):
			continue
		var f: = FileAccess.open(path, FileAccess.WRITE)
		f.store_line("msgid \"\"")
		f.store_line("msgstr \"\"")
		f.store_line("\"Language: %s\\n\"" % l)
		f.store_line("\"Content-Type: text/plain; charset=UTF-8\\n\"")


func update_po_files_from_pot() -> void :
	var loca_dir: = DirAccess.open(LOCA_PATH)
	if loca_dir == null:
		push_error(loca_dir, "Expected path \"%s\", but it does not exist." % LOCA_PATH)
		return

	var pot: = ""
	var po_files: Array[String] = []

	loca_dir.list_dir_begin()
	while true:
		var file_name = loca_dir.get_next()
		if file_name == "":
			break

		if loca_dir.current_is_dir():
			push_warning("Found directory \"%s\", but will not look into it." % file_name)
			continue

		if file_name.get_extension() == "pot":
			if !pot.is_empty():
				push_warning("Second POT file found (\"%s\"). Will stick to \"%s\"" % [file_name, pot])
				continue

			pot = file_name

		elif file_name.get_extension() == "po":
			po_files.append(file_name)
	loca_dir.list_dir_end()

	if po_files.is_empty():
		print("No PO files found.")
		return

	var abs_loca_path: = ProjectSettings.globalize_path(LOCA_PATH)
	for f: String in po_files:
		print("Updating file: %s" % f)
		var output: = []
		var exit_code = OS.execute(
			"msgmerge", 
			[
				"--update", 
				"--backup=none", 
				"--no-wrap", 
				"--no-fuzzy-matching", 
				abs_loca_path + "/" + f, 
				abs_loca_path + "/" + pot
			], 
			output, 
			true
		)
		for line in output:
			print(line)


func convert_po_files_to_mo() -> void :
	var loca_dir: = DirAccess.open(LOCA_PATH)
	if loca_dir == null:
		push_error(loca_dir, "Expected path \"%s\", but it does not exist." % LOCA_PATH)
		return

	var abs_loca_path: = ProjectSettings.globalize_path(LOCA_PATH)

	loca_dir.list_dir_begin()
	while true:
		var file_name = loca_dir.get_next()
		if file_name == "":
			break

		if loca_dir.current_is_dir():

			continue

		if file_name.get_extension() != "po":
			continue

		print("Converting file: %s" % file_name)
		var output: = []
		var exit_code = OS.execute(
			"msgfmt", 
			[
				"--no-hash", 
				abs_loca_path + "/" + file_name, 
				"-o", 
				abs_loca_path + "/" + file_name.get_basename() + ".mo"
			], 
			output, 
			true
		)
		for line in output:
			print(line)
	loca_dir.list_dir_end()


func convert_to_csv() -> void :
	var loca_dir: = DirAccess.open(LOCA_PATH)
	if loca_dir == null:
		push_error(loca_dir, "Expected path \"%s\", but it does not exist." % LOCA_PATH)
		return

	var abs_loca_path: = ProjectSettings.globalize_path(LOCA_PATH)
	var abs_loca_wörk_path: = abs_loca_path + "/loca_wörk/"

	var loca_wörk_dir: = DirAccess.open(abs_loca_wörk_path)
	if loca_wörk_dir == null:
		push_error(loca_wörk_dir, "Expected path \"%s\", but it does not exist." % abs_loca_wörk_path)
		return

	var output: = []
	var exit_code: = OS.execute(
		"po2csv", 
		[
			abs_loca_path, 
			abs_loca_wörk_path
		], 
		output, 
		true
	)
	for line: String in output:
		print(line)


func convert_to_xlsx() -> void :
	var loca_dir: = DirAccess.open(LOCA_PATH)
	if loca_dir == null:
		push_error(loca_dir, "Expected path \"%s\", but it does not exist." % LOCA_PATH)
		return

	var abs_loca_path: = ProjectSettings.globalize_path(LOCA_PATH)
	var abs_loca_wörk_path: = abs_loca_path + "/loca_wörk/"

	var arguments: PackedStringArray = ["-o", abs_loca_wörk_path + "texts.xlsx"]

	loca_dir.list_dir_begin()
	while true:
		var file_name = loca_dir.get_next()
		if file_name == "":
			break

		if loca_dir.current_is_dir():

			continue

		if file_name.get_extension() == "po":
			arguments.append(abs_loca_path + "/" + file_name)

	var output: = []
	print("Executing: %s" % arguments)
	var exit_code = OS.execute(
		"po2xls", 
		arguments, 
		output, 
		true
	)
	for line in output:
		print(line)
	loca_dir.list_dir_end()


func convert_csv_to_po() -> void :
	var loca_dir: = DirAccess.open(LOCA_PATH)
	if loca_dir == null:
		push_error(loca_dir, "Expected path \"%s\", but it does not exist." % LOCA_PATH)
		return

	var loca_wörk_dir: = DirAccess.open(LOCA_PATH + "/loca_wörk/")
	if loca_wörk_dir == null:
		push_error(loca_wörk_dir, "Expected path \"%s\", but it does not exist." % (LOCA_PATH + "/loca_wörk/"))
		return

	var abs_loca_path: = ProjectSettings.globalize_path(LOCA_PATH)
	var abs_loca_wörk_path: = abs_loca_path + "/loca_wörk/"









	loca_wörk_dir.list_dir_begin()
	while true:
		var file_name = loca_wörk_dir.get_next()
		if file_name == "":
			break

		if loca_wörk_dir.current_is_dir():

			continue

		if file_name.get_extension() != "csv":
			continue


		var output: = []
		var exit_code = OS.execute(
			"csv2po", 
			[
				abs_loca_wörk_path + file_name, 
				abs_loca_path + "/" + file_name.get_basename() + ".po"
			], 
			output, 
			true
		)
		for line in output:
			print(line)
	loca_wörk_dir.list_dir_end()

	update_po_files_from_pot()
