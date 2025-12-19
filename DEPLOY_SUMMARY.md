# 📋 Сводка по деплою

## ✅ Конфигурация деплоя

**Репозиторий**: [3dstepansky/tg_master_0.02](https://github.com/3dstepansky/tg_master_0.02)  
**Ветка для деплоя**: `tg_master+`  
**Версия**: 0.1.0

## 📦 Созданные файлы для деплоя

Все файлы находятся в директории `tg_master_0.02/`:

1. ✅ **Dockerfile** - Docker образ на базе Node.js 20 Alpine
2. ✅ **docker-compose.yml** - Конфигурация для запуска контейнера
3. ✅ **.dockerignore** - Исключение ненужных файлов из образа
4. ✅ **deploy.sh** - Скрипт автоматического деплоя
5. ✅ **README_DEPLOY.md** - Подробная инструкция по деплою
6. ✅ **README.md** - Описание версии и проекта
7. ✅ **.env.example** - Пример файла переменных окружения

## 🚀 Быстрый деплой на сервер

### На сервере выполните:

```bash
# Скачайте скрипт деплоя
curl -O https://raw.githubusercontent.com/3dstepansky/tg_master_0.02/tg_master%2B/deploy.sh

# Сделайте его исполняемым
chmod +x deploy.sh

# Запустите деплой (автоматически использует ветку tg_master+)
./deploy.sh
```

Скрипт автоматически:
- Клонирует/обновит репозиторий из ветки `tg_master+`
- Соберёт Docker образ
- Запустит контейнер с приложением
- Проверит работоспособность

## ⚙️ Настройка перед первым запуском

Создайте файл `.env` в директории `tg_master_0.02/` на сервере:

```env
PORT=8080
ADMIN_TOKEN=your_secure_admin_token_here
API_ID=your_telegram_api_id
API_HASH=your_telegram_api_hash
```

## 📝 Команды для управления

```bash
# Просмотр логов
docker logs -f tg-master-api

# Остановка
cd ~/tg-master/tg_master_0.02
docker-compose down

# Перезапуск
docker-compose restart

# Обновление до последней версии
./deploy.sh tg_master+
```

## 🔗 Полезные ссылки

- **Репозиторий**: https://github.com/3dstepansky/tg_master_0.02
- **Ветка деплоя**: https://github.com/3dstepansky/tg_master_0.02/tree/tg_master%2B
- **Инструкция по деплою**: [README_DEPLOY.md](./README_DEPLOY.md)
- **Описание проекта**: [README.md](./README.md)

## ✅ Готово к деплою!

Все файлы настроены и готовы к использованию. Просто выполните команды выше на вашем сервере.

