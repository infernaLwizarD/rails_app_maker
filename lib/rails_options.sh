#!/bin/bash
# Интерактивный выбор опций rails new и сборка флагов
# Требует: source lib/common.sh

prompt_rails_options() {
    local step_offset=$1
    local step_num

    # --- База данных ---
    step_num=$((step_offset))
    print_step $step_num "База данных"
    print_hint "СУБД для приложения. PostgreSQL рекомендуется для production."
    prompt_choice "База данных" "3" \
        "sqlite3|Лёгкая файловая БД, не требует сервера. Подходит для прототипов" \
        "mysql|Популярная реляционная БД. Требует отдельный сервер" \
        "postgresql|Мощная реляционная БД с расширенными типами данных. Рекомендуется" \
        "trilogy|Современный MySQL-клиент от GitHub. Быстрее стандартного mysql2" \
        "mariadb-mysql|MariaDB через mysql2 адаптер" \
        "mariadb-trilogy|MariaDB через trilogy адаптер"
    CHOSEN_DB="$REPLY_VALUE"
    print_ok "БД: ${BOLD}$CHOSEN_DB${NC}"
    echo ""
    print_divider
    echo ""

    # --- JavaScript ---
    step_num=$((step_offset + 1))
    print_step $step_num "JavaScript"
    print_hint "Способ подключения JavaScript в приложении."
    prompt_choice "JavaScript" "1" \
        "importmap|Без сборщика, нативные ES-модули через Import Maps. Стандарт Rails 8" \
        "bun|Быстрый JS-рантайм и пакетный менеджер. Альтернатива Node.js" \
        "esbuild|Сверхбыстрый сборщик от создателей Figma" \
        "webpack|Классический сборщик с богатой экосистемой плагинов" \
        "rollup|Сборщик, оптимизированный для библиотек и tree-shaking" \
        "нет|Пропустить JavaScript полностью (--skip-javascript)"
    CHOSEN_JS="$REPLY_VALUE"
    print_ok "JS: ${BOLD}$CHOSEN_JS${NC}"
    echo ""
    print_divider
    echo ""

    # --- CSS ---
    step_num=$((step_offset + 2))
    print_step $step_num "CSS"
    print_hint "CSS-процессор или фреймворк. По умолчанию Rails использует обычный CSS."
    prompt_choice "CSS" "1" \
        "нет|Стандартный CSS без дополнительных инструментов" \
        "tailwind|Utility-first CSS фреймворк. Стили прямо в HTML-классах" \
        "bootstrap|Популярный UI-фреймворк с готовыми компонентами" \
        "bulma|Лёгкий CSS-фреймворк на Flexbox, без JavaScript" \
        "postcss|Инструмент для трансформации CSS с помощью плагинов" \
        "sass|Препроцессор CSS с переменными, миксинами и вложенностью"
    CHOSEN_CSS="$REPLY_VALUE"
    print_ok "CSS: ${BOLD}$CHOSEN_CSS${NC}"
    echo ""
    print_divider
    echo ""

    # --- Пропуск компонентов ---
    step_num=$((step_offset + 3))
    print_step $step_num "Компоненты Rails"
    print_hint "Выберите, какие компоненты включить. Enter — оставить по умолчанию (Да)."
    echo ""

    echo -e "  ${BOLD}Коммуникации:${NC}"
    prompt_yes_no "  Action Mailer — отправка email" "y"
    SKIP_MAILER="$REPLY_VALUE"
    prompt_yes_no "  Action Mailbox — приём входящих email" "y"
    SKIP_MAILBOX="$REPLY_VALUE"
    prompt_yes_no "  Action Cable — WebSocket в реальном времени" "y"
    SKIP_CABLE="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Хранение и контент:${NC}"
    prompt_yes_no "  Active Storage — загрузка файлов (в облако/на диск)" "y"
    SKIP_STORAGE="$REPLY_VALUE"
    prompt_yes_no "  Action Text — Rich-text редактор (Trix)" "y"
    SKIP_TEXT="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Фоновые задачи:${NC}"
    prompt_yes_no "  Active Job — фреймворк фоновых задач" "y"
    SKIP_JOB="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Фронтенд:${NC}"
    prompt_yes_no "  Hotwire — Turbo + Stimulus (SPA-подобный UX без JS-фреймворка)" "y"
    SKIP_HOTWIRE="$REPLY_VALUE"
    prompt_yes_no "  Asset Pipeline — конвейер ассетов (Propshaft)" "y"
    SKIP_ASSETS="$REPLY_VALUE"
    prompt_yes_no "  Jbuilder — DSL для генерации JSON-ответов" "y"
    SKIP_JBUILDER="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Тестирование:${NC}"
    prompt_yes_no "  Тесты (Minitest)" "y"
    SKIP_TEST="$REPLY_VALUE"
    prompt_yes_no "  Системные тесты (Capybara + Selenium)" "y"
    SKIP_SYSTEM_TEST="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Инфраструктура и CI:${NC}"
    prompt_yes_no "  Docker — Dockerfile и .dockerignore" "y"
    SKIP_DOCKER="$REPLY_VALUE"
    prompt_yes_no "  Kamal — деплой через Kamal (Docker-based)" "y"
    SKIP_KAMAL="$REPLY_VALUE"
    prompt_yes_no "  Solid — Solid Cache, Solid Queue, Solid Cable" "y"
    SKIP_SOLID="$REPLY_VALUE"
    prompt_yes_no "  Thruster — HTTP/2 прокси перед Puma" "y"
    SKIP_THRUSTER="$REPLY_VALUE"
    prompt_yes_no "  GitHub CI — файлы для GitHub Actions" "y"
    SKIP_CI="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Качество кода:${NC}"
    prompt_yes_no "  RuboCop — линтер и форматтер Ruby-кода" "y"
    SKIP_RUBOCOP="$REPLY_VALUE"
    prompt_yes_no "  Brakeman — сканер безопасности Rails-приложений" "y"
    SKIP_BRAKEMAN="$REPLY_VALUE"
    prompt_yes_no "  Bundler Audit — проверка уязвимостей в гемах" "y"
    SKIP_BUNDLER_AUDIT="$REPLY_VALUE"
    echo ""

    echo -e "  ${BOLD}Прочее:${NC}"
    prompt_yes_no "  Bootsnap — ускорение загрузки приложения через кэширование" "y"
    SKIP_BOOTSNAP="$REPLY_VALUE"
    prompt_yes_no "  Dev Gems — гемы для разработки (web-console и др.)" "y"
    SKIP_DEV_GEMS="$REPLY_VALUE"
    prompt_yes_no "  Git — инициализация git-репозитория" "y"
    SKIP_GIT="$REPLY_VALUE"
    echo ""

    # --- Режим API ---
    prompt_yes_no "  API-only режим (без views, без asset pipeline)" "n"
    USE_API="$REPLY_VALUE"

    prompt_yes_no "  Minimal режим (минимальный набор, без лишнего)" "n"
    USE_MINIMAL="$REPLY_VALUE"

    echo ""

    # Собираем пропущенные компоненты для отображения
    SKIPPED_LIST=""

    # --- Формируем флаги ---
    EXTRA_RAILS_FLAGS=""

    # База данных
    if [ "$CHOSEN_DB" != "postgresql" ]; then
        EXTRA_RAILS_FLAGS="--database=$CHOSEN_DB"
    fi

    # JavaScript
    if [ "$CHOSEN_JS" = "нет" ]; then
        EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-javascript"
        SKIPPED_LIST="${SKIPPED_LIST}JavaScript, "
    elif [ "$CHOSEN_JS" != "importmap" ]; then
        EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --javascript=$CHOSEN_JS"
    fi

    # CSS
    if [ "$CHOSEN_CSS" != "нет" ]; then
        EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --css=$CHOSEN_CSS"
    fi

    # Пропуск компонентов
    [ "$SKIP_MAILER" = "n" ]        && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-action-mailer"        && SKIPPED_LIST="${SKIPPED_LIST}Action Mailer, "
    [ "$SKIP_MAILBOX" = "n" ]       && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-action-mailbox"       && SKIPPED_LIST="${SKIPPED_LIST}Action Mailbox, "
    [ "$SKIP_CABLE" = "n" ]         && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-action-cable"         && SKIPPED_LIST="${SKIPPED_LIST}Action Cable, "
    [ "$SKIP_STORAGE" = "n" ]       && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-active-storage"       && SKIPPED_LIST="${SKIPPED_LIST}Active Storage, "
    [ "$SKIP_TEXT" = "n" ]          && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-action-text"          && SKIPPED_LIST="${SKIPPED_LIST}Action Text, "
    [ "$SKIP_JOB" = "n" ]          && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-active-job"           && SKIPPED_LIST="${SKIPPED_LIST}Active Job, "
    [ "$SKIP_HOTWIRE" = "n" ]      && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-hotwire"              && SKIPPED_LIST="${SKIPPED_LIST}Hotwire, "
    [ "$SKIP_ASSETS" = "n" ]       && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-asset-pipeline"       && SKIPPED_LIST="${SKIPPED_LIST}Asset Pipeline, "
    [ "$SKIP_JBUILDER" = "n" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-jbuilder"             && SKIPPED_LIST="${SKIPPED_LIST}Jbuilder, "
    [ "$SKIP_TEST" = "n" ]         && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-test"                 && SKIPPED_LIST="${SKIPPED_LIST}Тесты, "
    [ "$SKIP_SYSTEM_TEST" = "n" ]  && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-system-test"          && SKIPPED_LIST="${SKIPPED_LIST}Системные тесты, "
    [ "$SKIP_DOCKER" = "n" ]       && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-docker"               && SKIPPED_LIST="${SKIPPED_LIST}Docker, "
    [ "$SKIP_KAMAL" = "n" ]        && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-kamal"                && SKIPPED_LIST="${SKIPPED_LIST}Kamal, "
    [ "$SKIP_SOLID" = "n" ]        && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-solid"                && SKIPPED_LIST="${SKIPPED_LIST}Solid, "
    [ "$SKIP_THRUSTER" = "n" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-thruster"             && SKIPPED_LIST="${SKIPPED_LIST}Thruster, "
    [ "$SKIP_CI" = "n" ]           && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-ci"                   && SKIPPED_LIST="${SKIPPED_LIST}GitHub CI, "
    [ "$SKIP_RUBOCOP" = "n" ]      && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-rubocop"              && SKIPPED_LIST="${SKIPPED_LIST}RuboCop, "
    [ "$SKIP_BRAKEMAN" = "n" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-brakeman"             && SKIPPED_LIST="${SKIPPED_LIST}Brakeman, "
    [ "$SKIP_BUNDLER_AUDIT" = "n" ] && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-bundler-audit"       && SKIPPED_LIST="${SKIPPED_LIST}Bundler Audit, "
    [ "$SKIP_BOOTSNAP" = "n" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-bootsnap"             && SKIPPED_LIST="${SKIPPED_LIST}Bootsnap, "
    [ "$SKIP_DEV_GEMS" = "n" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-dev-gems"             && SKIPPED_LIST="${SKIPPED_LIST}Dev Gems, "
    [ "$SKIP_GIT" = "n" ]          && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --skip-git"                  && SKIPPED_LIST="${SKIPPED_LIST}Git, "

    # API / Minimal
    [ "$USE_API" = "y" ]     && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --api"
    [ "$USE_MINIMAL" = "y" ] && EXTRA_RAILS_FLAGS="$EXTRA_RAILS_FLAGS --minimal"

    # Убираем лишние пробелы в начале
    EXTRA_RAILS_FLAGS="$(echo "$EXTRA_RAILS_FLAGS" | sed 's/^ *//')"
    # Убираем trailing ", " из списка пропущенных
    SKIPPED_LIST="$(echo "$SKIPPED_LIST" | sed 's/, $//')"

    print_divider
    echo ""

    # Показываем сводку выбранных опций
    print_ok "БД: ${BOLD}$CHOSEN_DB${NC}"
    print_ok "JS: ${BOLD}$([ "$CHOSEN_JS" = "нет" ] && echo "пропущен" || echo "$CHOSEN_JS")${NC}"
    print_ok "CSS: ${BOLD}$([ "$CHOSEN_CSS" = "нет" ] && echo "стандартный" || echo "$CHOSEN_CSS")${NC}"
    [ "$USE_API" = "y" ] && print_ok "Режим: ${BOLD}API-only${NC}"
    [ "$USE_MINIMAL" = "y" ] && print_ok "Режим: ${BOLD}Minimal${NC}"
    if [ -n "$SKIPPED_LIST" ]; then
        print_ok "Пропущено: ${DIM}$SKIPPED_LIST${NC}"
    else
        print_ok "Пропущено: ${DIM}ничего${NC}"
    fi
}
