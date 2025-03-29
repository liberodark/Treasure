class_name PauseMenu
extends CanvasLayer
## Pause menu for the Treasure game
##
## Displays when the player presses Escape during gameplay and
## allows pausing, accessing settings, or quitting the level.

signal resume_requested
signal main_menu_requested

# Constants for audio buses
const MASTER_BUS_IDX: int = 0
const MUSIC_BUS_IDX: int = 1
const SFX_BUS_IDX: int = 2

# Node references
@onready var pause_panel = $PausePanel
@onready var settings_panel = $SettingsPanel
@onready var confirm_dialog = $ConfirmDialog

@onready var resume_button = $PausePanel/VBoxContainer/ButtonsContainer/ResumeButton
@onready var settings_button = $PausePanel/VBoxContainer/ButtonsContainer/SettingsButton
@onready var main_menu_button = $PausePanel/VBoxContainer/ButtonsContainer/MainMenuButton
@onready var back_button = $SettingsPanel/VBoxContainer/BackButton
@onready var cancel_button = $ConfirmDialog/VBoxContainer/ButtonsContainer/CancelButton
@onready var confirm_button = $ConfirmDialog/VBoxContainer/ButtonsContainer/ConfirmButton

@onready var master_volume_slider = $SettingsPanel/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider = $SettingsPanel/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $SettingsPanel/VBoxContainer/SFXVolumeSlider

func _ready():
	# Enable focus for controller navigation
	resume_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	main_menu_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL
	cancel_button.focus_mode = Control.FOCUS_ALL
	confirm_button.focus_mode = Control.FOCUS_ALL
	
	master_volume_slider.focus_mode = Control.FOCUS_ALL
	music_volume_slider.focus_mode = Control.FOCUS_ALL
	sfx_volume_slider.focus_mode = Control.FOCUS_ALL
	
	# Connect signals for buttons
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	# Connect signals for volume sliders
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Initialize sliders with current values
	_initialize_volume_sliders()
	
	# Hide menu at start
	hide()
	
	print("PauseMenu initialized and ready")

## Initialize volume sliders with current values
func _initialize_volume_sliders():
	if has_node("/root/SettingsManager"):
		master_volume_slider.value = SettingsManager.get_volume(MASTER_BUS_IDX)
		music_volume_slider.value = SettingsManager.get_volume(MUSIC_BUS_IDX)
		sfx_volume_slider.value = SettingsManager.get_volume(SFX_BUS_IDX)
	else:
		master_volume_slider.value = AudioServer.get_bus_volume_db(MASTER_BUS_IDX)
		music_volume_slider.value = AudioServer.get_bus_volume_db(MUSIC_BUS_IDX)
		sfx_volume_slider.value = AudioServer.get_bus_volume_db(SFX_BUS_IDX)

## Show the pause menu
func show_menu():
	pause_panel.visible = true
	settings_panel.visible = false
	confirm_dialog.visible = false
	show()
	
	# Set focus to the resume button
	resume_button.grab_focus()

## Hide the pause menu
func hide_menu():
	hide()

## Handler for Resume button
func _on_resume_button_pressed():
	resume_requested.emit()

## Handler for Settings button
func _on_settings_button_pressed():
	pause_panel.visible = false
	settings_panel.visible = true
	
	# Focus the first slider
	master_volume_slider.grab_focus()

## Handler for Main Menu button
func _on_main_menu_button_pressed():
	pause_panel.visible = false
	confirm_dialog.visible = true
	
	# Focus the cancel button
	cancel_button.grab_focus()

## Handler for Back button in settings
func _on_back_button_pressed():
	settings_panel.visible = false
	pause_panel.visible = true
	
	# Save settings
	if has_node("/root/SettingsManager"):
		SettingsManager.save_settings()
	
	# Focus the settings button
	settings_button.grab_focus()

## Handler for Cancel button in dialog box
func _on_cancel_button_pressed():
	confirm_dialog.visible = false
	pause_panel.visible = true
	
	# Focus the main menu button
	main_menu_button.grab_focus()

## Handler for Confirm button in dialog box
func _on_confirm_button_pressed():
	main_menu_requested.emit()

## Handler for master volume change
func _on_master_volume_changed(value):
	if has_node("/root/SettingsManager"):
		SettingsManager.set_volume(MASTER_BUS_IDX, value)
	else:
		AudioServer.set_bus_volume_db(MASTER_BUS_IDX, value)
		AudioServer.set_bus_mute(MASTER_BUS_IDX, value <= -30)

## Handler for music volume change
func _on_music_volume_changed(value):
	if has_node("/root/SettingsManager"):
		SettingsManager.set_volume(MUSIC_BUS_IDX, value)
	else:
		AudioServer.set_bus_volume_db(MUSIC_BUS_IDX, value)
		AudioServer.set_bus_mute(MUSIC_BUS_IDX, value <= -30)

## Handler for sfx volume change
func _on_sfx_volume_changed(value):
	if has_node("/root/SettingsManager"):
		SettingsManager.set_volume(SFX_BUS_IDX, value)
	else:
		AudioServer.set_bus_volume_db(SFX_BUS_IDX, value)
		AudioServer.set_bus_mute(SFX_BUS_IDX, value <= -30)

## Input handler to capture Escape key and controller buttons
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		if settings_panel.visible:
			_on_back_button_pressed()
		elif confirm_dialog.visible:
			_on_cancel_button_pressed()
		else:
			resume_requested.emit()
		get_viewport().set_input_as_handled()
