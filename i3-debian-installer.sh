#===============================================================================
#
#          FILE: i3-debian-installer.sh
#
#         USAGE: sudo ./i3-debian-installer.sh
#
#   DESCRIPTION: An interactive and modular script to install a complete i3
#                window manager environment on a minimal Debian 13 (Trixie) system.
#
#       OPTIONS: n/a
#  REQUIREMENTS: bash, dialog, root privileges, internet connection
#          BUGS: n/a
#         NOTES: The installation is modular, allowing the user to select which
#                component groups to install. Some manual steps are required
#                after the script finishes.
#        AUTHOR: ~marcelositr marcelost@riseup.net
#       CREATED: 2025/07/18
#       VERSION: 1.0.0
#      REVISION: Reverted to the previous stable script version. Shortened
#                long description texts to prevent dialog display issues.
#===============================================================================

# --- Initial Definitions ---
LOGFILE="/root/i3_install.log"
TERM_WIDTH=110
TERM_HEIGHT=35

# --- Configuration Variables ---

# -- Package Groups --
PACKAGES_BASE=(xorg xinit build-essential git vim nano dialog bash-completion)
PACKAGES_I3_FULL=(i3 i3status i3lock dunst suckless-tools rxvt-unicode rofi xsel sddm sddm-theme-debian-breeze picom hsetroot lxappearance fonts-noto fonts-font-awesome)
PACKAGES_SERVICES=(network-manager-gnome pipewire pipewire-pulse wireplumber pavucontrol alsa-utils)
PACKAGES_APPS=(thunar tumbler thunar-archive-plugin file-roller mousepad ristretto xfce4-taskmanager xfce4-power-manager xfce4-screenshooter xfce4-terminal gvfs-backends zip unzip tar gzip bzip2 xz-utils p7zip-full zstd unrar lrzip lzip squashfs-tools cabextract)
PACKAGES_DEVELOPMENT=(geany geany-plugins gdb cmake meson clang clang-format clang-tidy python3-dev python3-pip python3-venv python3-flake8 python3-black python3-numpy)
PACKAGES_MULTIMIDIA=(vlc vlc-plugin-qt gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libdvd-pkg libavcodec-extra ffmpeg yt-dlp mediainfo sox)
PACKAGES_TERMINAL_ADVANCED=(fish tmux eza ranger lf tree ripgrep fd-find fzf bat jq htop btop starship xdotool shellcheck taskwarrior glow lazygit lazydocker ueberzug w3m-img)
PACKAGES_HARDWARE=(bluez blueman cups system-config-printer xautolock)

# -- Dialog Descriptions --
DESC_BASE="Este grupo instala a base para o sistema gráfico e ferramentas de linha de comando essenciais. É o alicerce indispensável.

Pacotes principais:
- xorg: O servidor gráfico fundamental (X11).
- build-essential: Compiladores e ferramentas para instalar softwares.
- git: Para baixar as configurações (dotfiles).
- vim/nano: Editores de texto de terminal."

DESC_I3_FULL="Este grupo instala o coração do sistema: o i3, o gerenciador de login e todas as ferramentas visuais para que o dotfile funcione corretamente.

Pacotes:
- i3, i3status, i3lock: O gerenciador de janelas, barra e tela de bloqueio.
- rofi, dunst, rxvt-unicode: Lançador de apps, notificações e o terminal do dotfile.
- sddm: A tela de login gráfica.
- picom, hsetroot, lxappearance: Compositor visual, papel de parede e configurador de temas."

DESC_SERVICES="Instala os sistemas de áudio e rede, essenciais para um desktop moderno.

Pacotes:
- network-manager-gnome: Gerenciador de rede com applet para a bandeja do sistema.
- pipewire/wireplumber: O sistema de áudio moderno do Linux.
- pavucontrol/alsa-utils: Controle de áudio gráfico e via linha de comando."

DESC_APPS="Instala uma suíte de aplicativos gráficos leves do XFCE e adiciona suporte completo a arquivos compactados.

Pacotes:
- thunar, file-roller: Gerenciador de arquivos e de arquivos compactados.
- mousepad, ristretto: Editor de texto e visualizador de imagens.
- Suporte a .zip, .rar, .7z, .tar.gz e muitos outros."

DESC_DEVELOPMENT="Instala um ambiente de desenvolvimento completo para C/C++ e Python, com a IDE Geany.

Pacotes:
- geany, geany-plugins: Uma IDE leve e extensível.
- C/C++: clang, cmake, gdb e ferramentas de formatação.
- Python: pip, venv e bibliotecas essenciais."

