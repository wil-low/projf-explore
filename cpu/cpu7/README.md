# 🧠 CPU7: 7-bit Stack-Based CPU in SystemVerilog

This project is a SystemVerilog implementation of the conceptual **CPU7** architecture—a 7-bit stack-based processor inspired by Forth and Reverse Polish Notation (RPN) principles. It features a minimalist instruction set and supports dynamic virtual cores, making it ideal for exploring unconventional CPU design and FPGA experimentation.

---

## 🔍 Overview

**CPU7** is a conceptual CPU architecture designed for simplicity and flexibility. Key features include:

- **7-bit Data Width**: Unusual data size for educational exploration
- **Stack-Based Execution**: Operates primarily through a data stack, similar to Forth
- **Minimal Instruction Set**: Focuses on essential operations for clarity and simplicity
- **Dynamic Virtual Cores**: Supports creation and destruction of virtual cores for multithreaded execution
- **Self-Modifying Code**: Capable of self-packing and unpacking code and data to optimize memory usage
- **Forth-like Assembly Language**: Instructions designed for direct operation with strings and system function calls

## 📚 References

* [CPU7 Concept](https://github.com/knivd/CPU7)
* [Project F: FPGA Learning Resources](https://github.com/projf/projf-explore)
