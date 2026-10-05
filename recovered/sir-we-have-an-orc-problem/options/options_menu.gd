extends Control

@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var language_option_button: OptionButton = %LanguageOptionButton

var locales: PackedStringArray = ["en"]

func _ready() -> void :

	language_option_button.get_popup().force_native = true

	locales.append_array(TranslationServer.get_loaded_locales())
	language_option_button.add_item("English")
	language_option_button.add_item("Deutsch")
	language_option_button.add_item("Español")
	language_option_button.add_item("Français")
	language_option_button.add_item("Italiano")
	language_option_button.add_item("日本語")
	language_option_button.add_item("한국어")
	language_option_button.add_item("Nederlands")
	language_option_button.add_item("Polski")
	language_option_button.add_item("Português Brasileiro")
	language_option_button.add_item("русский")
	language_option_button.add_item("简体中文")
	language_option_button.add_item("繁體中文")
	language_option_button.selected = locales.find(TranslationServer.get_locale())

	sfx_slider.value = AudioManager.sfx_volume
	music_slider.value = AudioManager.music_volume

	%FullscreenCheckBox.set_pressed_no_signal(Options.fullscreen)
	%CRTCheckBox.set_pressed_no_signal(Options.crt_effect_enabled)
	%EdgeScrollingCheckBox.set_pressed_no_signal(Options.edge_scrolling)

	%SupporterPackInfo.visible = !GameManager.has_supporter_pack
	%BlueFlamesCheckbox.disabled = !GameManager.has_supporter_pack
	%SpaceOrcsCheckbox.disabled = !GameManager.has_supporter_pack
	%SpaceBackgroundCheckbox.disabled = !GameManager.has_supporter_pack
	if GameManager.has_supporter_pack:
		%BlueFlamesCheckbox.set_pressed_no_signal(Options.supporter_flames_enabled)
		%SpaceOrcsCheckbox.set_pressed_no_signal(Options.supporter_orcs_enabled)
		%SpaceBackgroundCheckbox.set_pressed_no_signal(Options.supporter_background_enabled)

func _on_back_pressed() -> void :
	SaveSystem.save_user_data()
	queue_free()

func _on_fullscreen_check_box_toggled(toggled_on: bool) -> void :
	Options.fullscreen = toggled_on

func _on_crt_check_box_toggled(toggled_on: bool) -> void :
	Options.crt_effect_enabled = toggled_on

func _on_edge_scrolling_check_box_toggled(toggled_on: bool) -> void :
	Options.edge_scrolling = toggled_on

func _on_sfx_slider_value_changed(value: float) -> void :
	AudioManager.sfx_volume = value

func _on_music_slider_value_changed(value: float) -> void :
	AudioManager.music_volume = value

func _on_language_option_button_item_selected(index: int) -> void :
	var locale: String = locales[index]
	Options.set_locale(locale)

func _on_blue_flames_checkbox_toggled(toggled_on: bool) -> void :
	Options.supporter_flames_enabled = toggled_on

func _on_space_orcs_checkbox_toggled(toggled_on: bool) -> void :
	Options.supporter_orcs_enabled = toggled_on

func _on_space_background_checkbox_toggled(toggled_on: bool) -> void :
	Options.supporter_background_enabled = toggled_on

func _on_supporter_pack_info_meta_clicked(_meta: Variant) -> void :
	Steamy.open_link_in_overlay("https://store.steampowered.com/app/4981840")
