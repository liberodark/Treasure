class_name Menu
extends Control
## Main menu for the Treasure game.
##
## Handles game start, settings, and exiting the game.

const MASTER_BUS_IDX: int = 0
const MUSIC_BUS_IDX: int = 1
const SFX_BUS_IDX: int = 2

const CONFIG_FILE_PATH: String = "user://settings.cfg"

@onready var settings_panel: Panel = $SettingsPanel
@onready var play_button: Button = $MenuContainer/PlayButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var exit_button: Button = $MenuContainer/ExitButton
@onready var back_button: Button = $SettingsPanel/VBoxContainer/BackButton
@onready var version_label: Label = $VersionLabel

@onready var master_volume_slider: HSlider = $SettingsPanel/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $SettingsPanel/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $SettingsPanel/VBoxContainer/SFXVolumeSlider

func _ready() -> void:
	_setup_audio_buses()
	
	# Set up UI focus for controller navigation
	play_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	exit_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL
	
	master_volume_slider.focus_mode = Control.FOCUS_ALL
	music_volume_slider.focus_mode = Control.FOCUS_ALL
	sfx_volume_slider.focus_mode = Control.FOCUS_ALL
	
	# Set initial focus
	play_button.grab_focus()
	
	# Connect button signals
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect slider signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Set version label
	var version = ProjectSettings.get_setting("application/config/version")
	version_label.text = "v" + version
	
	# Initialize sliders from SettingsManager if available
	if has_node("/root/SettingsManager"):
		master_volume_slider.value = SettingsManager.get_volume(MASTER_BUS_IDX)
		music_volume_slider.value = SettingsManager.get_volume(MUSIC_BUS_IDX)
		sfx_volume_slider.value = SettingsManager.get_volume(SFX_BUS_IDX)
	else:
		# Fallback to direct loading if SettingsManager isn't available
		_load_settings()

func _setup_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(1, "Music")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(2, "SFX")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_manager.tscn")

func _on_settings_button_pressed() -> void:
	settings_panel.visible = true
	# Set focus to the first slider when opening settings
	master_volume_slider.grab_focus()

func _on_exit_button_pressed() -> void:
	_save_settings()
	get_tree().quit()

func _on_back_button_pressed() -> void:
	_save_settings()
	settings_panel.visible = false
	# Restore focus to the settings button when closing settings
	settings_button.grab_focus()

func _on_master_volume_changed(value: float) -> void:
	if MASTER_BUS_IDX < AudioServer.get_bus_count():
		AudioServer.set_bus_volume_db(MASTER_BUS_IDX, value)
		AudioServer.set_bus_mute(MASTER_BUS_IDX, value <= -30)

func _on_music_volume_changed(value: float) -> void:
	if MUSIC_BUS_IDX < AudioServer.get_bus_count():
		AudioServer.set_bus_volume_db(MUSIC_BUS_IDX, value)
		AudioServer.set_bus_mute(MUSIC_BUS_IDX, value <= -30)

func _on_sfx_volume_changed(value: float) -> void:
	if SFX_BUS_IDX < AudioServer.get_bus_count():
		AudioServer.set_bus_volume_db(SFX_BUS_IDX, value)
		AudioServer.set_bus_mute(SFX_BUS_IDX, value <= -30)

func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume", music_volume_slider.value)
	config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	
	var err = config.save(CONFIG_FILE_PATH)
	if err != OK:
		push_error("Failed to save settings to %s" % CONFIG_FILE_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	
	if err != OK:
		master_volume_slider.value = -10
		music_volume_slider.value = -15
		sfx_volume_slider.value = -5
		return
	
	master_volume_slider.value = config.get_value("audio", "master_volume", -10)
	music_volume_slider.value = config.get_value("audio", "music_volume", -15)
	sfx_volume_slider.value = config.get_value("audio", "sfx_volume", -5)
	
	if MASTER_BUS_IDX < AudioServer.get_bus_count():
		_on_master_volume_changed(master_volume_slider.value)
	
	if MUSIC_BUS_IDX < AudioServer.get_bus_count():
		_on_music_volume_changed(music_volume_slider.value)
	
	if SFX_BUS_IDX < AudioServer.get_bus_count():
		_on_sfx_volume_changed(sfx_volume_slider.value)

## Handle input for controller navigation
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()
