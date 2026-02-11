#!/bin/bash
# Режим 4: Расширенная установка
# Требует: source lib/common.sh, source lib/rails_options.sh

run_mode_advanced() {
    TOTAL_STEPS=10

    # --- Шаг 1: Имя приложения ---
    print_step 1 "Имя приложения"
    print_hint "Латинские буквы, цифры, _ и - (начинается с буквы)"
    prompt_app_name
    APP_NAME="$REPLY_VALUE"
    print_ok "Имя: ${BOLD}$APP_NAME${NC}"
    echo ""
    print_divider
    echo ""

    # --- Шаг 2: Версия Ruby ---
    print_step 2 "Версия Ruby"
    print_hint "Версия образа ruby:X.Y.Z из Docker Hub"
    prompt_ruby_version "$DEFAULT_RUBY_VERSION"
    RUBY_VERSION="$REPLY_VALUE"
    print_ok "Ruby: ${BOLD}$RUBY_VERSION${NC}"
    echo ""
    print_divider
    echo ""

    # --- Шаг 3: Директория установки ---
    print_step 3 "Директория установки"
    print_hint "Абсолютный путь к родительской директории. Приложение будет создано внутри."
    prompt_directory "$APPS_INSTALL_DIR"
    INSTALL_DIR="$REPLY_VALUE"
    print_ok "Путь: ${BOLD}$INSTALL_DIR/$APP_NAME${NC}"
    echo ""
    print_divider
    echo ""

    # --- Шаг 4: Порты ---
    print_step 4 "Настройка портов"
    print_hint "Порты, на которых будут доступны сервисы на хост-машине"
    echo ""

    prompt_port "Порт Rails (веб-сервер)" "$DEFAULT_WEB_PORT"
    WEB_PORT="$REPLY_VALUE"

    prompt_port "Порт PostgreSQL (БД)" "$DEFAULT_POSTGRES_PORT"
    PG_PORT="$REPLY_VALUE"

    prompt_port "Порт Adminer (веб-интерфейс БД)" "$DEFAULT_ADMINER_PORT"
    ADMINER_PORT="$REPLY_VALUE"

    print_ok "Порты: Rails=${BOLD}$WEB_PORT${NC}, PostgreSQL=${BOLD}$PG_PORT${NC}, Adminer=${BOLD}$ADMINER_PORT${NC}"
    echo ""
    print_divider
    echo ""

    # --- Шаги 5–8: Опции rails new ---
    prompt_rails_options 5

    echo ""
    print_divider
    echo ""

    # --- Шаг 9: Boilerplate ---
    print_step 9 "Rails 8 Boilerplate"
    print_hint "Набор готовых конфигов, генераторов и best practices для Rails 8."
    print_hint "Включает: настроенный Devise, RSpec, Rubocop, GitHub Actions и др."
    prompt_yes_no "Установить boilerplate?" "n"
    USE_BOILERPLATE="$REPLY_VALUE"

    if [ "$USE_BOILERPLATE" = "y" ]; then
        print_ok "Boilerplate: ${BOLD}Да${NC}"
    else
        print_ok "Boilerplate: ${BOLD}Нет${NC}"
    fi
    echo ""
    print_divider
    echo ""

    # --- Шаг 10: Подтверждение ---
    print_step 10 "Подтверждение"
    echo ""
    show_summary
    echo ""

    prompt_yes_no "Начать создание?" "y"
    CONFIRM="$REPLY_VALUE"
}
