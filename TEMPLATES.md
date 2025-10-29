# Работа с шаблонами

## Структура шаблонов

Все шаблоны находятся в директории `templates/` и организованы по категориям:

- `templates/docker/` — Docker и docker-compose файлы
- `templates/bin/` — Исполняемые скрипты
- `templates/config/` — Конфигурационные файлы

## Плейсхолдеры

В шаблонах используются плейсхолдеры, которые автоматически заменяются на значения из `config.sh`:

| Плейсхолдер | Описание | Источник |
|-------------|----------|----------|
| `__RUBY_VERSION__` | Версия Ruby | Аргумент скрипта или `DEFAULT_RUBY_VERSION` |
| `__POSTGRES_IMAGE__` | Docker образ PostgreSQL | `POSTGRES_IMAGE` из config.sh |
| `__SELENIUM_IMAGE__` | Docker образ Selenium | `SELENIUM_IMAGE` из config.sh |
| `__ADMINER_IMAGE__` | Docker образ Adminer | `ADMINER_IMAGE` из config.sh |
| `__MASTER_KEY__` | Rails master key | Из `config/master.key` |
| `__DB_USER__` | Пользователь БД | Генерируется скриптом |
| `__DB_PASSWORD__` | Пароль БД | Генерируется скриптом |
| `__WEB_PORT__` | Порт веб-сервера | `DEFAULT_WEB_PORT` из config.sh |
| `__POSTGRES_PORT__` | Порт PostgreSQL | `DEFAULT_POSTGRES_PORT` из config.sh |
| `__ADMINER_PORT__` | Порт Adminer | `DEFAULT_ADMINER_PORT` из config.sh |

## Добавление нового шаблона

### 1. Создайте файл шаблона

```bash
# Например, добавим шаблон для Redis
cat > templates/docker/docker-compose.redis.yml <<'EOF'
services:
  redis:
    image: redis:7-alpine
    ports:
      - ${REDIS_PORT:-6379}:6379
    volumes:
      - redis_data:/data

volumes:
  redis_data:
EOF
```

### 2. Добавьте плейсхолдеры (если нужно)

```yaml
services:
  redis:
    image: __REDIS_IMAGE__
    ports:
      - ${REDIS_PORT:-__REDIS_PORT__}:6379
```

### 3. Обновите config.sh

```bash
# Добавьте новые переменные
REDIS_IMAGE="redis:7-alpine"
DEFAULT_REDIS_PORT=6379
```

### 4. Обновите скрипт create-rails-app.sh

Добавьте обработку нового шаблона:

```bash
# В функцию process_template добавьте новый плейсхолдер
-e "s|__REDIS_IMAGE__|$REDIS_IMAGE|g" \
-e "s|__REDIS_PORT__|$DEFAULT_REDIS_PORT|g" \

# В основной код добавьте копирование
log_info "Создание docker-compose.redis.yml..."
process_template "$TEMPLATES_DIR/docker/docker-compose.redis.yml" "docker-compose.redis.yml"
```
