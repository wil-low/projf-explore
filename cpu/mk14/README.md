# 🧠 MK14 in SystemVerilog

This project is a hardware recreation of the **Science of Cambridge MK14** microcomputer, implemented in SystemVerilog for FPGA platforms. It emulates the original 1977 kit computer, featuring the **National Semiconductor SC/MP (INS8060)** CPU, 7-segment LED display, and keypad interface.

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
- **Display**: Multiplexed 7-segment LED driver, or TM1680 module; VGA/HDMI drivers for graphical mode
- **Keypad**: Infrared controller input handling
- **Monitor ROM**: Original MK14 monitor program in Intel HEX format
- **ROM Update**: UART driver

---

## 📚 References

* [MK14 on Wikipedia](https://en.wikipedia.org/wiki/MK14)
* [More resources on MK14](https://www.theoddys.com/acorn/acorn_system_computers/mk14/mk14.html)
* [Project F: FPGA Learning Resources](https://github.com/projf/projf-explore)

---

## 🙌 Acknowledgments

* Inspired by the original MK14 design by Science of Cambridge
* Uses libraries of the Project F initiative to make FPGA development accessible
