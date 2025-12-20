# Инструкция по деплою tg-master API на удаленный сервер

## Оглавление

1. [Подготовка сервера](#подготовка-сервера)
2. [Подготовка проекта](#подготовка-проекта)
3. [Деплой через SSH](#деплой-через-ssh)
4. [Настройка переменных окружения](#настройка-переменных-окружения)
5. [Запуск и проверка](#запуск-и-проверка)
6. [Интеграция с n8n](#интеграция-с-n8n)
7. [Решение проблем](#решение-проблем)
8. [Мониторинг и логи](#мониторинг-и-логи)

---

## Подготовка сервера

### Требования к серверу

- **ОС**: Linux (Ubuntu 20.04+ / Debian 11+ / CentOS 8+)
- **RAM**: минимум 512MB (рекомендуется 1GB+)
- **CPU**: 1 ядро (рекомендуется 2+)
- **Диск**: минимум 5GB свободного места
- **Сеть**: открытый порт 8080 (или другой, по вашему выбору)

### Установка Docker и Docker Compose

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление текущего пользователя в группу docker (чтобы не использовать sudo)
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Проверка установки
docker --version
docker-compose --version

# Перезагрузка сессии (чтобы применить изменения группы)
# Выйдите и войдите снова в SSH, или выполните:
newgrp docker
```

---

## Подготовка проекта

### 1. Клонирование/загрузка проекта

**Вариант A: Через Git (если проект в репозитории)**

```bash
git clone <your-repo-url> tg-master
cd tg-master
```

**Вариант B: Загрузка файлов через SCP**

На локальной машине:

```bash
# Создайте архив проекта
tar -czf tg-master.tar.gz \
  *.js \
  package.json \
  package-lock.json \
  Dockerfile \
  docker-compose.yml \
  .gitignore

# Загрузите на сервер
scp tg-master.tar.gz user@your-server-ip:/home/user/
```

На сервере:

```bash
# Распакуйте архив
tar -xzf tg-master.tar.gz -C /opt/tg-master
cd /opt/tg-master
```

### 2. Создание директории для данных

```bash
mkdir -p data/sessions
chmod 755 data
chmod 755 data/sessions
```

---

## Деплой через SSH

### Шаг 1: Подключение к серверу

```bash
ssh user@your-server-ip
```

### Шаг 2: Переход в директорию проекта

```bash
cd /opt/tg-master  # или путь, где вы разместили проект
```

### Шаг 3: Настройка переменных окружения

**ВАЖНО**: Не создавайте `.env` файл! Все секреты передаются через переменные окружения Docker или в теле запросов от n8n.

Создайте файл `.env.docker` (только для локальной настройки docker-compose):

```bash
cat > .env.docker << 'EOF'
# Токен администратора (ОБЯЗАТЕЛЬНО измените!)
ADMIN_TOKEN=REPLACE_ME_STRONG

# Telegram API credentials (опционально, обычно передаются в body)
TG_API_ID=
TG_API_HASH=

# Настройки производительности
SAFE_BASE_DELAY_MS=1200
DEBUG_GROUPS=0
EOF
```

**Или установите переменные окружения напрямую в docker-compose.yml** (см. раздел ниже).

### Шаг 4: Сборка и запуск контейнера

```bash
# Сборка образа
docker-compose build

# Запуск в фоновом режиме
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

---

## Настройка переменных окружения

### Способ 1: Через docker-compose.yml (рекомендуется)

Отредактируйте `docker-compose.yml` и установите значения напрямую:

```yaml
environment:
  - ADMIN_TOKEN=your_strong_token_here
  - PORT=8080
  # TG_API_ID и TG_API_HASH можно не указывать, если передаете в body
```

### Способ 2: Через переменные окружения системы

```bash
# Экспортируйте переменные перед запуском docker-compose
export ADMIN_TOKEN="your_strong_token_here"
export TG_API_ID="your_api_id"  # опционально
export TG_API_HASH="your_api_hash"  # опционально

# Запустите docker-compose
docker-compose up -d
```

### Способ 3: Через .env файл (только для docker-compose)

Создайте `.env` файл в корне проекта (НЕ коммитьте в Git!):

```bash
ADMIN_TOKEN=your_strong_token_here
TG_API_ID=your_api_id
TG_API_HASH=your_api_hash
SAFE_BASE_DELAY_MS=1200
```

Docker Compose автоматически подхватит эти переменные.

---

## Запуск и проверка

### Проверка работоспособности

```bash
# Health check
curl http://localhost:8080/v1/health

# Ожидаемый ответ:
# {"success":true,"data":{"status":"ok"},"meta":null,"error":null}
```

### Проверка с авторизацией

```bash
# С правильным токеном
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  http://localhost:8080/v1/auth/session

# Должен вернуть список сессий (возможно, пустой)
```

### Проверка извне (если порт открыт)

```bash
# С вашего локального компьютера
curl http://your-server-ip:8080/v1/health
```

---

## Интеграция с n8n

### Настройка HTTP Request узлов в n8n

#### 1. Endpoint: `/v1/groups/summary`

**Важно**: API ожидает `api_id` и `api_hash` в теле запроса (JSON), а не в заголовках!

**Правильная конфигурация в n8n:**

```json
{
  "method": "POST",
  "url": "http://your-server-ip:8080/v1/groups/summary",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      {
        "name": "Authorization",
        "value": "Bearer YOUR_ADMIN_TOKEN"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {
        "name": "session_name",
        "value": "={{ $json.session_name }}"
      },
      {
        "name": "api_id",
        "value": "={{ $json.api_id }}"
      },
      {
        "name": "api_hash",
        "value": "={{ $json.api_hash }}"
      },
      {
        "name": "usernames",
        "value": "={{ $json.usernames }}"
      }
    ]
  },
  "options": {
    "response": {
      "response": {
        "fullResponse": true
      }
    }
  }
}
```

**Критически важно:**

1. ✅ Используйте `sendBody: true` и `bodyParameters` (не `sendQuery`!)
2. ✅ Установите `Content-Type: application/json` в заголовках
3. ✅ Передавайте `api_id` и `api_hash` в теле запроса (не в URL параметрах!)
4. ✅ Используйте `Authorization: Bearer TOKEN` в заголовках

#### 2. Endpoint: `/v1/auth/login/start`

```json
{
  "method": "POST",
  "url": "http://your-server-ip:8080/v1/auth/login/start",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      {
        "name": "Authorization",
        "value": "Bearer YOUR_ADMIN_TOKEN"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {
        "name": "phone",
        "value": "={{ $json.phone }}"
      },
      {
        "name": "api_id",
        "value": "={{ $json.api_id }}"
      },
      {
        "name": "api_hash",
        "value": "={{ $json.api_hash }}"
      }
    ]
  }
}
```

#### 3. Endpoint: `/v1/parsing/members/sample`

```json
{
  "method": "POST",
  "url": "http://your-server-ip:8080/v1/parsing/members/sample",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      {
        "name": "Authorization",
        "value": "Bearer YOUR_ADMIN_TOKEN"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {
        "name": "session_name",
        "value": "={{ $json.session_name }}"
      },
      {
        "name": "api_id",
        "value": "={{ $json.api_id }}"
      },
      {
        "name": "api_hash",
        "value": "={{ $json.api_hash }}"
      },
      {
        "name": "username",
        "value": "={{ $json.username }}"
      },
      {
        "name": "limits.history",
        "value": "600"
      },
      {
        "name": "limits.participants",
        "value": "300"
      },
      {
        "name": "window_days",
        "value": "10"
      }
    ]
  }
}
```

### Обновление URL в существующем проекте n8n

Если у вас уже есть проект n8n, замените все вхождения:

- `https://laudable-cooperation-production-9763.up.railway.app` → `http://your-server-ip:8080`
- `http://37.233.83.44:8080` → `http://your-server-ip:8080`

---

## Решение проблем

### Проблема 1: Ошибка 400 "TG_API_ID and TG_API_HASH required"

**Причина**: API не получает `api_id` и `api_hash` из тела запроса.

**Решение**:

1. ✅ Проверьте, что в n8n используется `sendBody: true` (не `sendQuery`)
2. ✅ Убедитесь, что `Content-Type: application/json` установлен в заголовках
3. ✅ Проверьте, что `api_id` и `api_hash` передаются в `bodyParameters`, а не в `queryParameters`
4. ✅ Убедитесь, что значения не пустые и имеют правильный тип (число для api_id, строка для api_hash)

**Правильный формат запроса:**

```bash
curl -X POST http://your-server-ip:8080/v1/groups/summary \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "session_name": "my-session",
    "api_id": 12345678,
    "api_hash": "abcdef1234567890",
    "usernames": ["@testgroup"]
  }'
```

### Проблема 2: Ошибка 401 "Missing or invalid ADMIN_TOKEN"

**Причина**: Неправильный токен или токен не передан.

**Решение**:

1. ✅ Проверьте, что `ADMIN_TOKEN` установлен в docker-compose.yml или переменных окружения
2. ✅ Убедитесь, что в n8n используется формат `Bearer TOKEN` (не просто `TOKEN`)
3. ✅ Проверьте, что токен совпадает в обоих местах

**Проверка токена:**

```bash
# Проверьте переменную окружения в контейнере
docker-compose exec tg-master env | grep ADMIN_TOKEN
```

### Проблема 3: Группы классифицируются как "NonParsing" вместо "parsable"

**Причина**: API не может определить, что группа парсится (нет связанного чата или обсуждений).

**Решение**:

1. ✅ Убедитесь, что группа действительно имеет связанный чат для обсуждений (для каналов)
2. ✅ Проверьте, что сессия имеет доступ к группе (пользователь состоит в группе)
3. ✅ Включите debug режим: установите `DEBUG_GROUPS=1` в docker-compose.yml и проверьте логи

**Включение debug режима:**

```yaml
environment:
  - DEBUG_GROUPS=1
```

**Просмотр debug логов:**

```bash
docker-compose logs -f | grep "\[groups\]\[debug\]"
```

### Проблема 4: Проблемы с парсингом body запросов (form-data vs JSON)

**Причина**: n8n отправляет form-data вместо JSON.

**Решение**:

1. ✅ В n8n HTTP Request узле убедитесь, что выбран тип `JSON` для body
2. ✅ Установите заголовок `Content-Type: application/json`
3. ✅ Используйте `bodyParameters` (не `formData`)

**Проверка формата запроса:**

```bash
# Включите логирование входящих запросов (временно)
# Добавьте в server.js перед app.use(express.json()):
app.use((req, res, next) => {
  console.log('Content-Type:', req.headers['content-type']);
  console.log('Body:', JSON.stringify(req.body));
  next();
});
```

### Проблема 5: Сессии не сохраняются после перезапуска

**Причина**: Volume не настроен или путь неправильный.

**Решение**:

1. ✅ Проверьте, что volume настроен в docker-compose.yml:
   ```yaml
   volumes:
     - ./data:/app/data
   ```

2. ✅ Убедитесь, что директория существует и имеет правильные права:
   ```bash
   ls -la data/sessions/
   chmod 755 data/sessions/
   ```

3. ✅ Проверьте, что файлы создаются:
   ```bash
   docker-compose exec tg-master ls -la /app/data/sessions/
   ```

---

## Мониторинг и логи

### Просмотр логов в реальном времени

```bash
# Все логи
docker-compose logs -f

# Только ошибки
docker-compose logs -f | grep -i error

# Логи за последние 100 строк
docker-compose logs --tail=100
```

### Проверка статуса контейнера

```bash
# Статус
docker-compose ps

# Детальная информация
docker-compose exec tg-master ps aux

# Использование ресурсов
docker stats tg-master-api
```

### Перезапуск сервиса

```bash
# Перезапуск без пересборки
docker-compose restart

# Перезапуск с пересборкой
docker-compose up -d --build

# Полная перезагрузка (остановка + запуск)
docker-compose down
docker-compose up -d
```

### Резервное копирование сессий

```bash
# Создание бэкапа
tar -czf sessions-backup-$(date +%Y%m%d).tar.gz data/sessions/

# Восстановление из бэкапа
tar -xzf sessions-backup-YYYYMMDD.tar.gz
```

---

## Безопасность

### Рекомендации

1. ✅ **Измените ADMIN_TOKEN** на сильный случайный токен
2. ✅ **Используйте firewall** для ограничения доступа к порту 8080
3. ✅ **Настройте reverse proxy** (nginx) с SSL/TLS для production
4. ✅ **Регулярно обновляйте** Docker образы и зависимости
5. ✅ **Не коммитьте** `.env` файлы в Git

### Настройка firewall (UFW)

```bash
# Разрешить SSH
sudo ufw allow 22/tcp

# Разрешить порт API (только для вашего IP, если возможно)
sudo ufw allow from YOUR_IP to any port 8080

# Или разрешить всем (менее безопасно)
sudo ufw allow 8080/tcp

# Включить firewall
sudo ufw enable
```

### Настройка Nginx reverse proxy (опционально)

Создайте конфигурацию `/etc/nginx/sites-available/tg-master`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Активируйте:

```bash
sudo ln -s /etc/nginx/sites-available/tg-master /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Быстрая справка

### Основные команды

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Логи
docker-compose logs -f

# Статус
docker-compose ps

# Health check
curl http://localhost:8080/v1/health
```

### Основные endpoints

- `GET /v1/health` - Проверка работоспособности
- `GET /v1/auth/session` - Список сессий
- `POST /v1/auth/login/start` - Начать авторизацию
- `POST /v1/auth/login/verify_code` - Подтвердить код
- `POST /v1/groups/summary` - Классификация групп
- `POST /v1/parsing/members/sample` - Парсинг участников

---

## Поддержка

При возникновении проблем:

1. Проверьте логи: `docker-compose logs -f`
2. Проверьте статус: `docker-compose ps`
3. Проверьте health endpoint: `curl http://localhost:8080/v1/health`
4. Убедитесь, что все переменные окружения установлены правильно
5. Проверьте формат запросов от n8n (JSON, не form-data)

---

**Дата создания**: 2025-12-20  
**Версия документа**: 1.0

