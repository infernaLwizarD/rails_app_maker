#!/bin/bash
# Конфигурация для create-rails-app.sh

# Директория, где будут создаваться Rails приложения
# По умолчанию - родительская директория от скрипта
APPS_INSTALL_DIR="${APPS_INSTALL_DIR:-$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")}"

# Версия Ruby по умолчанию
DEFAULT_RUBY_VERSION="3.3.6"

# Версия Rails
RAILS_VERSION_CONSTRAINT="~> 8.0"

# Порты по умолчанию
DEFAULT_WEB_PORT=3001
DEFAULT_POSTGRES_PORT=5432
DEFAULT_ADMINER_PORT=8081

# Образы Docker
POSTGRES_IMAGE="postgres:13.9-alpine"
SELENIUM_IMAGE="selenium/standalone-chrome:112.0-20230421"
ADMINER_IMAGE="adminer:4.8.1"
