# BLUE3_RPI

## Raspberry Pi initial script

This directory contains the initial bootstrap script for Raspberry Pi OS Lite:

- [rpi_start.sh](rpi_start.sh).
- The blue3_rpi* files are legacy files from the monitoring setup.

Goal:

- prepare a minimal installation for projects with I2C, digital sensors and analog sensors;
- keep compatibility with Raspberry Pi OS Lite (Debian-based), running in root mode;
- offer interactive configuration to choose between a graphical environment (Desktop) or CLI only.

## What the script does

1. Validation and safety
- runs in Bash with strict mode (set -euo pipefail);
- validates that it is running as root;
- validates that the system is compatible with Raspberry Pi OS/Debian;
- writes an execution log to /var/log/rpi_start.log.

2. Base package installation
- installs python3;
- installs curl;
- installs php;
- adds useful packages for sensor and development projects:
	- python3-pip, python3-venv
	- python3-smbus, python3-rpi.gpio, python3-gpiozero, python3-spidev
	- i2c-tools
	- php-cli, php-curl
	- ca-certificates, git, nano, vim-tiny

3. Enabling interfaces for sensors
- enables I2C;
- enables SPI (useful for ADCs such as the MCP3008);
- asks whether to enable 1-Wire (example: DS18B20).

4. System mode choice
- asks whether to install a graphical environment;
- if YES: installs an available desktop metapackage (with a fallback to a minimal graphical environment);
- if NO: keeps the system in CLI mode (multi-user.target).

## How to run

On the Raspberry Pi:

```bash
sudo bash rpi_start.sh
```

## Post-installation

- reboot the Raspberry Pi to apply all module and boot changes;
- validate I2C with:

```bash
i2cdetect -y 1
```

- validate SPI by checking whether /dev/spidev0.0 exists:

```bash
ls -l /dev/spidev*
```

## Notes

- the script was designed for a minimal basic installation, avoiding unnecessary dependencies;
- by default, the recommended option for servers and gateways is CLI;
- use Desktop only when there is a real need for a graphical interface on the device.
