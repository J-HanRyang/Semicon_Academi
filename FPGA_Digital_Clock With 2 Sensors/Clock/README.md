### 1. Clock = Clock_Ctrl + Clock DP
  - **Clock_Ctrl** : Controls the clock's state and mode transitions (Setting)

### 2. Stop_Watch = Stop_Watch_Ctrl + Stop_Watch_DP
  - **Stop_Watch_Ctrl** : Controls the Stop_Watch's state and mode transitions (Run, Stop, Clear)

### 3. Timer = Timer_Ctrl + Timer_DP
  - **Timer_Ctrl** : Controls the Timer's state and mode transitions (Run, Stop, Clear, Setting)

### 4. Fnd_Controller = Digital_Spliters + Muxs + Decoders
  - **Digital Splitters**: This module is designed to split a number, ranging from 0 to 100, into individual digits for display.
  - **Muxs** : The output on the 7-segment display varies depending on the selected mode.
  - **Decoders** : This module converts decimal numbers into a format suitable for a 7-segment display.
