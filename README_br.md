# BLUE3_RPI

## Script inicial Raspberry Pi

Este diretório contém o script de bootstrap inicial para Raspberry Pi OS Lite:

- [rpi_start.sh](rpi_start.sh).
- Os arquivos blue3_rpi* são arquivos legados da configuração do monitoramento.

Objetivo:

- preparar uma instalação mínima para projetos com I2C, sensores digitais e sensores analógicos;
- manter compatibilidade com Raspberry Pi OS Lite (base Debian), com execução em modo root;
- oferecer configuração interativa para escolher entre ambiente gráfico (Desktop) ou somente CLI.

## O que o script faz

1. Validação e segurança
- executa em Bash com modo estrito (set -euo pipefail);
- valida se está rodando como root;
- valida sistema compatível com Raspberry Pi OS/Debian;
- grava log de execução em /var/log/rpi_start.log.

2. Instalação de pacotes base
- instala python3;
- instala curl;
- instala php;
- adiciona pacotes úteis para projetos com sensores e desenvolvimento:
	- python3-pip, python3-venv
	- python3-smbus, python3-rpi.gpio, python3-gpiozero, python3-spidev
	- i2c-tools
	- php-cli, php-curl
	- ca-certificates, git, nano, vim-tiny

3. Habilitação de interfaces para sensores
- habilita I2C;
- habilita SPI (útil para ADCs como MCP3008);
- pergunta se deve habilitar 1-Wire (exemplo: DS18B20).

4. Escolha do modo do sistema
- pergunta se deseja instalar ambiente gráfico;
- se SIM: instala metapacote desktop disponível (com fallback para ambiente gráfico mínimo);
- se NÃO: mantém sistema em modo CLI (multi-user.target).

## Como executar

No Raspberry Pi:

```bash
sudo bash rpi_start.sh
```

## Pós-instalação

- reiniciar o Raspberry Pi para aplicar todas as mudanças de módulos e boot;
- validar I2C com:

```bash
i2cdetect -y 1
```

- validar SPI verificando se existe /dev/spidev0.0:

```bash
ls -l /dev/spidev*
```

## Observações

- o script foi pensado para instalação básica mínima, evitando dependências desnecessárias;
- por padrão, a opção recomendada para servidores e gateways é CLI;
- use Desktop apenas quando houver necessidade real de interface gráfica no dispositivo.
