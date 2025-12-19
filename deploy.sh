#!/bin/bash

# Скрипт автоматического деплоя tg-master на сервер
# Использование: ./deploy.sh [branch_name]
# По умолчанию использует ветку 'tg_master+'

set -e  # Остановка при ошибке

BRANCH=${1:-tg_master+}
PROJECT_DIR="tg-master"
REPO_URL="https://github.com/3dstepansky/tg_master_0.02.git"

echo "🚀 Начинаем деплой tg-master из ветки: $BRANCH"

# Проверяем наличие Docker и Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Установите Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose не установлен. Установите Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Определяем команду docker compose (может быть docker-compose или docker compose)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Создаём директорию проекта, если её нет
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📁 Создаём директорию проекта: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    echo "📥 Клонируем репозиторий..."
    git clone "$REPO_URL" .
else
    echo "📁 Переходим в директорию проекта: $PROJECT_DIR"
    cd "$PROJECT_DIR"
    echo "🔄 Обновляем репозиторий..."
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
fi

# Переходим в директорию с кодом (если репозиторий содержит tg_master_0.02)
# Если репозиторий уже содержит файлы напрямую, остаёмся в корне
if [ -d "tg_master_0.02" ]; then
    cd tg_master_0.02
    echo "📁 Переходим в директорию tg_master_0.02"
else
    echo "📁 Используем корневую директорию репозитория"
fi

# Проверяем наличие необходимых файлов
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile не найден!"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml не найден!"
    exit 1
fi

# Проверяем наличие .env файла
if [ ! -f ".env" ]; then
    echo "⚠️  Файл .env не найден. Создайте его с необходимыми переменными окружения."
    echo "📝 Пример .env файла:"
    echo "   PORT=8080"
    echo "   ADMIN_TOKEN=your_admin_token_here"
    echo "   API_ID=your_api_id"
    echo "   API_HASH=your_api_hash"
    echo ""
    read -p "Продолжить без .env файла? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Создаём директорию для данных, если её нет
mkdir -p data/sessions
chmod 755 data
chmod 755 data/sessions

echo "🔨 Останавливаем существующие контейнеры..."
$DOCKER_COMPOSE down || true

echo "🏗️  Собираем Docker образ..."
$DOCKER_COMPOSE build --no-cache

echo "🚀 Запускаем контейнеры..."
$DOCKER_COMPOSE up -d

echo "⏳ Ждём запуска контейнера (10 секунд)..."
sleep 10

# Проверяем статус контейнера
if docker ps | grep -q tg-master-api; then
    echo "✅ Контейнер успешно запущен!"
    echo ""
    echo "📊 Статус контейнера:"
    docker ps | grep tg-master-api
    echo ""
    echo "📋 Логи (последние 20 строк):"
    docker logs --tail 20 tg-master-api
    echo ""
    echo "🌐 Проверка health endpoint:"
    PORT=${PORT:-8080}
    curl -s http://localhost:$PORT/v1/health || echo "⚠️  Health check не прошёл (возможно, приложение ещё запускается)"
    echo ""
    echo "✨ Деплой завершён успешно!"
    echo ""
    echo "📝 Полезные команды:"
    echo "   Просмотр логов: docker logs -f tg-master-api"
    echo "   Остановка: cd $PROJECT_DIR/tg_master_0.02 && $DOCKER_COMPOSE down"
    echo "   Перезапуск: cd $PROJECT_DIR/tg_master_0.02 && $DOCKER_COMPOSE restart"
    echo "   Обновление: ./deploy.sh $BRANCH"
else
    echo "❌ Контейнер не запустился. Проверьте логи:"
    docker logs tg-master-api
    exit 1
fi