# --- CORREÇÃO: Texto encurtado ---
DESC_MULTIMIDIA="Instala o player VLC, um pacote completo de codecs para máxima compatibilidade e ferramentas de linha de comando essenciais como ffmpeg (para conversão de vídeo) e yt-dlp (para downloads)."

# --- CORREÇÃO: Texto encurtado ---
DESC_TERMINAL_ADVANCED="Turbine seu terminal com as melhores ferramentas modernas. Inclui o shell fish, o gerenciador de sessões tmux, substitutos para comandos clássicos (eza, bat, ripgrep) e interfaces visuais para Git/Docker (lazygit, lazydocker)."

DESC_HARDWARE="Adiciona suporte para funcionalidades de hardware como Bluetooth, impressoras e bloqueio de tela por inatividade.

Pacotes:
- blueman: Interface gráfica para gerenciar dispositivos Bluetooth.
- cups: Sistema de impressão do Linux.
- xautolock: Permite travar a tela automaticamente."

DESC_DOTFILES="Esta etapa irá baixar (clonar) o repositório 'i3-starterpack' com todas as configurações prontas.

O repositório será salvo em /opt/i3-starterpack.

Após a instalação, você precisará copiar os arquivos para sua pasta de usuário com um comando que será exibido no final."

# --- Utility Functions ---

log_message() {
    local message="$1"
    echo "$(date '+%F %T') | $message" | tee -a "$LOGFILE"
}

show_message() {
    local title="$1"
    local message="$2"
    dialog --title "$title" --msgbox "$message" 20 70
}

ask_user_yes_no() {
    local title="$1"
    local message="$2"
    dialog --title "$title" --yesno "$message" $TERM_HEIGHT $TERM_WIDTH
    return $?
}

is_installed() {
    dpkg -s "$1" &> /dev/null
    return $?
}

install_packages() {
    local -n packages_ref="$1"
    local group_name="$2"

    log_message "Starting analysis for group: $group_name"
    dialog --title "Verificando Grupo: $group_name" --infobox "\nAnalisando pacotes já instalados..." 8 50
    
    local missing_packages=()
    for pkg in "${packages_ref[@]}"; do
        if ! is_installed "$pkg"; then
            missing_packages+=("$pkg")
        else
            log_message "[INFO] Pacote '$pkg' já instalado."
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_message "[OK] Todos os pacotes do grupo '$group_name' já estavam instalados."
        show_message "Grupo: $group_name" "Todos os pacotes já estão instalados. Nenhuma ação necessária."
        return 0
    fi

    log_message "Iniciando instalação de pacotes para o grupo: $group_name"
    
    local TEMP_LOG
    TEMP_LOG=$(mktemp)

    (apt-get update -y && apt-get install -y "${missing_packages[@]}") >"$TEMP_LOG" 2>&1 &
    local apt_pid=$!

    (
    echo 0
    while kill -0 "$apt_pid" 2>/dev/null; do
        echo "#"
        sleep 1
    done
    echo 100
    ) | dialog --title "Instalando $group_name" --gauge "Executando apt-get install..." 10 70 0

    wait "$apt_pid"
    local exit_code=$?
    
    cat "$TEMP_LOG" >> "$LOGFILE"

    if [ "$exit_code" -ne 0 ]; then
        log_message "[ERROR] Falha ao instalar pacotes do grupo '$group_name'. Código de Saída: $exit_code"
        local error_details
        error_details=$(tail -n 5 "$TEMP_LOG")
        show_message "Erro na Instalação" "Ocorreu um erro ao instalar o grupo '$group_name'.\n\nDetalhes do erro:\n$error_details\n\nVerifique o log completo em $LOGFILE."
        rm -f "$TEMP_LOG"
        return 1
    else
        log_message "[OK] Grupo '$group_name' instalado com sucesso."
        rm -f "$TEMP_LOG"
        return 0
    fi
}

enable_service() {
    local service_name="$1"
    if systemctl list-unit-files | grep -q "^$service_name"; then
        if ! systemctl is-enabled "$service_name" &> /dev/null; then
            local output
            output=$(systemctl enable "$service_name" 2>&1)
            local exit_code=$?

            if [ "$exit_code" -eq 0 ]; then
                log_message "[OK] Serviço '$service_name' habilitado com sucesso."
            else
                log_message "[ERROR] Falha ao habilitar o serviço '$service_name'."
                log_message " -> Código de Saída: $exit_code"
                log_message " -> Mensagem do Sistema: $output"
            fi
        else
            log_message "[INFO] Serviço '$service_name' já está habilitado."
        fi
    else
        log_message "[WARN] Serviço '$service_name' não encontrado. Pulando habilitação."
    fi
}

