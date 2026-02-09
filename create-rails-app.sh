#!/bin/bash
set -e

# Определяем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Загружаем конфигурацию
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    log_warn "Файл config.sh не найден, используются значения по умолчанию"
    APPS_INSTALL_DIR="$(dirname "$SCRIPT_DIR")"
    DEFAULT_RUBY_VERSION="3.3.6"
    RAILS_VERSION_CONSTRAINT="~> 8.0"
    DEFAULT_WEB_PORT=3001
    DEFAULT_POSTGRES_PORT=5432
    DEFAULT_ADMINER_PORT=8081
    POSTGRES_IMAGE="postgres:13.9-alpine"
    SELENIUM_IMAGE="selenium/standalone-chrome:112.0-20230421"
    ADMINER_IMAGE="adminer:4.8.1"
fi

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Функция для замены плейсхолдеров в шаблоне
process_template() {
    local template_file=$1
    local output_file=$2
    
    if [ ! -f "$template_file" ]; then
        log_error "Шаблон не найден: $template_file"
        exit 1
    fi
    
    sed -e "s|__RUBY_VERSION__|$RUBY_VERSION|g" \
        -e "s|__POSTGRES_IMAGE__|$POSTGRES_IMAGE|g" \
        -e "s|__SELENIUM_IMAGE__|$SELENIUM_IMAGE|g" \
        -e "s|__ADMINER_IMAGE__|$ADMINER_IMAGE|g" \
        -e "s|__MASTER_KEY__|$MASTER_KEY|g" \
        -e "s|__DB_USER__|$DB_USER|g" \
        -e "s|__DB_PASSWORD__|$DB_PASSWORD|g" \
        -e "s|__WEB_PORT__|$DEFAULT_WEB_PORT|g" \
        -e "s|__POSTGRES_PORT__|$DEFAULT_POSTGRES_PORT|g" \
        -e "s|__ADMINER_PORT__|$DEFAULT_ADMINER_PORT|g" \
        "$template_file" > "$output_file"
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    log_error "Укажите имя приложения"
    echo "Использование: $0 <app_name> [ruby_version] [install_dir] [--boilerplate]"
    echo "Пример: $0 my_rails_app 3.3.6"
    echo "Пример с путём: $0 my_rails_app 3.3.6 /path/to/install"
    echo "Пример с boilerplate: $0 my_rails_app 3.3.6 --boilerplate"
    echo ""
    echo "Опции:"
    echo "  --boilerplate  Установить rails8_boilerplate (конфиги будут перезаписаны генератором)"
    echo ""
    echo "Текущая директория установки: $APPS_INSTALL_DIR"
    exit 1
fi

# Парсинг аргументов
USE_BOILERPLATE=false
APP_NAME=$1
RUBY_VERSION=""
CUSTOM_INSTALL_DIR=""

# Обработка остальных аргументов
shift
while [ $# -gt 0 ]; do
    case $1 in
        --boilerplate)
            USE_BOILERPLATE=true
            ;;
        *)
            if [ -z "$RUBY_VERSION" ]; then
                RUBY_VERSION=$1
            elif [ -z "$CUSTOM_INSTALL_DIR" ]; then
                CUSTOM_INSTALL_DIR=$1
            fi
            ;;
    esac
    shift
done

# Установка значений по умолчанию
RUBY_VERSION=${RUBY_VERSION:-$DEFAULT_RUBY_VERSION}
CUSTOM_INSTALL_DIR=${CUSTOM_INSTALL_DIR:-""}

# Определяем директорию установки
if [ -n "$CUSTOM_INSTALL_DIR" ]; then
    APP_DIR="$CUSTOM_INSTALL_DIR/$APP_NAME"
else
    APP_DIR="$APPS_INSTALL_DIR/$APP_NAME"
fi

log_info "Создание Rails приложения: $APP_NAME"
log_info "Версия Ruby: $RUBY_VERSION"
log_info "Директория установки: $APP_DIR"
if [ "$USE_BOILERPLATE" = true ]; then
    log_info "Режим: с установкой rails8_boilerplate"
fi

# Проверка существования директории
if [ -d "$APP_DIR" ]; then
    log_error "Директория $APP_DIR уже существует"
    exit 1
fi

# Создание директории
log_info "Создание директории проекта..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Генерация Rails приложения через Docker
log_info "Генерация Rails приложения (это может занять несколько минут)..."
docker run --rm -v "${PWD}:/app" -w /app ruby:$RUBY_VERSION bash -c "gem install rails -v '${RAILS_VERSION_CONSTRAINT}' && rails new . --force --database=postgresql --skip-bundle"

