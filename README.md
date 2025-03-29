# Treasure

A maze adventure game where you collect treasures while avoiding monsters.
This project is a port of the original game created in GameMaker 8.1 to Godot 4.4.

![Treasure Game Screenshot](screenshots/gameplay.png)

## Description

In Treasure, you control an explorer navigating through various maze-like levels. Your goal is to collect all the treasures while avoiding or outsmarting the monsters that patrol the levels.

## Features

- Grid-based movement system
- Multiple levels with increasing difficulty
- Monsters with different AI behaviors
- Collectible treasures and power-ups
- Score tracking and life system

## Prerequisites

- [Godot 4.4](https://godotengine.org/download) or higher

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/liberodark/treasure.git
   ```

2. Open Godot Engine and import the project:
   - Click "Import"
   - Navigate to the cloned project folder
   - Select the `project.godot` file
   - Click "Import & Edit"

## How to Play

- Use the arrow keys to move the explorer
- Collect all treasures to complete a level
- Avoid monsters or use special items to defeat them
- Complete all levels to win the game

## Controls

- **Arrow Keys**: Move the explorer
- **Esc**: Pause the game

## Project Structure

```
treasure/
├── assets/               # Game assets
│   ├── sprites/          # Graphics and sprites
│   └── sounds/           # Audio files
├── scenes/               # Game scenes
│   ├── actors/           # Player and enemy scenes
│   ├── levels/           # Game levels
│   ├── objects/          # Interactive objects
│   └── ui/               # User interface elements
├── scripts/              # GDScript code files
└── .godot/               # Godot project configuration (not versioned)
```

## Development

This project is a port of a GameMaker 8.1 game to the Godot 4 engine. The conversion process involved:

1. Recreating all assets and sprites
2. Implementing the grid-based movement system
3. Converting GameMaker Language (GML) to GDScript
4. Adapting the original gameplay mechanics to Godot's architecture

For developers looking to modify or extend this game:

- The core gameplay logic is in the `player.gd` and `monster.gd` scripts
- Level design is handled through TileMap nodes in the level scenes
- Game management (scores, lives, level transitions) is in the `game_manager.gd` script

## Contributing

Contributions are welcome! If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

- Original GameMaker version by liberodark & [#Ŧeяŕørist#]
- Godot port by liberodark
- Original art assets by [#Ŧeяŕørist#]
