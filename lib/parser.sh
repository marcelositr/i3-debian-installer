#!/bin/bash

# ==============================================================================
# ===              BIBLIOTECA DE PARSING E PROCESSAMENTO DE GRUPOS             ===
# ==============================================================================

# --- FUNÇÕES DE CONFIGURAÇÃO E PARSING ---

check_and_configure_sources() {
    while true; do
        log_message "INFO" "Verificando /etc/apt/sources.list"
        local missing_components=()
        local active_sources
        active_sources=$(grep -E '^\s*deb\s' /etc/apt/sources.list)
        if echo "$active_sources" | grep -qv 'contrib'; then missing_components+=("contrib"); fi
        if echo "$active_sources" | grep -qv 'non-free'; then missing_components+=("non-free"); fi
        if echo "$active_sources" | grep -qv 'non-free-firmware'; then missing_components+=("non-free-firmware"); fi
        if [ ${#missing_components[@]} -eq 0 ]; then
            log_message "SUCCESS" "Fontes de pacotes já estão configuradas."
            echo -e "${GREEN}Fontes de pacotes OK.${NC}"
            break
        fi
        log_message "WARN" "Componentes faltantes: ${missing_components[*]}"
        echo -e "\n${YELLOW}Componentes de repositório faltantes em /etc/apt/sources.list:${NC} ${missing_components[*]}"
        read -p $'\nO que deseja fazer? [A]utomático, [M]anual, [C]ancelar: ' -r r
        case "$r" in
            [aA])
                log_message "INFO" "Usuário escolheu correção automática."
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                log_message "INFO" "Backup criado em /etc/apt/sources.list.bak"
                sudo sed -i -E 's/^(deb\s.*(main|updates)\s*)$/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list
                ;;
            [mM])
                log_message "INFO" "Usuário escolheu correção manual."
                sudo nano /etc/apt/sources.list
                ;;
            [cC])
                log_message "INFO" "Configuração de repositórios cancelada pelo usuário."
                return 1
                ;;
            *)
                log_message "WARN" "Opção inválida '${r}' na configuração de repositórios."
                ;;
        esac
    done
    run_with_spinner "Atualizando lista de pacotes..." sudo apt-get update
    return 0
}

process_group() {
    local mode="$1" _="$2" category_name="$3" packages_str="$4" post_install_script="$5" selection_mode="$6" removable="$7"
    local -a all_packages=()
    local -a packages_to_process=()
    read -r -a all_packages <<< "$packages_str"
    log_message "INFO" "Processando grupo '${category_name}' no modo '${mode}'."

    if [[ "$mode" == "remove" && "$removable" == "no" ]]; then
        log_message "WARN" "Tentativa de remoção do grupo protegido '${category_name}'. Ação pulada."
        dialog --title "Ação Bloqueada" --msgbox "O grupo '${category_name}' é essencial e está protegido contra remoção." 8 70
        return
    fi

    if [ "$mode" == "install" ]; then
        if [[ "$selection_mode" == "all" ]]; then
            packages_to_process=("${all_packages[@]}")
            ui_show_essential_group_info "$category_name" "${packages_to_process[@]}"
            local choice=$?; if [ $choice -ne 0 ]; then log_message "INFO" "Script cancelado."; exit 0; fi
        else
            ui_select_packages "$category_name" "${all_packages[@]}"
            packages_to_process=("${SELECTED_PACKAGES[@]}")
        fi
        if [ ${#packages_to_process[@]} -eq 0 ]; then log_message "INFO" "Nenhum pacote selecionado."; return; fi
        log_message "INFO" "Pacotes a serem processados: ${packages_to_process[*]}"
        ui_confirm_installation "${packages_to_process[@]}"
        local choice=$?; if [ $choice -ne 0 ]; then log_message "INFO" "Instalação pulada."; return; fi
        run_with_spinner "Instalando grupo '${category_name}'..." sudo apt-get install -y "${packages_to_process[@]}"
    fi
}

parse_config_and_process() {
    local mode=$1
    local current_key="" current_name="" current_packages="" current_post_script="" current_selection_mode="" current_removable=""
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/#.*//')
        value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/#.*//')
        if [[ $key =~ ^\[(.+)\]$ ]]; then
            if [[ -n "$current_key" ]]; then
                process_group "$mode" "$current_key" "$current_name" "$current_packages" "$current_post_script" "$current_selection_mode" "$current_removable"
            fi
            current_key="${BASH_REMATCH[1]}"
            current_name=""; current_packages=""; current_post_script=""; current_selection_mode=""; current_removable=""
        elif [[ -n "$key" && "$key" != "["* ]]; then
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//')
            case "$key" in
                name) current_name="$value" ;; packages) current_packages="$value" ;;
                post_install_script) current_post_script="$value" ;; selection_mode) current_selection_mode="$value" ;;
                removable) current_removable="$value" ;;
            esac
        fi
    done < "$CONFIG_FILE"
    if [[ -n "$current_key" ]]; then
        process_group "$mode" "$current_key" "$current_name" "$current_packages" "$current_post_script" "$current_selection_mode" "$current_removable"
    fi
}