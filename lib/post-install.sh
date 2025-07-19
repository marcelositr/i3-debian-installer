#!/bin/bash

# ==============================================================================
# ===         BIBLIOTECA DE LÓGICA PARA A PÓS-INSTALAÇÃO DO AMBIENTE           ===
# ==============================================================================
#
# Contém todas as funções interativas que configuram o ambiente do usuário
# após a instalação dos pacotes.
#
# ==============================================================================

# --- FUNÇÕES DE CONFIGURAÇÃO ---

ui_run_fish_setup() {
    if ! command -v fish &> /dev/null; then
        log_message "INFO" "Comando 'fish' não encontrado, pulando configuração de shell."
        return
    fi

    log_message "INFO" "Iniciando configuração do shell Fish."
    if dialog --title "Configuração de Shell" --yesno "Deseja definir 'fish' como seu shell padrão?\\n\\n(Você precisará fazer logout e login para que a alteração tenha efeito)" 8 70; then
        if sudo chsh -s "$(which fish)" "$(whoami)"; then
            log_message "SUCCESS" "Shell do usuário '$(whoami)' alterado para fish."
            dialog --title "Sucesso" --msgbox "'fish' foi definido como seu shell padrão." 6 50
        else
            log_message "ERROR" "O comando 'sudo chsh' falhou."
            dialog --title "Erro" --msgbox "Falha ao tentar alterar o shell." 6 50
        fi
    else
        log_message "INFO" "Alteração de shell para fish pulada pelo usuário."
    fi
}

ui_run_git_setup() {
    log_message "INFO" "Iniciando configuração de autoria do Git."
    if dialog --title "Configuração do Git" --yesno "Deseja configurar a AUTORIA (nome/email) para seus commits?" 7 60; then
        local git_name; git_name=$(dialog --title "Nome do Autor" --inputbox "Qual seu nome completo?" 8 50 2>&1 >/dev/tty)
        local git_email; git_email=$(dialog --title "Email do Autor" --inputbox "Qual seu email?" 8 50 2>&1 >/dev/tty)
        if [[ -n "$git_name" && -n "$git_email" ]]; then
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            log_message "SUCCESS" "Autoria do Git configurada (user.name e user.email)."
        else
            log_message "WARN" "Nome ou email do Git não fornecido. Pulando."
        fi
    else
        log_message "INFO" "Configuração de autoria do Git pulada pelo usuário."
    fi
}

