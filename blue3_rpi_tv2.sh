#!/bin/bash
#
#
#
#  * Autor: Samir Hanna Verza
#  * Criado: 01/04/2025
#  * 
#  * Ult. Atualização: 01/04/2025
#  * Versão: 1.0
#
#
#

wget files.b3.rs/blue3/sources.12 -O /etc/apt/sources.12
mv /etc/apt/sources.list /etc/apt/sources.bk
mv /etc/apt/sources.12 /etc/apt/sources.list

apt update
apt upgrade -y
apt autoremove -y
apt clean -y
apt install -y xdotool unclutter

#USER=$(whoami)
# RECEBENDO O VALOR PELO SCRIPT
USER=$1
if [ -z "$USER" ]; then
	USER=blue3
fi



DIR=/home/$USER
FILE=$DIR/b3web.sh


echo "# Desativa o protetor de tela e o gerenciamento de energia" > $FILE
echo "xset s noblank" >> $FILE
echo "xset s off" >> $FILE
echo "xset -dpms" >> $FILE
echo "" >> $FILE
echo "# Esconde o cursor após 0.5 segundos de inatividade" >> $FILE
echo "unclutter -idle 0.5 -root &" >> $FILE
echo "" >> $FILE
echo "# Modifica as preferências do Chromium para evitar mensagens de erro" >> $FILE
echo "sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/$USER/.config/chromium/Default/Preferences" >> $FILE
echo "sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/$USER/.config/chromium/Default/Preferences" >> $FILE
echo "" >> $FILE
echo "# Inicia o Chromium em modo quiosque com as duas URLs em segundo plano" >> $FILE
echo "/usr/bin/chromium-browser --noerrdialogs --disable-infobars --kiosk \"https://prtg.blue3.cloud/public/mapshow.htm?id=2919&mapid=E63F8F04-E273-45B3-B33D-4106EE638CDF\" &" >> $FILE
echo "" >> $FILE
echo "# Aguarda 10 segundos para o Chromium abrir e carregar as páginas" >> $FILE
echo "sleep 10" >> $FILE
echo "" >> $FILE
echo "# Loop infinito para alternar entre abas a cada 20 segundos" >> $FILE
echo "while true; do" >> $FILE
echo "  # Garante que a janela do Chromium está em foco" >> $FILE
echo "  xdotool search --name "Chromium" windowfocus" >> $FILE
echo "  # Simula o pressionamento de Ctrl+Tab para alternar abas" >> $FILE
echo "  xdotool keydown ctrl+Tab; xdotool keyup ctrl+Tab" >> $FILE
echo "  # Aguarda 20 segundos antes da próxima alternância" >> $FILE
echo "  sleep 20" >> $FILE
echo "done" >> $FILE

chmod +x $FILE

FILE=/lib/systemd/system/b3web.service

echo "[Unit]" > $FILE
echo "Description=Chromium Kiosk" >> $FILE
echo "Wants=graphical.target" >> $FILE
echo "After=graphical.target" >> $FILE
echo "" >> $FILE
echo "[Service]" >> $FILE
echo "Environment=DISPLAY=:0" >> $FILE
echo "Environment=XAUTHORITY=/home/$USER/.Xauthority" >> $FILE
echo "Type=simple" >> $FILE
echo "ExecStart=/bin/bash /home/$USER/b3web.sh" >> $FILE
echo "Restart=on-abort" >> $FILE
echo "User=$USER" >> $FILE
echo "Group=$USER" >> $FILE
echo "" >> $FILE
echo "[Install]" >> $FILE
echo "WantedBy=graphical.target" >> $FILE


systemctl enable b3web.service
systemctl start b3web.service


echo ""
echo ""
echo ""
echo "CONCLUIDO"
echo ""
echo ""
echo ""
systemctl disable bluetooth
