extends Node
## Global settings manager for the Treasure game.
##
## Handles saving and loading game settings, especially audio settings.

# Audio bus indices
const MASTER_BUS_IDX: int = 0
const MUSIC_BUS_IDX: int = 1
const SFX_BUS_IDX: int = 2

# Configuration file
const CONFIG_FILE_PATH: String = "user://settings.cfg"

# Default values
var default_settings = {
	"audio": {
		"master_volume": -10.0,
		"music_volume": -15.0,
		"sfx_volume": -5.0
	}
}

func _ready() -> void:
	# Load settings on game start
	load_settings()

## Save all current settings to the config file
func save_settings() -> void:
	var config = ConfigFile.new()

	# Store audio settings
	config.set_value("audio", "master_volume", AudioServer.get_bus_volume_db(MASTER_BUS_IDX))
	config.set_value("audio", "music_volume", AudioServer.get_bus_volume_db(MUSIC_BUS_IDX))
	config.set_value("audio", "sfx_volume", AudioServer.get_bus_volume_db(SFX_BUS_IDX))

	# Save the file
	var err = config.save(CONFIG_FILE_PATH)
	if err != OK:
		push_error("Failed to save settings to %s" % CONFIG_FILE_PATH)

## Load settings from the config file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)

	if err != OK:
		print("No settings file found, using defaults")
		apply_default_settings()
		return

	# Get volume settings with defaults as fallback
	var master_vol = config.get_value("audio", "master_volume", default_settings.audio.master_volume)
	var music_vol = config.get_value("audio", "music_volume", default_settings.audio.music_volume)
	var sfx_vol = config.get_value("audio", "sfx_volume", default_settings.audio.sfx_volume)

	# Apply loaded settings
	set_volume(MASTER_BUS_IDX, master_vol)
	set_volume(MUSIC_BUS_IDX, music_vol)
	set_volume(SFX_BUS_IDX, sfx_vol)

## Apply default settings
func apply_default_settings() -> void:
	set_volume(MASTER_BUS_IDX, default_settings.audio.master_volume)
	set_volume(MUSIC_BUS_IDX, default_settings.audio.music_volume)
	set_volume(SFX_BUS_IDX, default_settings.audio.sfx_volume)

## Set volume for a specific audio bus
func set_volume(bus_idx: int, volume_db: float) -> void:
	if bus_idx >= AudioServer.get_bus_count():
		while AudioServer.get_bus_count() <= bus_idx:
			AudioServer.add_bus()
			
		if bus_idx == MUSIC_BUS_IDX:
			AudioServer.set_bus_name(MUSIC_BUS_IDX, "Music")
		elif bus_idx == SFX_BUS_IDX:
			AudioServer.set_bus_name(SFX_BUS_IDX, "SFX")
 
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	AudioServer.set_bus_mute(bus_idx, volume_db <= -30)

## Get current volume for a specific audio bus
func get_volume(bus_idx: int) -> float:
	return AudioServer.get_bus_volume_db(bus_idx)
