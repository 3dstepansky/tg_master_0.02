# Используем официальный Node.js образ
FROM node:20-alpine

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем package.json и package-lock.json (если есть)
COPY package*.json ./

# Устанавливаем зависимости
# Используем npm ci если есть package-lock.json, иначе npm install
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# Копируем весь код приложения
COPY . .

# Создаём директории для данных и сессий
RUN mkdir -p /app/data/sessions

# Открываем порт (по умолчанию 8080, но можно изменить через переменную окружения)
EXPOSE 8080

# Запускаем приложение
CMD ["npm", "start"]

