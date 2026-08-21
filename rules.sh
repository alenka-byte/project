#!/bin/bash
MY_IP=$(hostname -I | awk '{print $1}')

# === Настройки ===
BACKEND_IP="192.168.23.10"    # ВМ1
PROXY_IP="192.168.23.130"      # ВМ2

BACKEND_PORT="8080"          # Порт Backend API
PROXY_PORT="5000"            # Порт Proxy API
POSTGRES_PORT="5432"         # Порт PostgreSQL
REDIS_PORT="6379"            # Порт Redis

# === Функция для Ubuntu (iptables) ===
configure_ubuntu() {
    echo "Настройка Ubuntu (ВМ1: Backend + PostgreSQL)..."
    # Сбрасываем все правила
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    # Политика по умолчанию - DROP (всё запрещено)
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT  # Исходящие разрешены для доступа к репозиториям и т.д.
    # Разрешаем localhost
    sudo iptables -A INPUT -i lo -j ACCEPT
    # Разрешаем установленные соединения
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    # Разрешаем SSH (чтобы не потерять доступ)
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    # === Правила для Backend (порт 8080) ===
    # Принимаем запросы ТОЛЬКО от прокси (ВМ2)
    sudo iptables -A INPUT -p tcp --dport $BACKEND_PORT -s $PROXY_IP -j ACCEPT
    # От всех остальных - блокируем
    # === Правила для PostgreSQL (порт 5432) ===
    # Принимаем подключения ТОЛЬКО от Backend (localhost, так как на одной ВМ)
    sudo iptables -A INPUT -p tcp --dport $POSTGRES_PORT -s 127.0.0.1 -j ACCEPT
    # Блокируем все внешние подключения к PostgreSQL
    # (политика DROP уже это делает)
    echo "Настройка Ubuntu завершена"
}

# === Функция для CentOS ===
configure_centos() {
    echo "Настройка CentOS (ВМ2: Proxy + Redis)..."
    # Останавливаем firewalld (используем iptables)
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
    # Устанавливаем iptables-services если нужно
    sudo yum install -y iptables-services
    # Сбрасываем все правила
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    # Политика по умолчанию - DROP для входящих, ACCEPT для исходящих
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    # Разрешаем localhost
    sudo iptables -A INPUT -i lo -j ACCEPT
    # Разрешаем установленные соединения
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    # Разрешаем SSH
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    # === Правила для Proxy (порт 5000) ===
    # Принимаем запросы от любого источника (как требуется в ТЗ)
    sudo iptables -A INPUT -p tcp --dport $PROXY_PORT -j ACCEPT
    # === Правила для Redis (порт 6379) ===
    # Redis доступен только локально (для прокси на той же ВМ)
    sudo iptables -A INPUT -p tcp --dport $REDIS_PORT -s 127.0.0.1 -j ACCEPT
    # Блокируем внешний доступ к Redis
    echo "Настройка CentOS завершена"
}

# === Определяем, где запущен скрипт ===
if [[ $MY_IP == $BACKEND_IP ]]; then
    configure_ubuntu
elif [[ $MY_IP == $PROXY_IP ]]; then
    configure_centos
else
    echo "Неизвестный IP: $MY_IP"
    echo "Пожалуйста, укажите роль вручную:"
    echo "  ./rules.sh ubuntu"
    echo "  ./rules.sh centos"
    exit 1
fi

# Сохраняем правила (чтобы не сбросились после перезагрузки)
if [[ $MY_IP == $BACKEND_IP ]]; then
    # Для Ubuntu
    sudo apt-get install -y iptables-persistent
    sudo netfilter-persistent save
elif [[ $MY_IP == $PROXY_IP ]]; then
    # Для CentOS
    sudo service iptables save
    sudo systemctl enable iptables
fi

echo "Настройка сетевого взаимодействия завершена"
