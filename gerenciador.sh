#!/bin/bash

# ==============================================================================
# ===              FERRAMENTA DE GERENCIAMENTO DE AMBIENTE DEBIAN              ===
# ==============================================================================
#
# Autor: Seu Nome (com assistência de IA)
# Versão: 15.0 "Final Polish"
#
# Este script é o ponto de entrada principal (roteador). Ele define
# variáveis globais, carrega as bibliotecas e inicia o fluxo de comando.
#
# ==============================================================================

# --- CONFIGURAÇÕES E DEFINIÇÕES GLOBAIS ---
set -o pipefail
export GREEN='\033[1;32m'; export YELLOW='\033[1;33m'; export BLUE='\033[1;34m'; export RED='\033[1;31m'; export NC='\033[0m'
export LOG_FILE="/tmp/debian_manager_$(date +%Y-%m-%d_%H-%M-%S).log"
export CONFIG_FILE="pacotes.conf"
export POST_INSTALL_DIR="post-install.d"
export LIB_DIR="lib"

# --- CARREGAMENTO DAS BIBLIOTECAS ---
if ! [ -d "$LIB_DIR" ]; then echo -e "${RED}ERRO: Diretório '${LIB_DIR}' não encontrado.${NC}" >&2; exit 1; fi
for lib_file in "$LIB_DIR"/*.sh; do if [ -f "$lib_file" ]; then source "$lib_file"; fi; done
export -f log_message run_with_spinner

# --- FUNÇÕES DE FLUXO PRINCIPAL (MAIN) ---

mostrar_help() {
    echo -e "${GREEN}Ferramenta de Gerenciamento de Ambiente Debian (v15.0)${NC}"
    echo -e "---------------------------------------------------------"
    echo -e "Usa os arquivos de configuração em '${YELLOW}${CONFIG_FILE}${NC}' e as bibliotecas em '${YELLOW}${LIB_DIR}/${NC}'."
    echo; echo -e "Um log detalhado de cada execução é salvo em '${YELLOW}${LOG_FILE}${NC}'."
    echo; echo -e "${YELLOW}Uso:${NC}  $0 [comando]"; echo
    echo -e "${YELLOW}Comandos disponíveis:${NC}";
    echo -e "  ${GREEN}install${NC}       Inicia a instalação e configuração do ambiente."
    echo -e "  ${GREEN}remove${NC}        Inicia a remoção completa de grupos de pacotes."
    echo -e "  ${GREEN}drivers${NC}       Inicia o assistente de detecção de drivers."
    echo -e "  ${GREEN}help, -h${NC}      Mostra esta mensagem de ajuda."
}

# REVISÃO COMPLETA: pre_flight_checks agora é 100% dialog e proativo.
pre_flight_checks() {
    log_message "INFO" "Iniciando verificação de pré-execução."
    if [[ $EUID -eq 0 ]]; then log_message "ERROR" "Script executado como root."; echo -e "${RED}ERRO: Execute como usuário normal.${NC}" >&2; exit 1; fi
    for f in "$CONFIG_FILE" "$LIB_DIR"; do if ! [ -e "$f" ]; then log_message "ERROR" "Recurso faltante: $f"; echo -e "${RED}ERRO: Recurso faltante: $f${NC}" >&2; exit 1; fi; done
    
    # Etapa 1: Boas-vindas
    dialog --backtitle "Assistente de Instalação Debian" --title "Bem-vindo!" --msgbox "Este assistente usará 'sudo' para tarefas administrativas.\\n\\nPor segurança, sempre saiba o que um script faz antes de conceder acesso com sua senha.\\n\\nVocê precisará validar sua sessão com 'sudo' a seguir." 12 70

    # Etapa 2: Checagem proativa de repositórios
    log_message "INFO" "Verificando /etc/apt/sources.list para componentes contrib e non-free."
    local missing_components=()
    local active_sources; active_sources=$(grep -E '^\s*deb\s' /etc/apt/sources.list)
    if echo "$active_sources" | grep -qv 'contrib'; then missing_components+=("contrib"); fi
    if echo "$active_sources" | grep -qv 'non-free'; then missing_components+=("non-free"); fi
    if [ ${#missing_components[@]} -gt 0 ]; then
        log_message "WARN" "Componentes de repositório faltantes: ${missing_components[*]}"
        dialog --title "Aviso de Repositórios" --msgbox "Detectamos que seus repositórios podem não ter os componentes 'contrib' e 'non-free' habilitados.\\n\\nPara garantir acesso a todos os drivers e pacotes (como 'unrar'), é ALTAMENTE RECOMENDADO que você os habilite manualmente em /etc/apt/sources.list.\\n\\nO script continuará, mas algumas instalações podem falhar." 15 75
    fi

    # Etapa 3: Validação do sudo (agora no terminal)
    clear
    echo -e "${YELLOW}Por favor, valide sua sessão sudo abaixo...${NC}"
    log_message "INFO" "Validando sessão sudo com 'sudo -v'."
    if ! sudo -v; then log_message "ERROR" "Falha na validação do sudo."; echo -e "${RED}ERRO: Falha na validação do sudo.${NC}"; exit 1; fi
    log_message "SUCCESS" "Sessão sudo validada."
    if ! command -v dialog &> /dev/null; then log_message "WARN" "'dialog' não encontrado."; run_with_spinner "Instalando 'dialog'..." sudo apt-get install -y dialog; fi
}

run_system_update() {
    if dialog --title "Atualização do Sistema" --yesno "Deseja sincronizar repositórios e atualizar os pacotes do sistema agora? (Recomendado antes de instalar)" 8 70; then
        run_with_spinner "Sincronizando repositórios (apt update)..." sudo apt-get update
        run_with_spinner "Atualizando pacotes do sistema (apt upgrade)..." sudo apt-get upgrade -y
    fi
}

run_post_install_flow() {
    dialog --title "Fase 2: Configuração" --msgbox "A instalação dos pacotes foi concluída.\\n\\nAgora, vamos iniciar a fase de configuração do seu ambiente pessoal." 8 70
    ui_run_fish_setup
    ui_run_git_setup
    ui_run_ssh_setup
    ui_configure_screenlock
    if dialog --title "Serviços do Sistema" --yesno "Deseja habilitar os serviços essenciais (login gráfico, bluetooth, impressão) para iniciarem com o sistema?" 8 70; then
        run_with_spinner "Habilitando serviços do sistema..." sudo systemctl enable lightdm bluetooth cups
    fi
    ui_manage_dotfiles
}

main_install() {
    pre_flight_checks
    run_system_update
    parse_config_and_process "install"
    run_post_install_flow
    log_message "SUCCESS" "Fluxo de instalação e configuração concluído."
    dialog --title "Processo Finalizado" --msgbox "O processo foi concluído com sucesso!\\n\\nÉ ALTAMENTE recomendado reiniciar o sistema para que todas as alterações tenham efeito." 10 70
}

main_remove() {
    pre_flight_checks
    parse_config_and_process "remove"
    if dialog --title "Limpeza Final" --yesno "Deseja limpar o cache de pacotes baixados (apt clean)?" 7 60; then
        run_with_spinner "Limpando o cache do apt..." sudo apt-get clean
    fi
    log_message "SUCCESS" "Fluxo de remoção concluído."
}

# REESCRITA COMPLETA: main_drivers agora usa 100% dialog
main_drivers() {
    pre_flight_checks
    log_message "INFO" "Iniciando fluxo 'drivers'."
    
    local virt_type; virt_type=$(systemd-detect-virt)
    if [ "$virt_type" != "none" ]; then
        log_message "INFO" "VM '${virt_type}' detectada."
        if dialog --title "Ambiente Virtual Detectado" --yesno "Detectamos uma máquina virtual (${virt_type}).\n\nDeseja instalar os pacotes de otimização (guest-utils) em vez de procurar por drivers de hardware?" 10 70; then
            run_with_spinner "Instalando pacotes para VMs..." sudo apt-get install -y open-vm-tools virtualbox-guest-utils
        fi
        log_message "SUCCESS" "Fluxo 'drivers' concluído (modo VM)."; exit 0
    fi

    if ! ping -c 1 deb.debian.org &> /dev/null; then
        log_message "ERROR" "Sem conexão com a internet."; dialog --title "Erro de Rede" --msgbox "Não foi possível estabelecer uma conexão com a internet. Por favor, verifique sua rede e tente novamente." 7 60; exit 1
    fi
    
    # A função check_and_configure_sources não existe mais, a lógica foi movida para pre_flight_checks
    # Aqui, poderíamos rodar um apt update para garantir que a lista está fresca, mesmo que não seja um upgrade
    run_with_spinner "Sincronizando repositórios (apt update)..." sudo apt-get update

    run_with_spinner "Instalando ferramentas de diagnóstico..." sudo apt-get install -y pciutils nvidia-detect isenkram-cli mokutil
    
    if lspci | grep -iq "nvidia"; then
        log_message "INFO" "Placa de vídeo NVIDIA detectada."
        local sb_status; sb_status=$(mokutil --sb-state)
        log_message "INFO" "Status do Secure Boot: ${sb_status}"
        local install_nvidia=false
        if [[ "$sb_status" == "SecureBoot enabled" ]]; then
            log_message "WARN" "Secure Boot está ATIVO."
            if dialog --title "AVISO CRÍTICO: Secure Boot" --yesno "Seu sistema está com o Secure Boot ATIVO.\n\nO driver padrão da NVIDIA não funcionará neste modo.\n\nVocê precisará desabilitar o Secure Boot na BIOS/UEFI APÓS a instalação.\n\nDeseja continuar mesmo assim?" 15 75; then
                install_nvidia=true
            fi
        else
            install_nvidia=true
        fi
        if [ "$install_nvidia" = true ]; then
            local driver; driver=$(nvidia-detect | grep -o 'nvidia-.*' | head -n 1)
            if [ -n "$driver" ]; then
                if dialog --title "Driver NVIDIA" --yesno "O sistema recomenda instalar o pacote: '${driver}'.\n\nDeseja instalar agora?" 8 70; then
                    run_with_spinner "Instalando driver NVIDIA..." sudo apt-get install -y "$driver"
                fi
            else
                log_message "WARN" "nvidia-detect não recomendou um driver."; dialog --title "Driver NVIDIA" --msgbox "'nvidia-detect' não recomendou um driver específico." 7 60
            fi
        fi
    fi

    local fw; fw=$(sudo isenkram-cli -l | tr '\n' ' ')
    if [ -n "$fw" ]; then
        log_message "WARN" "Firmware faltante detectado: $fw"
        if dialog --title "Firmware Faltante" --yesno "Firmwares faltantes detectados.\n\nRecomendados:\n${fw}\n\nDeseja instalar?" 12 70; then
            run_with_spinner "Instalando pacotes de firmware..." sudo apt-get install -y "$fw"
        fi
    fi

    dialog --title "Processo Finalizado" --msgbox "O assistente de drivers foi concluído.\n\nÉ ALTAMENTE RECOMENDADO reiniciar o computador agora." 10 70
}

# --- PONTO DE ENTRADA DO SCRIPT ---

if [ "$1" == "" ]; then mostrar_help; exit 1; fi
rm -f "$LOG_FILE" &> /dev/null
log_message "INFO" "--- Início da execução v15.0 ---"; log_message "INFO" "Argumentos recebidos: $*"
case "$1" in
    install|remove|drivers|help|-h|--help) log_message "INFO" "Comando '$1' reconhecido." ;;
    *) log_message "ERROR" "Comando inválido '$1'."; echo -e "${RED}Erro: '$1' inválido.${NC}\n"; mostrar_help; exit 1 ;;
esac
case "$1" in
    install) main_install ;;
    remove) main_remove ;;
    drivers) main_drivers ;;
    help|-h|--help) mostrar_help ;;
esac
log_message "INFO" "--- Fim da execução ---"
exit 0