# Rails App Maker

Автоматизация создания Rails приложений с настроенным Docker окружением.

## Установка

```bash
git clone <repository-url> rails_app_maker
cd rails_app_maker
chmod +x create-rails-app.sh
```

## Структура проекта

```
rails_app_maker/
├── create-rails-app.sh       # Основной скрипт
├── config.sh                 # Конфигурация
├── config.example.sh         # Пример конфигурации
├── README.md
└── templates/                # Шаблоны файлов
    ├── docker/
    │   ├── Dockerfile.development
    │   ├── Dockerfile.production
    │   ├── docker-compose.yml
    │   ├── docker-compose.development.yml
    │   └── docker-compose.production.yml
    ├── bin/
    │   ├── docker-entrypoint
    │   └── docker-entrypoint-dev
    └── config/
        ├── database.yml
        └── env.template
```

## Конфигурация

Настройки находятся в файле `config.sh`:

- **APPS_INSTALL_DIR** — директория для создания приложений (по умолчанию: родительская директория от скрипта)
- **DEFAULT_RUBY_VERSION** — версия Ruby по умолчанию
- **RAILS_VERSION_CONSTRAINT** — версия Rails
- **Порты и образы Docker** — настройки для PostgreSQL, Selenium, Adminer

## Кастомизация шаблонов

Все файлы в директории `templates/` можно редактировать под свои нужды:

- **Docker файлы** — добавить дополнительные пакеты или настройки
- **docker-compose** — изменить сервисы, порты, volumes
- **Entrypoint скрипты** — добавить свою логику инициализации
- **Конфигурационные файлы** — настроить database.yml или .env

Плейсхолдеры в шаблонах (например, `__RUBY_VERSION__`) автоматически заменяются на значения из `config.sh`.

## Использование

### create-rails-app.sh

**Базовое использование:**
```bash
./create-rails-app.sh <app_name> [ruby_version] [install_dir]
```

**Примеры:**
```bash
# С настройками по умолчанию (Ruby 3.3.6, установка в родительскую директорию)
./create-rails-app.sh my_awesome_app

# С указанием версии Ruby
./create-rails-app.sh my_awesome_app 3.3.5

# С указанием директории установки
./create-rails-app.sh my_awesome_app 3.3.6 /home/user/projects

# Или через переменную окружения
APPS_INSTALL_DIR=/custom/path ./create-rails-app.sh my_app
```

**Что делает скрипт:**
- Создаёт новое Rails приложение через Docker (не требует установленной Ruby/Rails в системе)
- Конфигурирует Docker для development и production
- Настраивает PostgreSQL с автогенерацией паролей
- Конфигурирует database.yml
- Создаёт entrypoint скрипты для контейнеров
- Переносит RAILS_MASTER_KEY в .env файл
- Собирает Docker образ и устанавливает зависимости
- Создаёт базы данных

**После создания:**
```bash
cd /home/username/projects/<app_name>
docker compose up
```

Приложение доступно по адресу: `http://localhost:3001`  
Adminer (управление БД): `http://localhost:8081`

## Требования

- Docker
- Docker Compose
- openssl (для генерации паролей)

## Структура проекта

По умолчанию скрипт создаёт приложения в родительской директории (т.е. если скрипт находится в `/home/username/projects/rails_app_maker/`, приложения будут создаваться в `/home/username/projects/`).

Можно изменить это поведение:
1. Отредактировав `APPS_INSTALL_DIR` в `config.sh`
2. Передав путь третьим аргументом: `./create-rails-app.sh myapp 3.3.6 /custom/path`
3. Через переменную окружения: `APPS_INSTALL_DIR=/custom/path ./create-rails-app.sh myapp`

## Работа из любой директории

Скрипт можно запускать из любой директории:

```bash
# Добавьте в PATH или создайте alias
alias make-rails-app='/home/username/projects/rails_app_maker/create-rails-app.sh'

# Теперь можно использовать откуда угодно
cd ~/anywhere
make-rails-app my_project
```
