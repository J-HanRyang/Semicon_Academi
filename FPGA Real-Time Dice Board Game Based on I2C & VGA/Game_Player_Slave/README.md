# Game_Player Slave
<div align="center">
  <img width="667" height="386" alt="image" src="https://github.com/user-attachments/assets/f37c4753-5a32-4022-9e86-19ddac206c2d" />
</div>

## Slave Boards
- Receive game state registers from the Master
- Apply real-time visual filters based on received states
- Output synchronized VGA display

### 🔗 I2C Communication
- **I2C Master Controller**
  - Sends game state data to Slave boards
  - Introduced a 3ms interval between transactions to prevent BUSY conflicts
- **I2C Slave Registers**
  - **Reg0** : Player status (leading / trailing)
  - **Reg1** : Game result (win / lose)
  - **Reg2** : Visual filter events
- **Slave Visual Effects**
  - Gray (trailing)
  - Mosaic / Shake (trap)
  - Golden (ladder)
  - WIN / LOSE effects
