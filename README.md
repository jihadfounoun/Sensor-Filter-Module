# Digital Logic Design Project - Sensor Filter Module

This repository contains the **Sensor Filter Module**, developed as part of the **Digital Logic Design** course at Politecnico di Milano. The module implements a VHDL-based hardware design for analyzing and processing sensor data, assigning credibility scores, and managing outliers.

---

## Features

- **Data Analysis and Credibility Assignment**: Processes memory data, assigning credibility indices ranging from 0 to 31.
- **Sequential Computations**: Performs multiple computations over the data to handle missing values or invalid entries.
- **Outlier Management**: Automatically adjusts data and credibility indices using a Bayesian-inspired filtering approach.

---

## Use Case

An example application is a **smart air purifier** equipped with sensors for humidity and dust levels:
- Sensors store readings in memory periodically.
- The system analyzes the data, fills missing values, and assigns credibility to each reading.

---

## Architecture

- **Finite State Machine (FSM)**: Manages the operational states for data processing.
- **Counter Address**: Tracks memory addresses during read/write operations.
- **Counter K**: Handles iteration counts for sequential computations.
- **Selector**: Determines the values and credibility indices to write back to memory.

---

## Experimental Results

- Maximum operating frequency: **237.71 MHz**
- FPGA resource usage: Utilizes 75 Flip-Flops, with no latches.
- Thoroughly tested under various conditions (e.g., long sequences of zeros, consecutive computations).

---

## Documentation

- **[Hardware Code](hardware_code.vhd)**: Contains the VHDL implementation of the module.
- **[Project Report](project_report.pdf)**: Detailed documentation of the project, including design decisions and test results.
- **[Specifications](project_specifications.pdf)**: Formal requirements and descriptions.

---

## Installation

- Clone the repository:
   ```bash
   git clone https://github.com/jihadfounoun/Sensor-Filter-Module.git
   ```




---

## Software Used
- Xilinx Vivado

---

## Contributors

- [Jihad Founoun](https://github.com/jihadfounoun)
- [Amina El Kharouai](https://github.com/AminaElKharouai)

---

## Project Score

Final Evaluation: **30/30**

---

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

**Politecnico di Milano - Digital Logic Design Project 2023/2024**

