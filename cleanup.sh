#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info() {
    echo -e "  ${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "  ${RED}✗${NC} $1"
}

prompt_yes_no() {
    local label="$1"
    local default="$2"
    local hint input

    if [ "$default" = "y" ]; then hint="Д/н"; else hint="д/Н"; fi

    while true; do
        echo -ne "  ${BOLD}$label${NC} ${DIM}[$hint]${NC}: "
        read -r input
        input="${input:-$default}"
        case "$input" in
            y|Y|yes|YES|Yes|д|Д|да|Да|ДА) return 0 ;;
            n|N|no|NO|No|н|Н|нет|Нет|НЕТ) return 1 ;;
            *) log_error "Введите: да/нет, д/н, y/n" ;;
        esac
    done
}

# ============================================================
# Обнаружение проектов по Docker Compose labels
# ============================================================

discover_projects() {
    local projects=""

    # Контейнеры с label com.docker.compose.project
    local from_containers
    from_containers=$(docker ps -a --format '{{.Label "com.docker.compose.project"}}' 2>/dev/null | sort -u | grep -v '^$' || true)
    if [ -n "$from_containers" ]; then
        projects="$from_containers"
    fi

    # Сети с label com.docker.compose.network
    local from_networks
    from_networks=$(docker network ls --format '{{.Name}}' 2>/dev/null | while read -r net; do
        label=$(docker network inspect "$net" --format '{{index .Labels "com.docker.compose.project"}}' 2>/dev/null || true)
        [ -n "$label" ] && echo "$label"
    done | sort -u || true)
    if [ -n "$from_networks" ]; then
        projects=$(printf '%s\n%s' "$projects" "$from_networks")
    fi

    # Volumes с label com.docker.compose.project
    local from_volumes
    from_volumes=$(docker volume ls --format '{{.Name}}' 2>/dev/null | while read -r vol; do
        label=$(docker volume inspect "$vol" --format '{{index .Labels "com.docker.compose.project"}}' 2>/dev/null || true)
        [ -n "$label" ] && echo "$label"
    done | sort -u || true)
    if [ -n "$from_volumes" ]; then
        projects=$(printf '%s\n%s' "$projects" "$from_volumes")
    fi

    # Образы, собранные docker compose build (имеют label com.docker.compose.project)
    local from_images
    from_images=$(docker images --format '{{index .Labels "com.docker.compose.project"}}' 2>/dev/null | sort -u | grep -v '^$' || true)
    if [ -n "$from_images" ]; then
        projects=$(printf '%s\n%s' "$projects" "$from_images")
    fi

    # Уникальный отсортированный список
    echo "$projects" | sort -u | grep -v '^$' || true
}

# ============================================================
# Сканирование ресурсов конкретного проекта (по label)
# ============================================================

