#!/bin/bash
# Общие функции для setup.sh и модулей установки

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================
# Функции вывода
# ============================================================

print_header() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║         Rails App Maker — Установка          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "  ${CYAN}${BOLD}[$1/$TOTAL_STEPS]${NC} ${BOLD}$2${NC}"
}

print_hint() {
    echo -e "  ${DIM}$1${NC}"
}

print_ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_err() {
    echo -e "  ${RED}✗ $1${NC}"
}

print_divider() {
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
}

# ============================================================
# Функции ввода с валидацией
# ============================================================

# Чтение строки с дефолтом. Результат — в глобальной переменной REPLY_VALUE.
prompt_input() {
    local label="$1"
    local default="$2"
    local input

    if [ -n "$default" ]; then
        echo -ne "  ${BOLD}$label${NC} ${DIM}[$default]${NC}: "
    else
        echo -ne "  ${BOLD}$label${NC}: "
    fi
    read -r input
    REPLY_VALUE="${input:-$default}"
}

# Чтение да/нет. Поддержка: y/n, да/нет, д/н (регистронезависимо).
# Результат — "y" или "n" в REPLY_VALUE.
prompt_yes_no() {
    local label="$1"
    local default="$2"  # "y" или "n"
    local hint input

    if [ "$default" = "y" ]; then
        hint="Д/н"
    else
        hint="д/Н"
    fi

    while true; do
        echo -ne "  ${BOLD}$label${NC} ${DIM}[$hint]${NC}: "
        read -r input
        input="${input:-$default}"

        case "$input" in
            y|Y|yes|YES|Yes|д|Д|да|Да|ДА)  REPLY_VALUE="y"; return ;;
            n|N|no|NO|No|н|Н|нет|Нет|НЕТ)  REPLY_VALUE="n"; return ;;
            *)
                print_err "Введите: да/нет, д/н, y/n"
                ;;
        esac
    done
}

