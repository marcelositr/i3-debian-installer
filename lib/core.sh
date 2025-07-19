#!/bin/bash

# --- FUNÇÕES CORE (LOGGING E EXECUÇÃO) ---

SPINNER_BRAILLE=('⠟' '⠯' '⠽' '⠾' '⠷' '⠯' '⠟')

log_message() {
    local level="$1"; shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level^^}] ${message}" >> "$LOG_FILE"
}

# REESCRITA COMPLETA: Versão final que não usa 'eval'.
# Argumento 1: Mensagem a ser exibida.
# Argumentos 2..N: O comando e seus argumentos.
run_with_spinner() {
    local message="$1"; shift
    local cmd_and_args=("$@"); local i=0
    local temp_log; temp_log=$(mktemp)

    log_message "CMD" "${cmd_and_args[*]}"
    
    echo -n -e "$message"
    
    # Executa o comando diretamente, passando os argumentos de forma segura.
    "${cmd_and_args[@]}" &> "$temp_log" &
    local pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        echo -n -e " [ ${SPINNER_BRAILLE[i % ${#SPINNER_BRAILLE[@]}]} ]"
        sleep 0.1
        echo -n -e "\r$message"
        ((i++))
    done
    
    wait $pid
    local exit_code=$?
    
    while IFS= read -r line; do log_message "OUTPUT" "$line"; done < "$temp_log"
    rm "$temp_log"

    log_message "INFO" "Comando finalizado com código de saída: $exit_code"

    if [ $exit_code -eq 0 ]; then
        echo -e "\r$message [ ${GREEN}✔ Concluído!${NC} ]"
        log_message "SUCCESS" "Comando bem-sucedido."
    else
        echo -e "\r$message [ ${RED}✖ ERRO!${NC}      ]"
        echo -e "${YELLOW}Consulte o log para detalhes: ${LOG_FILE}${NC}"
        log_message "FAIL" "Comando falhou."
        exit 1
    fi
}