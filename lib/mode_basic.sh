#!/bin/bash
# Режим 1: Базовая установка (выбор опций rails new)
# Требует: source lib/common.sh, source lib/rails_options.sh

run_mode_basic() {
    TOTAL_STEPS=6
    VANILLA_MODE="y"

    # --- Шаг 1: Имя приложения ---
    print_step 1 "Имя приложения"
    print_hint "Латинские буквы, цифры, _ и - (начинается с буквы)"
    prompt_app_name
    APP_NAME="$REPLY_VALUE"
    print_ok "Имя: ${BOLD}$APP_NAME${NC}"
    echo ""
    print_divider
    echo ""

    # --- Шаги 2–5: Опции rails new ---
    prompt_rails_options 2

    echo ""
    print_divider
    echo ""

    # --- Шаг 6: Подтверждение ---
    print_step 6 "Подтверждение"
    echo ""
    show_summary
    echo ""

    prompt_yes_no "Начать создание?" "y"
    CONFIRM="$REPLY_VALUE"
}
