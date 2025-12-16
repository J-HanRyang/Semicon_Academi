# FPGA Real-Time Dice Board Game Based on I2C & VGA
## Team
- **Jiyun Han** : Player Movement / Visual Filter / I2C Slave / Top Integration
- **Gwak** : Team Leader / Game_Logic / I2C Master / SCCB
- **Hwang** : Dice Detector / VGA Display / Presentation
- **Jin** : Back Ground Text / Video 

<br>

## Project Summary
This project implements a real-time FPGA-based dice board game system using a Master–Slave architecture. <br>
A live video stream from an OV7670 camera is used to detect dice values by identifying red pixels, <br>
and the detected results drive the game logic.

Game states and events are synchronized across multiple FPGA boards using I2C communication, <br>
while the game status is visualized in real time through VGA output with dynamic visual effects.
<br>

### ⚡ Key Features
- **Real-Time Dice Recognition** : Dice value detection using red pixel analysis from OV7670 camera input
- **Game Logic Implementation** : Player movement, ladder/trap handling, and best-of-three game rules
- **Master/Multi-Slave Architecture** : I2C-based communication for game state synchronization
- **Real-Time Visual Effects** : State-dependent VGA filters (Gray, Mosaic, Golden, etc.)
- **VGA Display System** : Board status, dice value, player position, turn, and timer visualization
<br>

### 🛠 Development Environment
- **EDA Tool**   : Vivado 2020.2
- **Language**   : SystemVerilog
- **FPGA Board** : Digilent Basys 3
- **Camera**     : OV7670
- **Interface**  : I2C Protocol
<br>


#### 📜 *Referenced Document*
Please find the project details and diagrams in the uploaded PDF file. <br>
[Docs Project](https://github.com/J-HanRyang/Semicon_Academi/tree/main/FPGA%20Real-Time%20Dice%20Board%20Game%20Based%20on%20I2C%20%26%20VGA/Docs)
