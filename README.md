# Development Tools

This repository contains scripts and configuration files for building, testing, and managing firmware for the Raspberry Pi Pico and related projects.

## Features

- **Build Automation**: 
  - `build.sh`: Automates the build process using CMake and Ninja. Includes options for cleaning and configuring the workspace.
  - `picotool-build.sh`: Downloads, builds, and installs `picotool`, a utility for managing Raspberry Pi Pico firmware.
  
- **Testing**:
  - `test.sh`: Runs tests on the Raspberry Pi Pico, handles parameter updates, and monitors serial output.

- **Utility Functions**:
  - `utilities.sh`: Provides reusable functions for file management, USB device detection, and parameter flashing.

- **Version Management**:
  - `revision.h.in` & `revision_header.cmake`: Supports generating firmware version headers dynamically.

- **Additional Scripts**:
  - `generate_authors.sh`: Generates a formatted list of project contributors from Git history.

## Getting Started

1. **Install Dependencies**:
   Ensure `cmake`, `make`, `libusb`, and a suitable GCC toolchain for ARM are installed.

2. **Build the Project**:
   ```bash
   ./build.sh
   ```

3. **Install picotool**:
   ```bash
   ./picotool-build.sh
   ```

4. **Run Tests**:
   Use `test.sh` to run firmware tests:
   ```bash
   ./test.sh <group> <identifier> [binary.uf2]
   ```

## Project Structure

- `build/`: Contains build scripts and CMake configurations.
- `bin/`: Output binaries and logs.
- `scripts/`: Utility and helper scripts.

## Contributing

Contributions are welcome! Please ensure your changes adhere to the project's coding and formatting standards.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
