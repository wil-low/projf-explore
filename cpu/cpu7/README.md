# 🧠 CPU7: 7-bit Stack-Based CPU in System Verilog

This project is a System Verilog implementation of the conceptual **CPU7** architecture—a 7-bit stack-based processor inspired by Forth and Reverse Polish Notation (RPN) principles. It features a minimalist instruction set and supports dynamic virtual cores, making it ideal for exploring unconventional CPU design and FPGA experimentation.

---

## 🔍 Overview

**CPU7** is a conceptual CPU architecture designed for simplicity and flexibility. Key features include:

- **7-bit Data Width**: Unusual data size for educational exploration
- **Stack-Based Execution**: Operates primarily through a data stack, similar to Forth
- **Minimal Instruction Set**: Focuses on essential operations for clarity and simplicity
- **Dynamic Virtual Cores**: Supports creation and destruction of virtual cores for multithreaded execution
- **Self-Modifying Code**: Capable of self-packing and unpacking code and data to optimize memory usage
- **Forth-like Assembly Language**: Instructions designed for direct operation with strings and system function calls

---

## 🛠️ Project Structure

- `cpu7_soc.sv`: Top-level module integrating CPU, memory, display, and input
- `core.sv`: Core Verilog module implementing the CPU7 architecture
- `constants.svh`: Operation and error codes

---

## 🚀 Getting Started

### Prerequisites

- Verilog simulator (e.g., Icarus Verilog, ModelSim)
- Optional: FPGA development board for hardware implementation

### Simulation

1. Compile the Verilog files:

   ```bash
   iverilog -o cpu7_tb cpu7.v cpu7_tb.v
````

2. Run the simulation:

   ```bash
   vvp cpu7_tb
   ```

3. View waveforms using GTKWave or a similar tool:

   ```bash
   gtkwave cpu7_tb.vcd
   ```

---

## 📚 References

* [CPU7 Conceptual Framework](https://github.com/knivd/CPU7)
* [Project F: FPGA Learning Resources](https://github.com/projf/projf-explore)

---

## 📝 License

This project is provided for educational and experimental purposes. Refer to the LICENSE file for more information.

---

## 🙌 Acknowledgments

* Inspired by the CPU7 architecture conceptualized by [knivd](https://github.com/knivd/CPU7)