scan_project() {
    local project="$1"

    CONTAINERS=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.Names}}  {{.Status}}" 2>/dev/null || true)
    CONTAINER_IDS=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.ID}}" 2>/dev/null || true)

    NETWORKS=$(docker network ls --format '{{.Name}}' 2>/dev/null | while read -r net; do
        label=$(docker network inspect "$net" --format '{{index .Labels "com.docker.compose.project"}}' 2>/dev/null || true)
        [ "$label" = "$project" ] && echo "$net"
    done || true)

    # Собственные образы (собранные docker compose build)
    # Ищем по label + fallback по имени project-*
    local own_by_label own_by_name
    own_by_label=$(docker images --format '{{index .Labels "com.docker.compose.project"}}|{{.Repository}}:{{.Tag}}' 2>/dev/null | grep "^${project}|" | cut -d'|' -f2 | sort -u || true)
    own_by_name=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep "^${project}[-_]" | sort -u || true)
    OWN_IMAGES_IDS=$(printf '%s\n%s' "$own_by_label" "$own_by_name" | sed '/^$/d' | sort -u || true)
    OWN_IMAGES_DISPLAY=""
    if [ -n "$OWN_IMAGES_IDS" ]; then
        OWN_IMAGES_DISPLAY=$(echo "$OWN_IMAGES_IDS" | while read -r img; do
            size=$(docker images --format "{{.Repository}}:{{.Tag}}  ({{.Size}})" "$img" 2>/dev/null | head -1 || echo "$img")
            echo "$size"
        done || true)
    fi

    # Общие образы (postgres, adminer, selenium и т.д.) — используются контейнерами проекта
    local container_images
    container_images=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.Image}}" 2>/dev/null | sort -u || true)
    SHARED_IMAGES_IDS=""
    SHARED_IMAGES_DISPLAY=""
    if [ -n "$container_images" ]; then
        # Отфильтровываем собственные образы — остаются только общие
        local shared
        shared=$(echo "$container_images" | while read -r img; do
            [ -z "$img" ] && continue
            # Пропускаем образы с именем проекта
            case "$img" in ${project}[-_]*) continue ;; esac
            # Проверяем, используется ли этот образ контейнерами ДРУГИХ проектов
            local other_users
            other_users=$(docker ps -a --filter "ancestor=$img" --format '{{.Label "com.docker.compose.project"}}' 2>/dev/null | grep -v "^${project}$" | grep -v '^$' | sort -u || true)
            if [ -n "$other_users" ]; then
                local projects_list
                projects_list=$(echo "$other_users" | paste -sd ', ' -)
                echo "SHARED:$img:$projects_list"
            else
                echo "SAFE:$img:"
            fi
        done || true)
        SHARED_IMAGES_IDS=$(echo "$shared" | sed '/^$/d' | cut -d: -f2 || true)
        SHARED_IMAGES_DISPLAY=$(echo "$shared" | sed '/^$/d' | while IFS=: read -r status img projects_list; do
            [ -z "$img" ] && continue
            size=$(docker images --format "({{.Size}})" "$img" 2>/dev/null | head -1 || true)
            if [ "$status" = "SHARED" ]; then
                echo "$img  $size  ← также: $projects_list"
            else
                echo "$img  $size"
            fi
        done || true)
        SHARED_IMAGES_SAFE=$(echo "$shared" | grep '^SAFE:' | cut -d: -f2 | sed '/^$/d' || true)
        SHARED_IMAGES_USED=$(echo "$shared" | grep '^SHARED:' | cut -d: -f2 | sed '/^$/d' || true)
    fi

    # Объединённые для подсчёта
    IMAGES_IDS=$(printf '%s\n%s' "$OWN_IMAGES_IDS" "$SHARED_IMAGES_IDS" | sed '/^$/d' | sort -u || true)
    IMAGES_DISPLAY=$(printf '%s\n%s' "$OWN_IMAGES_DISPLAY" "$SHARED_IMAGES_DISPLAY" | sed '/^$/d' || true)

    VOLUMES=$(docker volume ls --format '{{.Name}}' 2>/dev/null | while read -r vol; do
        label=$(docker volume inspect "$vol" --format '{{index .Labels "com.docker.compose.project"}}' 2>/dev/null || true)
        [ "$label" = "$project" ] && echo "$vol"
    done || true)

    # Подсчёт (фильтруем пустые строки, считаем wc -l)
    CNT_CONTAINERS=$(echo "$CONTAINER_IDS" | sed '/^$/d' | wc -l | tr -d ' ')
    CNT_NETWORKS=$(echo "$NETWORKS" | sed '/^$/d' | wc -l | tr -d ' ')
    CNT_OWN_IMAGES=$(echo "$OWN_IMAGES_IDS" | sed '/^$/d' | wc -l | tr -d ' ')
    CNT_SHARED_IMAGES=$(echo "$SHARED_IMAGES_IDS" | sed '/^$/d' | wc -l | tr -d ' ')
    CNT_IMAGES=$(( ${CNT_OWN_IMAGES:-0} + ${CNT_SHARED_IMAGES:-0} ))
    CNT_VOLUMES=$(echo "$VOLUMES" | sed '/^$/d' | wc -l | tr -d ' ')
}

# ============================================================
# Отображение ресурсов
# ============================================================

