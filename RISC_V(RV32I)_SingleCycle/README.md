# Semicon Academi CPU Project : **RISC_V(RV32I) - Single Cycle**
## Project Summary
This project is a 32bit single cycle CPU core based on the RISC-V Instruction Set Architecture, implemented in SystemVerilog. <br>
The main goal is to understand computer architecture by incrementally designing a processor that supports the full RV32I base integer instruction set, from R-Type through J-Type.

<br>

### ⚡ Key Features
- **Single-Cycle Architecture :** A simple design where every instruction completes in a single clock cycle.
- **Full RV32I Base ISA Support :** Implements all standard R, S, I, B, U and J-Type instructions.
- **Modular Hierarchical Design :** A clean, organized structure with a clear separation between the Control Unit, DataPath, and Memory Modules
- **Incremental Development :** The design was built progressively, starting with R-Type and expanding to S, I, B, U, and J-Types, solidifying the design process at each stage.

<br>

### 🖥️ System Architecture
The CPU utilizes a single-cycle architecture where the five stages of instruction processing (Fetch, Decode, Execute, Memory, and Writeback) are completed within one cycle. <br>
The core is composed of a Control Unit and a DataPath, which interface with an external Instruction ROM and Data RAM. 

<br>

<img width="1252" height="903" alt="image" src="https://github.com/user-attachments/assets/37b4f6b3-5b40-4832-b878-cd77d8fb0ff3" />

***A block diagram of the final single-cycle CPU supporting all RV32I base instructions.***

**Study design for each module** <br>
[Study](https://github.com/J-HanRyang/System_Verilog/tree/main/RV32I)


<br>

### 🛠 Development Environment 
- **Language :** SystemVerilog
- **EDA Tool :** Vivado

<br>

#### 📜 Referenced Document
Please find the project details and diagrams in the uploaded PDF file. <br>
[Docs](https://github.com/J-HanRyang/Semicon_Academi/tree/main/RISC_V(RV32I)_SingleCycle/Docs)
