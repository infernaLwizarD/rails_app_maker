#!/bin/bash
# Режимы 2 и 3: Быстрая установка / Быстрая + Boilerplate
# Требует: source lib/common.sh

run_mode_quick() {
    local with_boilerplate="$1"  # "y" или "n"

    TOTAL_STEPS=2

    # --- Шаг 1: Имя приложения ---
    print_step 1 "Имя приложения"
    print_hint "Латинские буквы, цифры, _ и - (начинается с буквы)"
    prompt_app_name
    APP_NAME="$REPLY_VALUE"
    print_ok "Имя: ${BOLD}$APP_NAME${NC}"
    echo ""

    USE_BOILERPLATE="$with_boilerplate"

    # --- Шаг 2: Подтверждение ---
    print_step 2 "Подтверждение"
    echo ""
    show_summary
    echo ""

    prompt_yes_no "Начать создание?" "y"
    CONFIRM="$REPLY_VALUE"
}
