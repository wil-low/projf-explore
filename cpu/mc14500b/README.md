# 🧮 MC14500B Industrial Controller (1-bit CPU) in SystemVerilog

This project implements a **Motorola MC14500B** industrial control unit in SystemVerilog. The MC14500B is a simple 1-bit CPU originally used in PLC (Programmable Logic Controller) applications in the late 1970s.

---

## 🧠 About the MC14500B

- **Bit width**: 1-bit architecture
- **Instruction set**: 16 simple instructions (no program counter)
- **Use cases**: Control logic, decision trees, industrial automation
- **Notable feature**: Separates control from program flow (typically uses external sequencer or microprogramming ROM)

More info: [Wikipedia – MC14500B](https://en.wikipedia.org/wiki/Motorola_MC14500B)

## 🎮 Bonus: "Kill the Bit" Game

The project also includes a playable implementation of **Kill the Bit**, a minimalist 1-bit game designed to demonstrate the MC14500B's capabilities. The game uses simple input logic and LED output to simulate gameplay, showcasing how even a 1-bit processor can drive interactive behavior.

## 🙏 Acknowledgments

* Based on Motorola MC14500B datasheets and control logic examples
