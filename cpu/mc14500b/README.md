# 🧮 MC14500B Industrial Controller (1-bit CPU) in System Verilog

This project implements a **Motorola MC14500B** industrial control unit in System Verilog. The MC14500B is a simple 1-bit CPU originally used in PLC (Programmable Logic Controller) applications in the late 1970s.

> 💡 Ideal for educational use and minimalist CPU design exploration.

---

## 🧠 About the MC14500B

- **Bit width**: 1-bit architecture
- **Instruction set**: 16 simple instructions (no program counter)
- **Use cases**: Control logic, decision trees, industrial automation
- **Notable feature**: Separates control from program flow (typically uses external sequencer or microprogramming ROM)

More info: [Wikipedia – MC14500B](https://en.wikipedia.org/wiki/Motorola_MC14500B)

---

## 📁 Features

- Full Verilog implementation of the MC14500B control unit
- Combinational and clocked variants for simulation and synthesis
- Instruction decoding and signal outputs match original datasheet
- Testbench demonstrating basic instruction usage and waveform behavior

---

## 🔧 File Overview

- `mc14500b.v`: Core Verilog module implementing the 1-bit CPU
- `instructions.svh`: CPU instruction codes
- `generate_cmd.svh`: Sample program
- `README.md`: This documentation

---

## 🚦 Instructions Summary

The CPU supports 16 operations including logical AND/OR/NOT, bit testing, conditional I/O, and jump control via external logic.

| Instruction | Mnemonic | Description                |
|-------------|----------|----------------------------|
| 0000        | NOP      | No Operation               |
| 0001        | LD       | Load input to data bit     |
| 0010        | AND      | Logical AND with input     |
| ...         | ...      | See datasheet for full list|

---

## ▶️ Simulation

You can run simulations using any Verilog simulator such as:

```bash
iverilog -o mc14500b_tb mc14500b.v mc14500b_tb.v
vvp mc14500b_tb
````

Waveforms can be viewed using GTKWave or ModelSim.

---

## 🎮 Bonus: "Kill the Bit" Game

The project also includes a playable implementation of **Kill the Bit**, a minimalist 1-bit game designed to demonstrate the MC14500B's capabilities. The game uses simple input logic and LED output to simulate gameplay, showcasing how even a 1-bit processor can drive interactive behavior.

- Written entirely for the 1-bit architecture
- Demonstrates conditional branching and I/O control
- Useful for educational and retro-gaming demonstrations on hardware

---

## 🚀 Future Enhancements

* Program ROM and external control logic
* Visualization of execution via LEDs or 7-segment display on FPGA board
* Hardware implementation on iCEBreaker or similar FPGA board

---

## 📝 License

This project is licensed under the MIT License. See [LICENSE](../LICENSE) for details.

---

## 🙏 Acknowledgments

* Based on Motorola MC14500B datasheets and control logic examples
