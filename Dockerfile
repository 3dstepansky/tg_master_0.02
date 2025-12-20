# @file: Dockerfile
# @description: Production-ready образ tg-master API на базе Node.js 20 Alpine.
# @dependencies: node:20-alpine, npm ci
# @created: 2025-12-20

# Dockerfile для tg-master API
# Создает production-ready контейнер с Node.js и всеми зависимостями
FROM node:20-alpine

WORKDIR /app

# Копируем package.json и package-lock.json для установки зависимостей
COPY package*.json ./

# Устанавливаем зависимости
RUN npm ci --only=production

# Копируем исходный код
COPY *.js ./

# Создаем директорию для данных (сессии Telegram)
RUN mkdir -p /app/data/sessions

# Устанавливаем переменные окружения по умолчанию
ENV PORT=8080
ENV DATA_DIR=/app/data
ENV NODE_ENV=production

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["node", "server.js"]

