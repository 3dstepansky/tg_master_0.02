# Инструкция по деплою tg-master на выделенный сервер

## 📋 Требования

- Выделенный сервер с Linux (Ubuntu/Debian рекомендуется)
- SSH доступ к серверу
- Docker и Docker Compose установлены на сервере
- Git установлен на сервере
- Минимум 2GB RAM, 10GB свободного места

## 🚀 Быстрый старт

### 1. Подключитесь к серверу через SSH

```bash
ssh user@your-server-ip
```

### 2. Запустите скрипт деплоя

```bash
# Скачайте скрипт деплоя
curl -O https://raw.githubusercontent.com/3dstepansky/tg_master_0.02/tg_master%2B/deploy.sh

# Сделайте его исполняемым
chmod +x deploy.sh

# Запустите деплой (по умолчанию из ветки tg_master+)
./deploy.sh

# Или укажите конкретную ветку
./deploy.sh production
```

Скрипт автоматически:
- ✅ Клонирует/обновит репозиторий из GitHub
- ✅ Соберёт Docker образ
- ✅ Запустит контейнер с приложением
- ✅ Проверит работоспособность

## ⚙️ Настройка переменных окружения

Перед первым запуском создайте файл `.env` в директории `tg_master_0.02/`:

```bash
cd tg-master/tg_master_0.02
nano .env
```

Добавьте необходимые переменные:

```env
# Обязательные
PORT=8080
ADMIN_TOKEN=your_secure_admin_token_here

# Telegram API credentials (опционально)
# Обычно передаются в каждом запросе из n8n в body
# Используются только как fallback, если не переданы в запросе
# API_ID=your_telegram_api_id
# API_HASH=your_telegram_api_hash

# Опциональные (значения по умолчанию указаны)
SAFE_BASE_DELAY_MS=950
CHECKER_MIN_INTERVAL_MS=1000
CHECKER_MAX_INTERVAL_MS=5000
CHECKER_MAX_PER_MIN=30
DEBUG_GROUPS=0
STANDALONE_GROUPS=0
```

## 📁 Структура после деплоя

```
~/tg-master/
├── tg_master_0.02/
│   ├── .env                    # Переменные окружения (создайте вручную)
│   ├── data/                   # Автоматически создаётся
│   │   └── sessions/          # Сессии Telegram (персистентные)
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── deploy.sh
│   └── ... (остальные файлы проекта)
```

## 🔧 Управление контейнером

### Просмотр логов

```bash
cd ~/tg-master/tg_master_0.02
docker logs -f tg-master-api
```

### Остановка

```bash
cd ~/tg-master/tg_master_0.02
docker-compose down
```

### Перезапуск

```bash
cd ~/tg-master/tg_master_0.02
docker-compose restart
```

### Обновление до последней версии

```bash
cd ~/tg-master/tg_master_0.02
./deploy.sh tg_master+  # или другая ветка
```

### Проверка статуса

```bash
docker ps | grep tg-master-api
docker logs --tail 50 tg-master-api
```

## 🌐 Проверка работоспособности

После деплоя проверьте health endpoint:

```bash
curl http://localhost:8080/v1/health
```

Ожидаемый ответ:
```json
{
  "success": true,
  "data": {
    "status": "ok"
  },
  "meta": null,
  "error": null
}
```

## 🔒 Безопасность

1. **ADMIN_TOKEN**: Используйте сложный случайный токен (обязательно)
   - Этот токен используется для авторизации всех API запросов
   - Передаётся в заголовке `Authorization: Bearer <token>`
2. **API_ID и API_HASH**: Обычно не нужны в .env
   - Эти данные передаются в каждом запросе из n8n в body запроса
   - Переменные окружения используются только как fallback
   ```bash
   openssl rand -hex 32
   ```

2. **Firewall**: Настройте firewall для ограничения доступа к порту
   ```bash
   # Разрешить доступ только с определённых IP
   sudo ufw allow from YOUR_IP to any port 8080
   ```

3. **HTTPS**: Рекомендуется использовать reverse proxy (nginx) с SSL сертификатом

## 🐛 Решение проблем

### Контейнер не запускается

```bash
# Проверьте логи
docker logs tg-master-api

# Проверьте переменные окружения
docker exec tg-master-api env | grep -E "PORT|ADMIN_TOKEN|API"
```

### Порт уже занят

Измените порт в `.env`:
```env
PORT=8081
```

Или остановите процесс, занимающий порт:
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

### Проблемы с правами доступа

```bash
# Убедитесь, что директория data доступна
chmod -R 755 ~/tg-master/tg_master_0.02/data
```

### Обновление Docker образа

```bash
cd ~/tg-master/tg_master_0.02
docker-compose build --no-cache
docker-compose up -d
```

## 📊 Мониторинг

### Проверка использования ресурсов

```bash
docker stats tg-master-api
```

### Проверка здоровья контейнера

```bash
docker inspect tg-master-api | grep -A 10 Health
```

## 🔄 Автоматическое обновление

Для автоматического обновления при push в GitHub можно настроить webhook или использовать cron:

```bash
# Добавьте в crontab (обновление каждый день в 3:00)
0 3 * * * cd ~/tg-master/tg_master_0.02 && ./deploy.sh tg_master+ >> /var/log/tg-master-deploy.log 2>&1
```

## 📝 Дополнительная информация

- **Версия**: 0.1.0
- **Node.js**: 20 (Alpine)
- **Порт по умолчанию**: 8080
- **Документация API**: см. `docs/Project.md` в репозитории

## 🆘 Поддержка

При возникновении проблем:
1. Проверьте логи: `docker logs tg-master-api`
2. Проверьте переменные окружения в `.env`
3. Убедитесь, что все зависимости установлены
4. Проверьте документацию в `docs/` директории репозитория