clone_dotfiles() {
    local dotfiles_dir="/opt/i3-starterpack"
    local dotfiles_repo="https://github.com/marcelositr/i3-starterpack.git"

    if [ -d "$dotfiles_dir" ]; then
        log_message "[INFO] Diretório de dotfiles $dotfiles_dir já existe. Pulando clonagem."
        return 0
    fi

    {
        git clone --depth 1 "$dotfiles_repo" "$dotfiles_dir"
    } 2>&1 | tee -a "$LOGFILE" | dialog --title "Downloading Configurations" --progressbox $TERM_HEIGHT $TERM_WIDTH

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log_message "[ERRO] Falha ao clonar o repositório de dotfiles."
        show_message "Error" "Failed to download the dotfiles repository."
    else
        log_message "[OK] Repositório de dotfiles clonado com sucesso em $dotfiles_dir."
    fi
}

run_group_install() {
    local group_name="$1"
    local description_text="$2"
    local -n packages_ref="$3"

    if ask_user_yes_no "Group: $group_name" "$description_text"; then
        install_packages packages_ref "$group_name"
    else
        log_message "[SKIPPED] Instalação do grupo '$group_name' foi pulada pelo usuário."
    fi
}

# --- Main Execution Flow ---

echo "===== Starting i3 environment installation on $(date) =====" > "$LOGFILE"
clear

# -- Welcome Screen --
show_message "Instalador Interativo do Ambiente i3" \
"Bem-vindo. Este script irá guiar você na instalação de um ambiente de desktop completo e produtivo, baseado no gerenciador de janelas i3.

O processo é modular. Você será questionado antes da instalação de cada grupo de pacotes, permitindo controle total sobre o que é instalado.

Requisitos: Conexão com a internet e execução com privilégios de root (sudo).
Todas as ações são registradas em $LOGFILE.

Pressione Enter para iniciar."

# -- Installation Groups --
run_group_install "1. Base do Sistema e Gráficos (Essencial)" "$DESC_BASE" PACKAGES_BASE
run_group_install "2. Ambiente i3 Completo (Essencial)" "$DESC_I3_FULL" PACKAGES_I3_FULL
run_group_install "3. Serviços Essenciais (Rede e Áudio)" "$DESC_SERVICES" PACKAGES_SERVICES
run_group_install "4. Suíte de Aplicativos e Compressão (Opcional)" "$DESC_APPS" PACKAGES_APPS
run_group_install "5. Ambiente de Desenvolvimento (Opcional)" "$DESC_DEVELOPMENT" PACKAGES_DEVELOPMENT
run_group_install "6. Codecs e Ferramentas Multimídia (Opcional)" "$DESC_MULTIMIDIA" PACKAGES_MULTIMIDIA
run_group_install "7. Ferramentas de Terminal Avançadas (Opcional)" "$DESC_TERMINAL_ADVANCED" PACKAGES_TERMINAL_ADVANCED
run_group_install "8. Gestão de Hardware (Opcional)" "$DESC_HARDWARE" PACKAGES_HARDWARE

# -- Final Tasks --
if ask_user_yes_no "Aplicação das Configurações (Dotfile)" "$DESC_DOTFILES"; then
    clone_dotfiles
fi

log_message "Habilitando serviços de sistema..."
is_installed sddm && enable_service sddm.service
is_installed bluez && enable_service bluetooth.service
is_installed cups && enable_service cups.service
is_installed tlp && enable_service tlp.service

# --- Final Report and Instructions ---
FINAL_MESSAGE="A instalação dos pacotes foi concluída.

*** AÇÕES MANUAIS IMPORTANTES: ***

1. REINICIE o computador para que o gerenciador de login (SDDM) seja iniciado.

2. Após reiniciar e fazer login com seu USUÁRIO NORMAL, abra um terminal e execute os seguintes comandos:

   a) Para instalar os codecs de DVD (pode ser necessário):
      sudo dpkg-reconfigure libdvd-pkg

   b) Para copiar os arquivos de configuração do i3 (se você escolheu baixá-los):
      cp -r /opt/i3-starterpack/.config/* ~/.config/
      
   c) Para habilitar os serviços de áudio para o seu usuário:
      systemctl --user enable --now pipewire pipewire-pulse wireplumber

Para detalhes completos, consulte o log em $LOGFILE."

show_message "Instalação Concluída!" "$FINAL_MESSAGE"

log_message "===== Installation finished on $(date) ====="
clear
echo "Instalação concluída. Por favor, reinicie o sistema."
echo "Confira o log para detalhes em $LOGFILE"

exit 0