show_resource() {
    local label="$1"
    local count="$2"
    local items="$3"
    local color="${4:-$NC}"

    if [ "${count:-0}" -gt 0 ] && [ -n "$items" ]; then
        echo -e "  ${color}${BOLD}$label ($count):${NC}"
        echo "$items" | while read -r item; do
            [ -n "$item" ] && echo -e "    ${DIM}•${NC} $item"
        done
    else
        echo -e "  ${DIM}$label: не найдены${NC}"
    fi
}

show_all_resources() {
    show_resource "Контейнеры" "$CNT_CONTAINERS" "$CONTAINERS"
    show_resource "Сети" "$CNT_NETWORKS" "$NETWORKS"
    show_resource "Образы проекта" "$CNT_OWN_IMAGES" "$OWN_IMAGES_DISPLAY" "$CYAN"
    show_resource "Общие образы" "$CNT_SHARED_IMAGES" "$SHARED_IMAGES_DISPLAY" "$YELLOW"
    show_resource "Volumes" "$CNT_VOLUMES" "$VOLUMES" "$RED"
}

# ============================================================
# Парсинг аргументов
# ============================================================

APP_NAME=""
CLEAN_ALL=false
SKIP_CONFIRM=false

while [ $# -gt 0 ]; do
    case $1 in
        --all) CLEAN_ALL=true ;;
        --yes) SKIP_CONFIRM=true ;;
        --help|-h)
            echo ""
            echo -e "${BOLD}Использование:${NC} $0 [app_name] [опции]"
            echo ""
            echo "Очищает Docker-ресурсы, созданные для Rails приложения."
            echo "Без аргументов — интерактивный режим с выбором приложения из списка."
            echo ""
            echo -e "${BOLD}Опции:${NC}"
            echo "  --all       Полная очистка без выбора компонентов"
            echo "  --yes       Пропустить подтверждение (для автоматизации)"
            echo "  --help      Показать эту справку"
            echo ""
            echo -e "${BOLD}Примеры:${NC}"
            echo "  $0                     # Интерактивный режим"
            echo "  $0 my_app              # Интерактивный выбор компонентов"
            echo "  $0 my_app --all        # Полная очистка (с подтверждением)"
            echo "  $0 my_app --all --yes  # Полная очистка без вопросов"
            echo ""
            exit 0
            ;;
        *)
            if [ -z "$APP_NAME" ]; then
                APP_NAME="$1"
            else
                log_error "Неизвестная опция: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

# ============================================================
# Заголовок
# ============================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Очистка Docker-ресурсов Rails          ${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# Выбор приложения (если не указано)
# ============================================================

