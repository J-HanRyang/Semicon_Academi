### 1. UART = B_Tick_Gen + UART_Rx + UART_Tx
- **B_Tick_Gen** : This module generates a 9600Hz Baud Rate Tick signal for the UART protocol by dividing the input clock signal.
- **UART_Rx** : This module starts receiving data when it detects a start bit (a logic 0).
- **UART_Tx** : This module outputs a start bit (a logic 0), sends 8 data bits, and then outputs a stop bit (a logic 1) to complete a transmission.

### 2. FIFO = FIFO_Ctrl + Register_File
- **FIFO_Ctrl** : This module uses Write_Pointer and Read_Pointer to store and read data from memory.
- **Register_File** : A memory that temporarily stores data.

#### Referenced Document
Please find the project details and diagrams in the uploaded PDF file.
[Docs](https://github.com/J-HanRyang/Semicon_Academi/tree/main/FPGA_Digital_Clock%20With%202%20Sensors/UART_FIFO/Docs)
