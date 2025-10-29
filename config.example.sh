#!/bin/bash
# Пример конфигурации для create-rails-app.sh
# Скопируйте этот файл в config.sh и настройте под себя

# Директория, где будут создаваться Rails приложения
# По умолчанию - родительская директория от скрипта (т.е. /home/username/projects)
# Можно указать любой путь, например:
# APPS_INSTALL_DIR="/home/username/my_rails_projects"
APPS_INSTALL_DIR="${APPS_INSTALL_DIR:-$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")}"

# Версия Ruby по умолчанию
DEFAULT_RUBY_VERSION="3.3.6"

# Версия Rails
# "~> 8.0" - последняя версия 8.x, но не 9.x
# "~> 7.0" - последняя версия 7.x
RAILS_VERSION_CONSTRAINT="~> 8.0"

# Порты по умолчанию
DEFAULT_WEB_PORT=3001
DEFAULT_POSTGRES_PORT=5432
DEFAULT_ADMINER_PORT=8081

# Образы Docker
POSTGRES_IMAGE="postgres:13.9-alpine"
SELENIUM_IMAGE="selenium/standalone-chrome:112.0-20230421"
ADMINER_IMAGE="adminer:4.8.1"
