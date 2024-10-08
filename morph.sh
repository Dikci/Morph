#!/bin/bash

# Логотип
echo -e '\e[32m'
echo -e '███╗   ██╗ ██████╗ ██████╗ ███████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ '
echo -e '████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗'
echo -e '██╔██╗ ██║██║   ██║██║  ██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝'
echo -e '██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗'
echo -e '██║ ╚████║╚██████╔╝██████╔╝███████╗██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║'
echo -e '╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝'
echo -e '\e[0m'

echo -e "\nПодписаться на канал may.crypto{🦅} чтобы быть в курсе самых актуальных нод - https://t.me/maycrypto\n"

sleep 2

while true; do
  # Меню
  PS3='Выберите опцию: '
  options=("Установить ноду Morph" "Удалить ноду Morph" "Проверить работоспособность ноды" "Добавить мониторинг через Telegram Бота" "Покинуть скрипт")
  select opt in "${options[@]}"
  do
      case $opt in
          "Установить ноду Morph")
              echo "Начинаем установку ноды Morph..."
            

              # Установка Geth
              echo "Установка Geth..."
              mkdir -p ~/.morph
              cd ~/.morph
              git clone https://github.com/morph-l2/morph.git
              cd morph
              git checkout v0.2.0-beta
              make nccc_geth
              cd ~/.morph/morph/node
              make build

              # Загрузка и распаковка данных
              echo "Загрузка и распаковка данных..."
              cd ~/.morph
              wget https://raw.githubusercontent.com/morph-l2/config-template/main/holesky/data.zip
              unzip data.zip

              # Создание Secret Key
              echo "Создание Secret Key..."
              cd ~/.morph
              openssl rand -hex 32 > jwt-secret.txt
              echo "Пауза 30 сек... Сохраните Secret Key в надежное место и не потеряйте..."
              cat jwt-secret.txt
              sleep 30

              # Запуск ноды Geth
              echo "Запуск ноды Geth..."
              screen -S geth -d -m ~/.morph/morph/go-ethereum/build/bin/geth --morph-holesky \
                  --datadir "./geth-data" \
                  --http --http.api=web3,debug,eth,txpool,net,engine \
                  --http.port 8546 \
                  --authrpc.addr localhost \
                  --authrpc.vhosts="localhost" \
                  --authrpc.port 8551 \
                  --authrpc.jwtsecret=./jwt-secret.txt \
                  --miner.gasprice="100000000" \
                  --log.filename=./geth.log \
                  --port 30363

              # Запуск Morph ноды
              echo "Запуск Morph ноды..."
              screen -S morph -d -m ~/.morph/morph/node/build/bin/morphnode --home ./node-data \
                  --l2.jwt-secret ./jwt-secret.txt \
                  --l2.eth http://localhost:8546 \
                  --l2.engine http://localhost:8551 \
                  --log.filename ./node.log

              echo "Установка завершена!"
              break
              ;;
              
          "Удалить ноду Morph")
              echo "Удаление ноды Morph..."
              sudo rm -rf ~/.morph
              sudo docker system prune -a -f
              screen -S geth -X quit
              screen -S morph -X quit
              screen -S telegram_bot -X quit
              echo "Нода Morph успешно удалена!"
              break
              ;;
              
          "Проверить работоспособность ноды")
              echo "Проверка работоспособности ноды..."
              curl -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":74}' http://localhost:8546
              curl http://localhost:26657/status
              break
              ;;
              
          "Добавить мониторинг через Telegram Бота")
              read -p "Введите API ключ от Telegram Бота: " API_KEY
              read -p "Введите ваш User ID в Telegram: " USER_ID
              read -p "Введите интервал проверки (в секундах, по умолчанию 600): " CHECK_INTERVAL
              CHECK_INTERVAL=${CHECK_INTERVAL:-600}  # Значение по умолчанию 600 секунд
              
              echo "Устанавливаем Python зависимости..."
              sudo apt install python3 -y
              sudo apt install pip -y
              apt install python3-python-telegram-bot
              apt install python3-requests
              echo "Создаем и запускаем скрипт мониторинга..."
              cat <<EOF > ~/.morph/node_monitor.py
import requests
import time
import json
from telegram import Bot

api_key = $API_KEY
user_id = $USER_ID
check_interval = $CHECK_INTERVAL

bot = Bot(token=api_key)

# Функция для проверки состояния ноды
def check_node_status():
    try:
        response_geth = requests.post('http://localhost:8546', json={"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":74})
        response_morph = requests.get('http://localhost:26657/status')

        if response_geth.status_code == 200 and response_morph.status_code == 200:
            geth_data = response_geth.json()
            morph_data = response_morph.json()
            
            message = f"🟢 Нода Morph работает корректно!\n\n" \
                      f"🔗 Geth Peer Count: {geth_data['result']}\n" \
                      f"📝 Morph Node Status: {json.dumps(morph_data, indent=2)}"
            bot.send_message(chat_id=user_id, text=message)
        else:
            bot.send_message(chat_id=user_id, text="🔴 Проблемы с нодой Morph!")
    except Exception as e:
        bot.send_message(chat_id=user_id, text=f"⚠️ Ошибка при проверке ноды: {e}")

# Основной цикл мониторинга
if __name__ == "__main__":
    notifications_enabled = True
    
    while True:
        if notifications_enabled:
            check_node_status()
        
        time.sleep(check_interval)
EOF
              chmod +x ~/.morph/node_monitor.py
              echo "Запуск скрипта мониторинга..."
              screen -S telegram_bot -d -m python3 ~/.morph/node_monitor.py
              echo "Мониторинг ноды через Telegram Бота установлен!"
              break
              ;;
              
          "Покинуть скрипт")
              echo "Выход..."
              exit 0
              ;;
              
          *) echo "Неверный выбор, попробуйте снова.";;
      esac
  done
done
