# 🧠 MK14 FPGA Implementation

This project is a hardware recreation of the **Science of Cambridge MK14** microcomputer, implemented in System Verilog for FPGA platforms. It emulates the original 1977 kit computer, featuring the **National Semiconductor SC/MP (INS8060)** CPU, 7-segment LED display, and keypad interface.

---

## 🕰️ About the MK14

The **MK14** (Microcomputer Kit 14) was one of the earliest affordable home computers in the UK, released in 1977 by Science of Cambridge (founded by Clive Sinclair). It featured:

- **CPU**: National Semiconductor SC/MP (INS8060)
- **Memory**: 256 bytes RAM (expandable to 640 bytes), 512 bytes ROM
- **Display**: 8-digit 7-segment LED
- **Input**: 20-key hexadecimal keypad

Over 15,000 units were sold, making it a significant milestone in computing history.

---

## ⚙️ Project Overview

This FPGA implementation includes:

- **SC/MP CPU Core**: System Verilog-based emulation of the INS8060 processor
- **Memory Map**: ROM and RAM layout matching the original MK14
- **Display**: Multiplexed 7-segment LED driver
- **Keypad**: Infrared controller input handling
- **Monitor ROM**: Original MK14 monitor program in Intel HEX format

---

## 🛠️ Getting Started

### Prerequisites

- FPGA development board (e.g., Lattice iCE40, ECP5, Gowin, or Xilinx Artix-7)
- Verilog-compatible toolchain (e.g., Yosys, nextpnr, Vivado, Quartus, Gowin IDE)
- Serial terminal for interaction (optional)

### Build Instructions

1. Clone the repository:

```bash
   git clone https://github.com/wil-low/projf-explore.git
   cd projf-explore/cpu/mk14
````

2. Synthesize and upload the design to your FPGA board using your preferred toolchain.

3. Interact with the MK14 via an infrared controller and observe output on the 7-segment display or VGA output

## 📁 Main modules

* `mk14_soc.sv`: Top-level module integrating CPU, memory, display, and input
* `mmu.sv`: MK14 Memory Management Unit
* `core.sv`: MK14 CPU core module
* `rom.hex`: Monitor program in Intel HEX format
* `ir_keypad.v`: Infrared controller input handler

---

## 📚 References

* [MK14 on Wikipedia](https://en.wikipedia.org/wiki/MK14)
* [Project F: FPGA Learning Resources](https://github.com/projf/projf-explore)

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE) file for details.

---

## 🙌 Acknowledgments

* Inspired by the original MK14 design by Science of Cambridge
* Uses libraries of the Project F initiative to make FPGA development accessible
