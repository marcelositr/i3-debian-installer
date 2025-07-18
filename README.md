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

O script irá oferecer os seguintes grupos de pacotes para instalação. Clique em cada categoria para ver os pacotes incluídos.

<details>
<summary><strong>1. Base do Sistema e Gráficos (Essencial)</strong></summary>

*   `xorg`, `xinit`, `build-essential`, `git`, `vim`, `nano`, `dialog`, `bash-completion`
</details>

<details>
<summary><strong>2. Ambiente i3 Completo (Essencial)</strong></summary>

*   **i3 e Ferramentas:** `i3`, `i3status`, `i3lock`, `dunst`, `suckless-tools`, `rxvt-unicode`, `rofi`, `xsel`
*   **Gerenciador de Login:** `sddm`, `sddm-theme-debian-breeze`
*   **Visual:** `picom`, `hsetroot`, `lxappearance`, `fonts-noto`, `fonts-font-awesome`
</details>

<details>
<summary><strong>3. Serviços Essenciais (Rede e Áudio)</strong></summary>

*   `network-manager-gnome`, `pipewire`, `pipewire-pulse`, `wireplumber`, `pavucontrol`, `alsa-utils`
</details>

<details>
<summary><strong>4. Suíte de Aplicativos e Compressão (Opcional)</strong></summary>

*   **Aplicativos XFCE:** `thunar`, `tumbler`, `file-roller`, `mousepad`, `ristretto`, `xfce4-taskmanager`, `xfce4-power-manager`, `xfce4-screenshooter`, `xfce4-terminal`, `gvfs-backends`
*   **Plugins do Thunar:** `thunar-archive-plugin`, `thunar-media-tags-plugin`
*   **Suporte a Compressão:** `zip`, `unzip`, `tar`, `gzip`, `bzip2`, `xz-utils`, `p7zip-full`, `zstd`, `unrar`, `lrzip`, `lzip`, `squashfs-tools`, `cabextract`
</details>

<details>
<summary><strong>5. Ambiente de Desenvolvimento (Opcional)</strong></summary>

*   **IDE:** `geany`, `geany-plugins`
*   **C/C++:** `gdb`, `cmake`, `meson`, `clang`, `clang-format`, `clang-tidy`
*   **Python:** `python3-dev`, `python3-pip`, `python3-venv`, `python3-flake8`, `python3-black`, `python3-numpy`
</details>

<details>
<summary><strong>6. Codecs e Ferramentas Multimídia (Opcional)</strong></summary>

*   **Players e Codecs:** `vlc`, `vlc-plugin-qt`, `gstreamer1.0-plugins-bad`, `gstreamer1.0-plugins-ugly`, `libdvd-pkg`, `libavcodec-extra`
*   **Ferramentas de Linha de Comando:** `ffmpeg`, `yt-dlp`, `mediainfo`, `sox`
</details>

<details>
<summary><strong>7. Ferramentas de Terminal Avançadas (Opcional)</strong></summary>

*   **Shells e Sessões:** `fish`, `tmux`, `starship`
*   **Navegação:** `eza`, `ranger`, `lf`, `tree`
*   **Busca:** `ripgrep`, `fd-find`, `fzf`
*   **Visualização:** `bat`, `jq`
*   **Monitoramento:** `htop`, `btop`
*   **Automação e TUI:** `xdotool`, `shellcheck`, `taskwarrior`, `glow`, `lazygit`, `lazydocker`, `ueberzug`, `w3m-img`
</details>

<details>
<summary><strong>8. Gestão de Hardware (Opcional)</strong></summary>

*   `bluez`, `blueman`, `cups`, `system-config-printer`, `xautolock`
</details>

<details>
<summary><strong>9. Aplicação das Configurações (Dotfile)</strong></summary>

*   Esta etapa não instala pacotes, mas executa uma ação: clona o repositório `https://github.com/marcelositr/i3-starterpack.git` para `/opt/i3-starterpack`.
</details>

## Pós-Instalação

Após a execução do script, algumas ações manuais são necessárias. O script irá lembrá-lo no final, mas elas são:

- **Reiniciar o sistema.**
- **Executar `sudo dpkg-reconfigure libdvd-pkg`** para finalizar a instalação dos codecs de DVD.
- **Copiar os dotfiles** para sua pasta de usuário (`cp -r /opt/i3-starterpack/.config/* ~/.config/`).
- **Habilitar os serviços de áudio** para o seu usuário (`systemctl --user ...`).

## Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
