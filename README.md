# FPGA HFT – Avellaneda-Stoikov Market Making & Market Data Parser

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue)
![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog-orange)
![CI](https://github.com/gaikwaddigvijay31-a11y/avellaneda-stoikov/actions/workflows/rtl-verification.yml/badge.svg)
![License](https://img.shields.io/badge/License-TBD-lightgrey)

A hardware-oriented High-Frequency Trading (HFT) project exploring market-making logic, binary market-data parsing, RTL simulation, and automated verification using GitHub Actions.

The project uses SystemVerilog to explore how latency-sensitive trading components can be represented and verified at the hardware level.

## Project Overview

The repository currently contains two main components:

1. **Avellaneda-Stoikov Market Making Model** – RTL implementation exploring reservation-price and optimal-spread calculations for inventory-aware market making.
2. **Market Data Parser** – A SystemVerilog parser that extracts structured fields from a 64-bit input stream.

The project also includes simulation testbenches and a GitHub Actions workflow for automated RTL compilation and verification.

## Repository Structure

```text
avellaneda-stoikov/
│
├── .github/
│   └── workflows/
│       └── rtl-verification.yml
│
├── rtl/
│   ├── fixed_point_pkg.sv
│   └── avellaneda_stoikov.sv
│
├── market_data_parser/
│   └── market_data_parser.sv
│
├── tb/
│   ├── tb_avellaneda_stoikov.sv
│   └── tb_market_data_parser/
│       └── tb_market_data_parser.sv
│
├── .gitignore
└── README.md
```

## 1. Market Data Parser

The market data parser is implemented in SystemVerilog.

It receives market-data messages through a 64-bit input interface and extracts structured information.

### Extracted fields

| Field | Width |
|---|---:|
| Message Type | 8 bits |
| Order ID | 64 bits |
| Symbol ID | 16 bits |
| Side | 8 bits |
| Price | 32 bits |
| Quantity | 32 bits |
| Timestamp | 64 bits |

### Parser architecture

The parser uses a finite-state machine (FSM):

```text
IDLE
  |
  v
WORD0
  |
  v
WORD1
  |
  v
WORD2
  |
  v
WORD3
  |
  v
OUTPUT
```

The FSM collects message fields across successive input words and produces a structured output message.

**Note:** The current implementation uses an ITCH-like message layout for experimentation. It is not yet a complete implementation of the official NSE or NASDAQ ITCH protocol.

## 2. Avellaneda-Stoikov Market Making Model

The project also includes an RTL implementation exploring the Avellaneda-Stoikov market-making framework.

The model focuses on concepts such as:

- Reservation price
- Optimal bid/ask spread
- Inventory management
- Market-price inputs
- Fixed-point arithmetic

The shared fixed-point package defines common data types and arithmetic
