# Semicon Academi Python Autumation Project : **IRIS**
## Project Summary
This project is a 32bit single cycle CPU core based on the RISC-V Instruction Set Architecture, implemented in SystemVerilog. <br>
The main goal is to understanding computer architecture by incrementally designing a processor that supports the full RV32I base integer instruction set, from R-Type through J-Type.

<br>

### ⚡ Key Features
- **Single-Cycle Architecture :** A simple design where every instruction completes in a single clock cycle.
- **Full RV32I Base ISA Suppot :** Implements all standard R, S, I, B, U and J-Type instructions.
- **Modular Hierarchical Design :** A clean, organized structure with a clear separation between to Control Unit, DataPath, and Memory Modules
- **Incremental Development :** The design was built progerssively, starting with R-Type and expanding to S, I, B, U, and J-Types, soildifying the design process at each stage.

<br>

### 🖥️ System Architecture
The CPU untillizes a single-cycle architecture where the five stages of instruction processing (Fetch, Decode, Execute, Memory, and WriteBack) are completed whitin one cycle. <br>
The core is composed of a Control Unit and a DataPath, which interface with an external Instruction ROM and Data RAM. <br>
<img width="1252" height="903" alt="image" src="https://github.com/user-attachments/assets/37b4f6b3-5b40-4832-b878-cd77d8fb0ff3" />
***A block diagram of the final single-cycle CPU supporting all RV32I base instructions.***


<br>

### 🛠 Development Environment 
- **Language :** SystemVerilog
- **EDA Tool :** Vivado

<br>

#### 📜 Referenced Document
Please find the project details and diagrams in the uploaded PDF file.
[Docs]()
