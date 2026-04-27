#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/rpi_start.log"

log() {
	local level="$1"
	local msg="$2"
	printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$msg" | tee -a "$LOG_FILE"
}

die() {
	log "ERRO" "$1"
	exit 1
}

require_root() {
	if [[ "${EUID}" -ne 0 ]]; then
		die "Execute como root: sudo bash ${SCRIPT_NAME}"
	fi
}

check_supported_os() {
	if [[ ! -f /etc/os-release ]]; then
		die "Nao foi possivel identificar o sistema operacional."
	fi

	# shellcheck disable=SC1091
	source /etc/os-release

	local os_name="${NAME:-desconhecido}"
	local os_id="${ID:-}"

	if [[ "$os_id" != "raspbian" && "$os_id" != "debian" ]]; then
		die "Sistema nao suportado: ${os_name}. Este script foi feito para Raspberry Pi OS (Lite)."
	fi

	if [[ -f /proc/device-tree/model ]] && ! grep -qi "raspberry pi" /proc/device-tree/model; then
		log "AVISO" "Hardware nao identificado como Raspberry Pi. Continuando por sua conta e risco."
	fi
}

ask_yes_no() {
	local prompt="$1"
	local default="${2:-N}"
	local answer

	while true; do
		if [[ "$default" == "S" ]]; then
			read -r -p "$prompt [S/n]: " answer
			answer="${answer:-S}"
		else
			read -r -p "$prompt [s/N]: " answer
			answer="${answer:-N}"
		fi

		case "${answer^^}" in
			S|SIM|Y|YES) return 0 ;;
			N|NAO|NÃO|NO) return 1 ;;
			*) log "INFO" "Resposta invalida. Digite s ou n." ;;
		esac
	done
}

apt_update_once() {
	log "INFO" "Atualizando indice de pacotes (apt update)..."
	DEBIAN_FRONTEND=noninteractive apt-get update -y
}

install_packages() {
	local -a packages=("$@")

	if [[ "${#packages[@]}" -eq 0 ]]; then
		return 0
	fi

	log "INFO" "Instalando pacotes: ${packages[*]}"
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
}

enable_i2c() {
	log "INFO" "Habilitando I2C"

	if command -v raspi-config >/dev/null 2>&1; then
		raspi-config nonint do_i2c 0 || log "AVISO" "Falha ao habilitar I2C via raspi-config; tentando metodo manual."
	fi

	if ! grep -Eq '^dtparam=i2c_arm=on' /boot/config.txt /boot/firmware/config.txt 2>/dev/null; then
		if [[ -f /boot/firmware/config.txt ]]; then
			echo 'dtparam=i2c_arm=on' >> /boot/firmware/config.txt
		elif [[ -f /boot/config.txt ]]; then
			echo 'dtparam=i2c_arm=on' >> /boot/config.txt
		fi
	fi

	if ! grep -Eq '^i2c-dev$' /etc/modules; then
		echo 'i2c-dev' >> /etc/modules
	fi

	modprobe i2c-dev || true
}

enable_spi() {
	log "INFO" "Habilitando SPI (util para ADCs como MCP3008)"

	if command -v raspi-config >/dev/null 2>&1; then
		raspi-config nonint do_spi 0 || log "AVISO" "Falha ao habilitar SPI via raspi-config; tentando metodo manual."
	fi

	if ! grep -Eq '^dtparam=spi=on' /boot/config.txt /boot/firmware/config.txt 2>/dev/null; then
		if [[ -f /boot/firmware/config.txt ]]; then
			echo 'dtparam=spi=on' >> /boot/firmware/config.txt
		elif [[ -f /boot/config.txt ]]; then
			echo 'dtparam=spi=on' >> /boot/config.txt
		fi
	fi
}

enable_one_wire_optional() {
	if ask_yes_no "Deseja habilitar 1-Wire (ex.: DS18B20)?" "N"; then
		log "INFO" "Habilitando 1-Wire"

		if command -v raspi-config >/dev/null 2>&1; then
			raspi-config nonint do_onewire 0 || log "AVISO" "Falha ao habilitar 1-Wire via raspi-config; tentando metodo manual."
		fi

		if ! grep -Eq '^dtoverlay=w1-gpio' /boot/config.txt /boot/firmware/config.txt 2>/dev/null; then
			if [[ -f /boot/firmware/config.txt ]]; then
				echo 'dtoverlay=w1-gpio' >> /boot/firmware/config.txt
			elif [[ -f /boot/config.txt ]]; then
				echo 'dtoverlay=w1-gpio' >> /boot/config.txt
			fi
		fi
	fi
}

install_graphical_environment() {
	local -a desktop_candidates=(
		"raspberrypi-ui-mods"
		"raspberrypi-desktop"
		"task-lxqt-desktop"
	)

	local selected=""
	local pkg
	for pkg in "${desktop_candidates[@]}"; do
		if apt-cache show "$pkg" >/dev/null 2>&1; then
			selected="$pkg"
			break
		fi
	done

	if [[ -z "$selected" ]]; then
		log "AVISO" "Nenhum metapacote de desktop encontrado. Instalando ambiente grafico minimo."
		install_packages xserver-xorg xinit openbox lightdm lxterminal pcmanfm
		return
	fi

	log "INFO" "Instalando ambiente grafico com pacote: $selected"
	install_packages "$selected"

	if command -v systemctl >/dev/null 2>&1; then
		systemctl set-default graphical.target || true
		systemctl enable lightdm >/dev/null 2>&1 || true
	fi
}

main() {
	require_root
	check_supported_os

	touch "$LOG_FILE"
	chmod 640 "$LOG_FILE"

	log "INFO" "Iniciando configuracao inicial do Raspberry Pi"

	apt_update_once

	install_packages \
		python3 \
		python3-pip \
		python3-venv \
		python3-smbus \
		python3-rpi.gpio \
		python3-gpiozero \
		python3-spidev \
		i2c-tools \
		curl \
		php \
		php-cli \
		php-curl \
		ca-certificates \
		git \
		nano \
		vim-tiny

	enable_i2c
	enable_spi
	enable_one_wire_optional

	if ask_yes_no "Deseja instalar ambiente grafico (Desktop)?" "N"; then
		install_graphical_environment
	else
		log "INFO" "Modo CLI selecionado. Ambiente grafico nao sera instalado."
		if command -v systemctl >/dev/null 2>&1; then
			systemctl set-default multi-user.target || true
		fi
	fi

	log "INFO" "Configuracao concluida. Reinicie o Raspberry Pi para aplicar tudo."
}

main "$@"
