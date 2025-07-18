# Instalador Interativo i3 para Debian

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shellcheck](https://img.shields.io/badge/shellcheck-passed-brightgreen.svg)
![Debian Version](https://img.shields.io/badge/Debian-13%20Trixie-purple.svg)

Um script interativo e modular para automatizar a configuração de um ambiente de desktop i3 completo e produtivo em uma instalação limpa (mínima/CLI) do Debian 13 "Trixie".

Este projeto foi criado para resolver a tediosa e repetitiva tarefa de instalar e configurar manualmente um ambiente i3 do zero, oferecendo um processo guiado que garante a instalação de todas as ferramentas necessárias para um fluxo de trabalho moderno e eficiente, baseado nos dotfiles de [marcelositr/i3-starterpack](https://github.com/marcelositr/i3-starterpack).

---

## Principais Características

*   **Modularidade:** A instalação é dividida em grupos lógicos (Base, i3, Serviços, Apps, Desenvolvimento, etc.). Você escolhe o que instalar.
*   **Interatividade:** Nenhuma ação é executada sem sua permissão. Uma interface baseada em `dialog` guia você por cada etapa.
*   **Instalação Limpa:** Parte de uma base mínima para garantir que nenhum pacote desnecessário de outros ambientes de desktop seja instalado.
*   **Foco em Produtividade:** Inclui categorias opcionais para instalar um ambiente de desenvolvimento completo (C++/Python) e uma suíte de ferramentas de terminal avançadas (`eza`, `ripgrep`, `fzf`, `btop`, etc.).
*   **Logging Robusto:** Todas as ações, sucessos e erros são registrados em `/root/i3_install.log` para fácil depuração.

## Pré-requisitos

Antes de executar, certifique-se de que você tem:

1.  Uma instalação mínima (sem ambiente gráfico) do **Debian 13 "Trixie"**.
2.  Acesso à internet.
3.  Acesso `root` (o script deve ser executado com `sudo`).

## Como Usar

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/SEU_USUARIO/i3-debian-installer.git
    cd i3-debian-installer
    ```

2.  **Torne o script executável:**
    ```bash
    chmod +x install.sh
    ```

3.  **Execute com privilégios de root:**
    ```bash
    sudo ./install.sh
    ```
Siga as instruções nas caixas de diálogo para selecionar os componentes que deseja instalar.

## Estrutura da Instalação

O script irá oferecer os seguintes grupos de pacotes para instalação:
1.  **Base do Sistema e Gráficos (Essencial)**
2.  **Ambiente i3 Completo (Essencial)**
3.  **Serviços Essenciais (Rede e Áudio)**
4.  **Suíte de Aplicativos e Compressão (Opcional)**
5.  **Ambiente de Desenvolvimento (Opcional)**
6.  **Codecs e Ferramentas Multimídia (Opcional)**
7.  **Ferramentas de Terminal Avançadas (Opcional)**
8.  **Gestão de Hardware (Opcional)**
9.  **Aplicação das Configurações (Dotfile)**

## Pós-Instalação

Após a execução do script, algumas ações manuais são necessárias. O script irá lembrá-lo no final, mas elas são:

- **Reiniciar o sistema.**
- **Executar `sudo dpkg-reconfigure libdvd-pkg`** para finalizar a instalação dos codecs de DVD.
- **Copiar os dotfiles** para sua pasta de usuário (`cp -r /opt/i3-starterpack/.config/* ~/.config/`).
- **Habilitar os serviços de áudio** para o seu usuário (`systemctl --user ...`).

## Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
