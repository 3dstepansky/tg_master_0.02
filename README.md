# tg-master API v0.1.0

REST API сервис для работы с Telegram API через Node.js и Express.

## 📦 Версия

**Текущая версия**: 0.1.0  
**Дата релиза**: 2025-12-06  
**Ветка**: `main` / `production`

## 🚀 Быстрый старт

### Локальный запуск

```bash
npm install
npm start
```

### Docker запуск

```bash
docker-compose up -d
```

Подробная инструкция по деплою: [README_DEPLOY.md](./README_DEPLOY.md)

## 📋 Основные возможности

- ✅ **Управление сессиями Telegram**: авторизация, сохранение, проверка
- ✅ **Проверка пользователей**: разрешение по username, user_id, телефону
- ✅ **Конвертация групп/каналов**: получение списка участников
- ✅ **Парсинг участников**: гибридный подход (GetParticipants + GetHistory) с полной пагинацией
- ✅ **Классификация групп**: определение статуса parsable/NonParsing

## 🔧 API Endpoints

### Health Check
```
GET /v1/health
```

### Управление сессиями
```
POST /v1/auth/login
POST /v1/auth/check
POST /v1/auth/delete
```

### Проверка пользователей
```
POST /v1/checker/resolve
POST /v1/checker/batch
```

### Конвертация групп
```
POST /v1/converter/members
```

### Парсинг
```
POST /v1/parsing/linked/resolve
POST /v1/parsing/members/sample
```

### Классификация групп
```
POST /v1/groups/summary
```

## ⚙️ Переменные окружения

### Обязательные
- `PORT` - Порт для запуска сервера (по умолчанию: 8080)
- `ADMIN_TOKEN` - Токен для авторизации API запросов (передаётся в заголовке `Authorization: Bearer <token>`)

### Опциональные (обычно передаются из n8n)
- `API_ID` / `TG_API_ID` - Telegram API ID (обычно передаётся в body каждого запроса из n8n)
- `API_HASH` / `TG_API_HASH` - Telegram API Hash (обычно передаётся в body каждого запроса из n8n)
  
  **Примечание**: Переменные окружения используются только как fallback, если данные не переданы в запросе.

### Опциональные
- `SAFE_BASE_DELAY_MS` - Базовая задержка между запросами (по умолчанию: 950ms)
- `CHECKER_MIN_INTERVAL_MS` - Минимальный интервал для checker (по умолчанию: 1000ms)
- `CHECKER_MAX_INTERVAL_MS` - Максимальный интервал для checker (по умолчанию: 5000ms)
- `CHECKER_MAX_PER_MIN` - Максимум запросов в минуту (по умолчанию: 30)
- `DEBUG_GROUPS` - Включить отладочные логи для groups (по умолчанию: 0)
- `STANDALONE_GROUPS` - Запуск groups модуля в standalone режиме (по умолчанию: 0)

## 📁 Структура проекта

```
tg_master_0.02/
├── server.js              # Главный файл приложения
├── account_manager.js     # Управление сессиями Telegram
├── checker.js             # Проверка пользователей
├── converter.js           # Конвертация групп/каналов
├── parsing.js             # Парсинг участников
├── groups.js              # Классификация групп
├── Dockerfile             # Docker образ
├── docker-compose.yml     # Docker Compose конфигурация
├── deploy.sh              # Скрипт автоматического деплоя
└── README_DEPLOY.md       # Инструкция по деплою
```

## 🔒 Безопасность

- Все API endpoints требуют авторизации через `ADMIN_TOKEN` (кроме `/v1/health`)
- Сессии Telegram хранятся локально в директории `data/sessions/`
- Рекомендуется использовать HTTPS через reverse proxy (nginx)

## 📚 Документация

Полная документация проекта находится в директории `docs/`:
- `Project.md` - Архитектура и описание проекта
- `changelog.md` - История изменений
- `qa.md` - Ответы на архитектурные вопросы
- `code_audit.md` - Аудит кода

## 🐳 Docker

### Сборка образа

```bash
docker build -t tg-master:0.1.0 .
```

### Запуск контейнера

```bash
docker-compose up -d
```

### Просмотр логов

```bash
docker logs -f tg-master-api
```

## 🔄 Обновление

Для обновления до новой версии:

```bash
# Локально
git pull origin main
npm install
npm start

# Docker
./deploy.sh main
```

## 🆘 Поддержка

При возникновении проблем:
1. Проверьте логи приложения
2. Убедитесь, что все переменные окружения установлены
3. Проверьте документацию в `docs/`
4. Проверьте health endpoint: `GET /v1/health`

## 📝 Лицензия

Проект для внутреннего использования.

## 👥 Авторы

Разработано для автоматизации работы с Telegram API.

---

**Версия**: 0.1.0  
**Последнее обновление**: 2025-12-06