# Переименование стандартного Dockerfile
log_info "Настройка Docker файлов..."
if [ -f "Dockerfile" ]; then
    mv Dockerfile Dockerfile.sample
fi

# Копирование и обработка Dockerfile шаблонов
log_info "Создание Dockerfile.development..."
process_template "$TEMPLATES_DIR/docker/Dockerfile.development" "Dockerfile.development"

log_info "Создание Dockerfile.production..."
process_template "$TEMPLATES_DIR/docker/Dockerfile.production" "Dockerfile.production"

# Создание entrypoint скриптов
log_info "Создание entrypoint скриптов..."

# Переименование стандартного entrypoint
if [ -f "bin/docker-entrypoint" ]; then
    mv bin/docker-entrypoint bin/docker-entrypoint.sample
fi

cp "$TEMPLATES_DIR/bin/docker-entrypoint-dev" "bin/docker-entrypoint-dev"
chmod +x bin/docker-entrypoint-dev

cp "$TEMPLATES_DIR/bin/docker-entrypoint" "bin/docker-entrypoint"
chmod +x bin/docker-entrypoint

# Генерация паролей
log_info "Генерация паролей..."
DB_USER="postgres"
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Получение RAILS_MASTER_KEY
MASTER_KEY=""
if [ -f "config/master.key" ]; then
    MASTER_KEY=$(cat config/master.key)
    rm config/master.key
    log_info "RAILS_MASTER_KEY перенесён из config/master.key"
fi

# Создание docker-compose файлов
log_info "Создание docker-compose файлов..."
process_template "$TEMPLATES_DIR/docker/docker-compose.yml" "docker-compose.yml"
process_template "$TEMPLATES_DIR/docker/docker-compose.development.yml" "docker-compose.development.yml"
process_template "$TEMPLATES_DIR/docker/docker-compose.production.yml" "docker-compose.production.yml"

# Создание .env файла
log_info "Создание .env файла..."
process_template "$TEMPLATES_DIR/config/env.template" ".env"

# Настройка database.yml
log_info "Настройка database.yml..."
if [ -f "config/database.yml" ]; then
    mv config/database.yml config/database.yml.sample
fi

cp "$TEMPLATES_DIR/config/database.yml" "config/database.yml"

if [ "$USE_BOILERPLATE" = true ]; then
    log_info "Docker конфиги созданы и будут перезаписаны при установке boilerplate..."
fi

# Добавление rails8_boilerplate в Gemfile если выбрана опция
if [ "$USE_BOILERPLATE" = true ]; then
    log_info "Добавление rails8_boilerplate в Gemfile..."
    # Добавляем гем в конец Gemfile
    echo "" >> Gemfile
    echo "# Rails 8 Boilerplate" >> Gemfile
    echo "gem 'rails8_boilerplate', git: 'https://github.com/infernaLwizarD/rails8_boilerplate.git'" >> Gemfile
fi

# Создание пустого Gemfile.lock для Docker build
log_info "Создание Gemfile.lock..."
touch Gemfile.lock

# Сборка образа
log_info "Сборка Docker образа..."
docker compose build

# Установка зависимостей
log_info "Установка зависимостей..."
docker compose run --rm web bundle install

# Установка и настройка boilerplate если выбрана опция
if [ "$USE_BOILERPLATE" = true ]; then
    log_info "Установка rails8_boilerplate..."
    docker compose run --rm web rails generate rails8_boilerplate:install
    
    log_info "Выполнение миграций..."
    docker compose run --rm web rails db:migrate
    
    log_info "Заполнение базы данных..."
    docker compose run --rm web rails db:seed
else
    # Создание БД
    log_info "Создание баз данных..."
    docker compose run --rm web rails db:create
fi

# Финальное сообщение
echo ""
log_info "✨ Rails приложение '$APP_NAME' успешно создано!"
echo ""
echo "Детали:"
echo "  Директория: $APP_DIR"
echo "  Ruby версия: $RUBY_VERSION"
echo "  DB пользователь: $DB_USER"
echo "  DB пароль: $DB_PASSWORD"
echo ""
echo "Для запуска приложения:"
echo "  cd $APP_DIR"
echo "  docker compose up"
echo ""
echo "Приложение будет доступно по адресу: http://localhost:$DEFAULT_WEB_PORT"
echo "Adminer (для управления БД): http://localhost:$DEFAULT_ADMINER_PORT"

if [ "$USE_BOILERPLATE" = true ]; then
    echo ""
    echo "✨ Rails 8 Boilerplate установлен и настроен!"
    echo "Примечание: Конфигурационные файлы могли быть изменены генератором boilerplate."
fi

echo ""
