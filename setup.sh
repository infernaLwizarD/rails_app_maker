#!/bin/bash
set -e

# Определяем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем конфигурацию для значений по умолчанию
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    APPS_INSTALL_DIR="$(dirname "$SCRIPT_DIR")"
    DEFAULT_RUBY_VERSION="3.3.6"
    RAILS_VERSION_CONSTRAINT="~> 8.0"
    DEFAULT_WEB_PORT=3001
    DEFAULT_POSTGRES_PORT=5432
    DEFAULT_ADMINER_PORT=8081
fi

# Загружаем модули
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/rails_options.sh"
source "$SCRIPT_DIR/lib/mode_basic.sh"
source "$SCRIPT_DIR/lib/mode_quick.sh"
source "$SCRIPT_DIR/lib/mode_advanced.sh"

# ============================================================
# Начало интерактивной установки
# ============================================================

print_header

echo -e "  Мастер создания нового Rails приложения."
echo -e "  Нажмите ${BOLD}Enter${NC} чтобы принять значение по умолчанию ${DIM}[в скобках]${NC}."
echo ""
print_divider
echo ""

# --- Выбор режима установки ---
echo -e "  ${BOLD}Выберите режим установки:${NC}"
echo ""
echo -e "  ${BOLD}1)${NC} Базовая установка (выбор опций rails new)"
echo -e "     ${DIM}Интерактивный выбор стандартных опций генератора Rails:${NC}"
echo -e "     ${DIM}база данных, CSS, JavaScript, пропуск компонентов и т.д.${NC}"
echo ""
echo -e "  ${BOLD}2)${NC} Быстрая установка"
echo -e "     ${DIM}Rails + PostgreSQL + Docker-окружение с настройками по умолчанию.${NC}"
echo -e "     ${DIM}Нужно указать только имя приложения.${NC}"
echo ""
echo -e "  ${BOLD}3)${NC} Быстрая + Boilerplate"
echo -e "     ${DIM}То же, что (2), плюс rails8_boilerplate —${NC}"
echo -e "     ${DIM}набор готовых конфигов, генераторов и best practices для Rails 8.${NC}"
echo ""
echo -e "  ${BOLD}4)${NC} Расширенная установка"
echo -e "     ${DIM}Полная настройка: версия Ruby, директория, порты, опции rails new, boilerplate.${NC}"
echo -e "     ${DIM}Максимальный контроль над всеми параметрами.${NC}"
echo ""

INSTALL_MODE=""
while true; do
    echo -ne "  ${BOLD}Режим${NC} ${DIM}[1]${NC}: "
    read -r INSTALL_MODE
    INSTALL_MODE="${INSTALL_MODE:-1}"
    case "$INSTALL_MODE" in
        1|2|3|4) break ;;
        *) print_err "Введите 1, 2, 3 или 4" ;;
    esac
done

echo ""
print_divider
echo ""

# Инициализация переменных
RUBY_VERSION="$DEFAULT_RUBY_VERSION"
INSTALL_DIR="$APPS_INSTALL_DIR"
WEB_PORT="$DEFAULT_WEB_PORT"
PG_PORT="$DEFAULT_POSTGRES_PORT"
ADMINER_PORT="$DEFAULT_ADMINER_PORT"
USE_BOILERPLATE="n"
VANILLA_MODE="n"
EXTRA_RAILS_FLAGS=""

# --- Запуск выбранного режима ---
case "$INSTALL_MODE" in
    1) run_mode_basic ;;
    2) run_mode_quick "n" ;;
    3) run_mode_quick "y" ;;
    4) run_mode_advanced ;;
esac

# --- Запуск или отмена ---
if [ "$CONFIRM" != "y" ]; then
    echo ""
    echo -e "  ${YELLOW}Установка отменена.${NC}"
    echo ""
    exit 0
fi

run_create_rails_app
