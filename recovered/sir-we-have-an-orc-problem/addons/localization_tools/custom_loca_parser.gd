@tool
class_name CustomLocaParser extends EditorTranslationParserPlugin

func _parse_file(path: String) -> Array[PackedStringArray]:

	var res: Variant = load(path)
	if not res: return []

	var msgids: Array[PackedStringArray] = []

	if res is UpgradeData:
		var data: UpgradeData = res
		msgids.append(PackedStringArray([data.name]))
		msgids.append(PackedStringArray([data.description]))

	return msgids


func _get_recognized_extensions():
	return ["tres"]