# Чтение имени приложения с валидацией.
prompt_app_name() {
    local input
    while true; do
        echo -ne "  ${BOLD}Имя приложения${NC}: "
        read -r input
        if [ -z "$input" ]; then
            print_err "Имя приложения обязательно"
        elif [[ ! "$input" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            print_err "Допустимы: латинские буквы, цифры, _ и - (начинается с буквы)"
        else
            REPLY_VALUE="$input"
            return
        fi
    done
}

# Чтение версии Ruby с валидацией формата X.Y.Z
prompt_ruby_version() {
    local default="$1"
    local input
    while true; do
        echo -ne "  ${BOLD}Версия Ruby${NC} ${DIM}[$default]${NC}: "
        read -r input
        input="${input:-$default}"
        if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            REPLY_VALUE="$input"
            return
        else
            print_err "Формат версии: X.Y.Z (например, 4.0.1)"
        fi
    done
}

# Чтение порта с валидацией (1–65535)
prompt_port() {
    local label="$1"
    local default="$2"
    local input
    while true; do
        echo -ne "  ${BOLD}$label${NC} ${DIM}[$default]${NC}: "
        read -r input
        input="${input:-$default}"
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le 65535 ]; then
            REPLY_VALUE="$input"
            return
        else
            print_err "Порт должен быть числом от 1 до 65535"
        fi
    done
}

# Чтение пути к директории с валидацией
prompt_directory() {
    local default="$1"
    local input
    while true; do
        echo -ne "  ${BOLD}Директория${NC} ${DIM}[$default]${NC}: "
        read -r input
        input="${input:-$default}"
        # Раскрываем ~ в путь
        input="${input/#\~/$HOME}"
        if [[ "$input" = /* ]]; then
            REPLY_VALUE="$input"
            return
        else
            print_err "Укажите абсолютный путь (начинается с /)"
        fi
    done
}

# Выбор из пронумерованного списка. Результат — значение выбранного элемента в REPLY_VALUE.
# Использование: prompt_choice "label" "default_num" "val1|Описание 1" "val2|Описание 2" ...
prompt_choice() {
    local label="$1"
    local default_num="$2"
    shift 2
    local options=("$@")
    local count=${#options[@]}
    local input i

    echo -e "  ${BOLD}$label:${NC}"
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        local val="${options[$i]%%|*}"
        local desc="${options[$i]#*|}"
        if [ "$num" = "$default_num" ]; then
            echo -e "    ${BOLD}$num)${NC} $val — ${DIM}$desc${NC} ${GREEN}← по умолчанию${NC}"
        else
            echo -e "    ${BOLD}$num)${NC} $val — ${DIM}$desc${NC}"
        fi
    done

    while true; do
        echo -ne "  ${BOLD}Выбор${NC} ${DIM}[$default_num]${NC}: "
        read -r input
        input="${input:-$default_num}"
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "$count" ]; then
            local idx=$((input - 1))
            REPLY_VALUE="${options[$idx]%%|*}"
            return
        else
            print_err "Введите число от 1 до $count"
        fi
    done
}

# ============================================================
# Отображение итоговой конфигурации
# ============================================================

show_summary() {
    echo -e "  ${BOLD}Итоговая конфигурация:${NC}"
    echo -e "    Приложение:      ${BOLD}$APP_NAME${NC}"
    echo -e "    Ruby:            ${BOLD}$RUBY_VERSION${NC}"
    echo -e "    Rails:           ${BOLD}$RAILS_VERSION_CONSTRAINT${NC}"
    echo -e "    Директория:      ${BOLD}$INSTALL_DIR/$APP_NAME${NC}"
    if [ "$VANILLA_MODE" != "y" ]; then
        echo -e "    Порт Rails:      ${BOLD}$WEB_PORT${NC}"
        echo -e "    Порт PostgreSQL:  ${BOLD}$PG_PORT${NC}"
        echo -e "    Порт Adminer:    ${BOLD}$ADMINER_PORT${NC}"
        echo -e "    Boilerplate:     ${BOLD}$([ "$USE_BOILERPLATE" = "y" ] && echo "Да" || echo "Нет")${NC}"
    else
        echo -e "    Режим:           ${BOLD}Чистая установка (без кастомизации)${NC}"
    fi
    if [ -n "$EXTRA_RAILS_FLAGS" ]; then
        echo -e "    Флаги rails new: ${DIM}$EXTRA_RAILS_FLAGS${NC}"
    fi
}

# ============================================================
# Запуск create-rails-app.sh
# ============================================================

run_create_rails_app() {
    echo ""
    print_divider
    echo ""

    # Формируем аргументы
    CMD_ARGS=("$SCRIPT_DIR/create-rails-app.sh" "$APP_NAME" "$RUBY_VERSION")

    if [ "$INSTALL_DIR" != "$APPS_INSTALL_DIR" ]; then
        CMD_ARGS+=("$INSTALL_DIR")
    fi

    if [ "$VANILLA_MODE" = "y" ]; then
        CMD_ARGS+=("--vanilla")
    fi

    if [ "$USE_BOILERPLATE" = "y" ]; then
        CMD_ARGS+=("--boilerplate")
    fi

    if [ -n "$EXTRA_RAILS_FLAGS" ]; then
        CMD_ARGS+=("--rails-flags=$EXTRA_RAILS_FLAGS")
    fi

    # Экспортируем порты (config.sh прочитает их через ${VAR:-default})
    export DEFAULT_WEB_PORT="$WEB_PORT"
    export DEFAULT_POSTGRES_PORT="$PG_PORT"
    export DEFAULT_ADMINER_PORT="$ADMINER_PORT"

    echo -e "  ${GREEN}${BOLD}Запуск создания приложения...${NC}"
    echo -e "  ${DIM}${CMD_ARGS[*]}${NC}"
    echo ""

    exec "${CMD_ARGS[@]}"
}
