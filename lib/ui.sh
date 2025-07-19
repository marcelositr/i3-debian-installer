#!/bin/bash

# --- FUNÇÕES DE INTERFACE DO USUÁRIO (UI) ---

# CORREÇÃO: Usa um loop 'for' para construir a string de exibição, garantindo quebras de linha.
ui_show_essential_group_info() {
    local category_name="$1"; shift
    local -a packages_to_process=("$@")
    local package_list_str=""
    for pkg in "${packages_to_process[@]}"; do
        package_list_str+="  - ${pkg}\n"
    done
    dialog --backtitle "Grupo Essencial" --title "$category_name" --msgbox "Este grupo é essencial e todos os pacotes abaixo serão instalados:\n\n${package_list_str}" 15 70
    return $?
}

ui_select_packages() {
    local category_name="$1"; shift
    local -a all_packages=("$@"); local -a dialog_args=()
    for pkg in "${all_packages[@]}"; do
        dialog_args+=("$pkg" "" "on")
    done
    local temp_file; temp_file=$(mktemp)
    dialog --backtitle "Seleção de Pacotes" --title "$category_name" --checklist "Use ESPAÇO para marcar/desmarcar." 20 70 15 "${dialog_args[@]}" 2> "$temp_file"
    # shellcheck disable=SC2162
    read -d '' -ra SELECTED_PACKAGES < "$temp_file"; rm "$temp_file"
}

# CORREÇÃO: Usa um loop 'for' para construir a string de exibição.
ui_confirm_installation() {
    local -a packages_to_process=("$@")
    local package_list_str=""
    for pkg in "${packages_to_process[@]}"; do
        package_list_str+="  - ${pkg}\n"
    done
    dialog --title "Confirmar Instalação" --yesno "Deseja instalar os seguintes pacotes?\n\n${package_list_str}" 15 70
    return $?
}

# CORREÇÃO: Usa um loop 'for' para construir a string de exibição.
ui_confirm_removal() {
    local category_name="$1"; shift
    local -a packages_to_process=("$@")
    local package_list_str=""
    for pkg in "${packages_to_process[@]}"; do
        package_list_str+="  - ${pkg}\n"
    done
    dialog --title "Confirmar Remoção" --yesno "CONFIRMA a REMOÇÃO COMPLETA do grupo '${category_name}' e dos pacotes abaixo?\n\n${package_list_str}" 15 70
    return $?
}

ui_manage_dotfiles() {
    if dialog --title "Dotfiles" --yesno "Deseja clonar um repositório de dotfiles do Git?" 7 60; then
        local repo_url; repo_url=$(dialog --title "URL do Repositório" --inputbox "Cole a URL HTTPS ou SSH:" 8 70 2>&1 >/dev/tty)
        if [[ -n "$repo_url" ]]; then
            run_with_spinner "git clone \"$repo_url\" \"$HOME/dotfiles\""
            dialog --title "Sucesso" --msgbox "Repositório clonado para '$HOME/dotfiles'.\n\nLembre-se de criar os links simbólicos." 8 60
        fi
    fi
}