if [ -z "$APP_NAME" ]; then
    echo -e "  ${BOLD}Поиск приложений в Docker...${NC}"
    echo ""

    PROJECTS=$(discover_projects)

    if [ -z "$PROJECTS" ]; then
        log_warn "Docker Compose проекты не найдены."
        echo ""
        exit 0
    fi

    # Формируем массив
    mapfile -t PROJECT_LIST <<< "$PROJECTS"
    COUNT=${#PROJECT_LIST[@]}

    echo -e "  ${BOLD}Найденные проекты:${NC}"
    echo ""
    for i in "${!PROJECT_LIST[@]}"; do
        num=$((i + 1))
        proj="${PROJECT_LIST[$i]}"
        # Быстрый подсчёт ресурсов для превью
        cnt=$(docker ps -a --filter "label=com.docker.compose.project=$proj" -q 2>/dev/null | wc -l || echo 0)
        echo -e "  ${BOLD}${num})${NC} ${CYAN}$proj${NC} ${DIM}(контейнеров: $cnt)${NC}"
    done
    echo ""

    # Выбор
    while true; do
        echo -ne "  ${BOLD}Выберите проект${NC} ${DIM}[1-$COUNT]${NC}: "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$COUNT" ]; then
            APP_NAME="${PROJECT_LIST[$((choice - 1))]}"
            break
        fi
        log_error "Введите число от 1 до $COUNT"
    done
    echo ""
fi

# Project name = имя как его видит Docker Compose
PROJECT=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')

# ============================================================
# Сканирование ресурсов
# ============================================================

echo -e "  ${BOLD}Сканирование ресурсов для: ${YELLOW}$PROJECT${NC}"
echo ""

scan_project "$PROJECT"

TOTAL=$(( ${CNT_CONTAINERS:-0} + ${CNT_NETWORKS:-0} + ${CNT_IMAGES:-0} + ${CNT_VOLUMES:-0} ))
if [ "$TOTAL" -eq 0 ]; then
    log_warn "Docker-ресурсы для '$PROJECT' не найдены."
    echo ""
    exit 0
fi

show_all_resources
echo ""

# ============================================================
# Неинтерактивный режим (--all)
# ============================================================

if [ "$CLEAN_ALL" = true ]; then
    echo -e "  ${BOLD}Режим: полная очистка${NC}"
    echo ""

    if [ "$SKIP_CONFIRM" = false ]; then
        if ! prompt_yes_no "Удалить ВСЕ ресурсы проекта '$PROJECT' (включая данные БД)?" "n"; then
            echo ""
            log_warn "Отменено."
            echo ""
            exit 0
        fi
        echo ""
    fi

    DO_CONTAINERS="y"
    DO_NETWORKS="y"
    DO_OWN_IMAGES="y"
    DO_SHARED_IMAGES="y"
    DO_VOLUMES="y"

else
    # ============================================================
    # Интерактивный режим
    # ============================================================

    echo -e "  ${BOLD}Выберите что очистить:${NC}"
    echo ""

    DO_CONTAINERS="n"
    DO_NETWORKS="n"
    DO_OWN_IMAGES="n"
    DO_SHARED_IMAGES="n"
    DO_VOLUMES="n"

    # 1. Контейнеры + сети
    if [ "${CNT_CONTAINERS:-0}" -gt 0 ] || [ "${CNT_NETWORKS:-0}" -gt 0 ]; then
        if prompt_yes_no "Удалить контейнеры и сети?" "y"; then
            DO_CONTAINERS="y"
            DO_NETWORKS="y"
        fi
    fi

    # 2. Собственные образы проекта
    if [ "${CNT_OWN_IMAGES:-0}" -gt 0 ]; then
        if prompt_yes_no "Удалить образы проекта (${PROJECT}-*)?" "y"; then
            DO_OWN_IMAGES="y"
        fi
    fi

    # 3. Общие образы
    if [ "${CNT_SHARED_IMAGES:-0}" -gt 0 ]; then
        cnt_used=$(echo "$SHARED_IMAGES_USED" | sed '/^$/d' | wc -l | tr -d ' ')
        if [ "${cnt_used:-0}" -gt 0 ]; then
            echo -e "  ${YELLOW}${BOLD}Некоторые общие образы используются другими проектами!${NC}"
        fi
        if prompt_yes_no "Удалить общие образы (postgres, adminer и т.д.)?" "n"; then
            DO_SHARED_IMAGES="y"
            # Если есть образы, используемые другими — предупреждаем
            if [ "${cnt_used:-0}" -gt 0 ]; then
                echo -e "  ${RED}${BOLD}Образы, используемые другими проектами, будут пропущены.${NC}"
            fi
        fi
    fi

    # 4. Volumes
    if [ "${CNT_VOLUMES:-0}" -gt 0 ]; then
        echo -e "  ${RED}${BOLD}ВНИМАНИЕ: volumes содержат данные БД!${NC}"
        if prompt_yes_no "Удалить volumes (данные БД будут потеряны)?" "n"; then
            DO_VOLUMES="y"
        fi
    fi

    echo ""

    # Проверяем, выбрано ли хоть что-то
    if [ "$DO_CONTAINERS" = "n" ] && [ "$DO_NETWORKS" = "n" ] && \
       [ "$DO_OWN_IMAGES" = "n" ] && [ "$DO_SHARED_IMAGES" = "n" ] && [ "$DO_VOLUMES" = "n" ]; then
        log_warn "Ничего не выбрано. Отменено."
        echo ""
        exit 0
    fi

    # Итоговое подтверждение
    echo -e "  ${BOLD}Будет выполнено для проекта ${YELLOW}$PROJECT${NC}${BOLD}:${NC}"
    [ "$DO_CONTAINERS" = "y" ]    && echo -e "    ${GREEN}•${NC} Удаление контейнеров"
    [ "$DO_NETWORKS" = "y" ]      && echo -e "    ${GREEN}•${NC} Удаление сетей"
    [ "$DO_OWN_IMAGES" = "y" ]    && echo -e "    ${GREEN}•${NC} Удаление образов проекта"
    [ "$DO_SHARED_IMAGES" = "y" ] && echo -e "    ${YELLOW}•${NC} Удаление общих образов (безопасных)"
    [ "$DO_VOLUMES" = "y" ]       && echo -e "    ${RED}•${NC} Удаление volumes (данные БД!)"
    echo ""

    if ! prompt_yes_no "Подтвердить очистку?" "y"; then
        echo ""
        log_warn "Отменено."
        echo ""
        exit 0
    fi
fi

echo ""
echo -e "  ${BOLD}Выполнение очистки...${NC}"
echo ""

# ============================================================
# Выполнение очистки
# ============================================================

# Контейнеры (по ID — точное совпадение по label)
if [ "$DO_CONTAINERS" = "y" ] && [ -n "$CONTAINER_IDS" ]; then
    log_info "Остановка и удаление контейнеров..."
    echo "$CONTAINER_IDS" | xargs -r docker rm -f 2>/dev/null || true
fi

# Сети (только принадлежащие проекту)
if [ "$DO_NETWORKS" = "y" ] && [ -n "$NETWORKS" ]; then
    log_info "Удаление сетей..."
    echo "$NETWORKS" | xargs -r docker network rm 2>/dev/null || true
fi

# Собственные образы проекта
if [ "$DO_OWN_IMAGES" = "y" ] && [ -n "$OWN_IMAGES_IDS" ]; then
    log_info "Удаление образов проекта..."
    echo "$OWN_IMAGES_IDS" | xargs -r docker rmi -f 2>/dev/null || true
fi

# Общие образы (только те, что не используются другими проектами)
if [ "$DO_SHARED_IMAGES" = "y" ] && [ -n "$SHARED_IMAGES_SAFE" ]; then
    log_info "Удаление общих образов..."
    echo "$SHARED_IMAGES_SAFE" | xargs -r docker rmi -f 2>/dev/null || true
fi
if [ "$DO_SHARED_IMAGES" = "y" ] && [ -n "$SHARED_IMAGES_USED" ]; then
    log_warn "Пропущены общие образы (используются другими проектами):"
    echo "$SHARED_IMAGES_USED" | while read -r img; do
        [ -n "$img" ] && echo -e "    ${DIM}•${NC} $img"
    done
fi

# Volumes (только принадлежащие проекту по label)
if [ "$DO_VOLUMES" = "y" ] && [ -n "$VOLUMES" ]; then
    log_warn "Удаление volumes..."
    echo "$VOLUMES" | xargs -r docker volume rm -f 2>/dev/null || true
fi

# Висячие образы (только если удаляли образы)
if [ "$DO_OWN_IMAGES" = "y" ] || [ "$DO_SHARED_IMAGES" = "y" ]; then
    DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null || true)
    if [ -n "$DANGLING" ]; then
        log_info "Очистка висячих образов..."
        docker image prune -f >/dev/null 2>&1 || true
    fi
fi

# ============================================================
# Итог
# ============================================================

echo ""
log_info "✨ Очистка Docker-ресурсов для '$PROJECT' завершена!"

# Показываем что осталось
scan_project "$PROJECT"
REMAINING=$(( ${CNT_CONTAINERS:-0} + ${CNT_NETWORKS:-0} + ${CNT_IMAGES:-0} + ${CNT_VOLUMES:-0} ))

if [ "$REMAINING" -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}Остались:${NC}"
    show_all_resources
fi
echo ""