ui_run_ssh_setup() {
    log_message "INFO" "Iniciando verificação de chaves SSH em ~/.ssh/"
    
    # Encontra todas as chaves públicas e as prepara para o dialog
    local -a ssh_keys=()
    local key_path
    while IFS= read -r key_path; do
        if [[ -f "$key_path" ]]; then
            ssh_keys+=("$(basename "$key_path")" "")
        fi
    done < <(find ~/.ssh -maxdepth 1 -type f -name 'id_*.pub')

    local ssh_pub_key_path=""

    if [ ${#ssh_keys[@]} -eq 0 ]; then
        log_message "WARN" "Nenhuma chave SSH pública encontrada em ~/.ssh/"
        dialog --title "Autenticação SSH" --msgbox "Nenhuma chave SSH encontrada em ~/.ssh/\\n\\nA configuração de autenticação para o GitHub será pulada.\\n\\nPara gerar uma nova chave, use:\\nssh-keygen -t ed25519 -C \\\"seu_email@exemplo.com\\\"" 12 70
        return
    elif [ ${#ssh_keys[@]} -eq 2 ]; then # Se encontrou apenas uma chave (um par de tag/item)
        ssh_pub_key_path="$HOME/.ssh/${ssh_keys[0]}"
    else # Se encontrou múltiplas chaves
        local temp_file; temp_file=$(mktemp)
        dialog --title "Seleção de Chave SSH" --radiolist "Múltiplas chaves SSH foram encontradas. Selecione qual você usa para o GitHub:" 15 70 ${#ssh_keys[@]} "${ssh_keys[@]}" 2> "$temp_file"
        local key_basename; key_basename=$(<"$temp_file"); rm "$temp_file"
        if [[ -n "$key_basename" ]]; then
            ssh_pub_key_path="$HOME/.ssh/$key_basename"
        fi
    fi

    if [[ -n "$ssh_pub_key_path" ]]; then
        log_message "SUCCESS" "Chave SSH selecionada pelo usuário: ${ssh_pub_key_path}"
        if dialog --title "Autenticação SSH" --yesno "Chave selecionada: ${ssh_pub_key_path}.\\n\\nDeseja configurar o Agente SSH para uso automático?" 8 70; then
            local BASHRC_FILE="$HOME/.bashrc"; local SSH_AGENT_LINE='eval "$(ssh-agent -s)"'
            if ! grep -q "ssh-agent" "$BASHRC_FILE"; then
                echo -e '\n# Inicia o ssh-agent para gerenciamento de chaves SSH' >> "$BASHRC_FILE"
                echo "$SSH_AGENT_LINE &> /dev/null" >> "$BASHRC_FILE"
                dialog --title "Sucesso" --msgbox "Configuração do Agente SSH adicionada ao seu .bashrc.\\nSerá ativado no próximo terminal." 7 60
            fi
            local key_content; key_content=$(cat "$ssh_pub_key_path")
            dialog --title "Passos Finais (Ação Manual)" --msgbox "Sua chave pública é:\\n\\n${key_content}\\n\\n1. Adicione esta chave à sua conta do GitHub.\\n2. Em um novo terminal, adicione a chave ao agente com:\\nssh-add ${ssh_pub_key_path/'.pub'/''}" 20 80
        fi
    fi
}

ui_configure_screenlock() {
    if ! command -v swayidle &> /dev/null; then
        log_message "INFO" "Comando 'swayidle' não encontrado, pulando configuração de bloqueio de tela."
        return
    fi
    
    log_message "INFO" "Iniciando configuração do bloqueio de tela."
    if dialog --title "Bloqueio de Tela Automático" --yesno "Deseja configurar o bloqueio de tela automático (após 10 min de inatividade) usando swayidle e i3lock?" 8 70; then
        local I3_CONFIG_DIR="$HOME/.config/i3"; local I3_CONFIG_FILE="$I3_CONFIG_DIR/config"
        mkdir -p "$I3_CONFIG_DIR"; touch "$I3_CONFIG_FILE"
        local SWAYIDLE_EXEC_LINE="exec_always --no-startup-id swayidle -w timeout 600 'i3lock -c 000000' timeout 630 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"'"
        if ! grep -q "swayidle" "$I3_CONFIG_FILE"; then
            log_message "INFO" "Adicionando configuração do swayidle ao ${I3_CONFIG_FILE}"
            echo -e "\n# Bloqueio de tela automático com swayidle" >> "$I3_CONFIG_FILE"
            echo -e "$SWAYIDLE_EXEC_LINE" >> "$I3_CONFIG_FILE"
            dialog --title "Sucesso" --msgbox "Bloqueio de tela automático configurado.\\nSerá aplicado no próximo login do i3." 7 60
        else
            log_message "WARN" "Configuração do swayidle já existe."
            dialog --title "Aviso" --msgbox "Uma configuração para 'swayidle' já parece existir em seu arquivo de configuração do i3." 7 60
        fi
    fi
}```

---

### **3. Arquivo Modificado: `pacotes.conf` (Completo)**

```ini
# =============================================================
# === ARQUIVO DE CONFIGURAÇÃO PARA O GERENCIADOR DE AMBIENTE ===
# =============================================================
#
# Estrutura:
# [NOME_DO_GRUPO]
# name="Nome Exibido"
# packages="pacote1 pacote2"
# selection_mode="all" (Opcional. Instala tudo. Padrão é múltiplo.)
# removable="no" (Opcional. Impede a remoção do grupo.)
#
# =============================================================

[BASE]
name="Sistema Base e Utilitários Essenciais"
packages="xorg xinit build-essential git vim nano dialog bash-completion"
selection_mode="all"
removable="no"

[I3_FULL]
name="i3wm Completo e Ferramentas Gráficas"
packages="i3 i3status i3lock dunst suckless-tools rxvt-unicode rofi xsel lightdm lightdm-gtk-greeter picom hsetroot lxappearance fonts-noto fonts-font-awesome"
selection_mode="all"
removable="no"

[SERVICES]
name="Serviços Essenciais (Rede, Áudio, BT, Impressão)"
packages="network-manager-gnome pipewire pipewire-pulse wireplumber pavucontrol alsa-utils bluez blueman cups printer-driver-gutenprint"
removable="no"

[APPS]
name="Aplicações de Uso Geral"
packages="thunar tumbler thunar-archive-plugin file-roller mousepad ristretto xfce4-taskmanager xfce4-power-manager xfce4-screenshooter xfce4-terminal gvfs-backends zip unzip tar gzip bzip2 xz-utils p7zip-full zstd unrar lrzip lzip cabextract"

[DEV_EDITORS]
name="Desenvolvimento: Editores e IDEs"
packages="geany geany-plugins"

[DEV_CPP]
name="Desenvolvimento: Ferramentas C/C++"
packages="gdb cmake meson clang clang-format clang-tidy"
removable="no"

[DEV_PYTHON]
name="Desenvolvimento: Ferramentas Python"
packages="python3-dev python3-pip python3-venv python3-flake8 black python3-numpy"
removable="no"

[MULTIMEDIA]
name="Pacotes de Multimídia"
packages="vlc vlc-plugin-qt gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libavcodec-extra ffmpeg yt-dlp mediainfo sox"

[TERMINAL_ADVANCED]
name="Terminal Avançado e Utilitários de CLI"
packages="fish tmux ranger lf tree ripgrep fzf jq htop btop starship xdotool shellcheck taskwarrior glow lazygit ueberzug w3m-img"

[HARDWARE]
name="Utilitários de Hardware e Bloqueio de Tela"
packages="swayidle"