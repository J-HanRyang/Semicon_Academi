# Game_Logic Master
<img width="3462" height="1819" alt="image" src="https://github.com/user-attachments/assets/f05b4177-0913-4585-a0ea-725e2b956772" />

## Master Board
- Performs real-time dice recognition using camera input
- Executes game logic via multiple FSMs
- Acts as the I2C Master, transmitting game state data to Slave boards

<br>

### 🎮 Game Logic (Master)
- **GAME_STATE FSM**
  - Controls game start, reset, and round management
- **PLAY_GAME FSM**
  - Calculates player movement using dice results
  - Handles ladders, traps, and finish line logic
- **VICTORY_TRACKER**
  - Determines round wins for best-of-three gameplay
- **TIMER**
  - Manages in-game timing and state-based timing control
 
<br>

### 🎲 Dice Detection & VGA Processing
- **OV7670 Camera Controller**
  - Frame acquisition using HREF/VSYNC signals
- **Red_Check Module**
  - Pixel-level red color detection (R > G, B)
- **Dice_Reader**
  - Counts red pixels per frame and maps count ranges to dice values
- **VGA Display**
  - Renders dice mask, board state, player position, timer, and effects
