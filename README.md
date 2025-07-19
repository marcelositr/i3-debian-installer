# Ferramenta de Gerenciamento de Ambiente Debian (v15.0 "Final Polish")

![Licença](https://img.shields.io/badge/license-MIT-blue.svg) ![Versão](https://img.shields.io/badge/version-15.0-brightgreen.svg) ![Shell](https://img.shields.io/badge/shell-bash-green.svg)

Este projeto é uma ferramenta de linha de comando robusta para automatizar a instalação, remoção e configuração de um ambiente de desenvolvimento completo em sistemas Debian, com foco em i3wm e ferramentas de terminal.

Ele foi projetado desde o início para ser seguro, interativo, modular e amigável para a comunidade open-source.

## Princípios de Design

*   **Segurança Primeiro:** O script roda como um usuário normal e só invoca `sudo` quando estritamente necessário, após validar a sessão uma vez. Grupos de pacotes essenciais são protegidos contra remoção.
*   **Interface Consistente:** Todas as interações com o usuário são feitas através de uma interface visual consistente baseada em `dialog`, proporcionando uma experiência clara e profissional.
*   **Configuração Externa:** Os pacotes e grupos são gerenciados no arquivo `pacotes.conf`. Isso permite a customização completa do ambiente sem alterar a lógica do programa.
*   **Modularidade Lógica:** O código é dividido em bibliotecas (`lib/`) com responsabilidades únicas (core, parser, ui), tornando o projeto mais limpo e fácil de manter.
*   **Diagnóstico Inteligente:** O comando `drivers` realiza uma série de checagens (Virtualização, Secure Boot, etc.) para prevenir problemas comuns antes que eles aconteçam.
*   **Logging Profissional:** A cada execução, um arquivo de log detalhado e estruturado é criado em `/tmp/debian_manager_*.log`. Este arquivo é essencial para diagnosticar qualquer problema com precisão.

## Estrutura do Projeto

O projeto é organizado da seguinte forma:

```
.
├── gerenciador.sh      (O motor principal / roteador)
├── pacotes.conf        (Onde você customiza os pacotes)
├── LICENSE             (A licença do projeto)
├── README.md           (Esta documentação)
└── lib/                (Bibliotecas com a lógica principal)
    ├── core.sh         (Funções de logging e execução de comandos)
    ├── parser.sh       (Lógica para ler o pacotes.conf e processar grupos)
    └── ui.sh           (Toda a lógica de interface com o usuário via 'dialog')
```
*(Nota: A pasta `post-install.d/` foi descontinuada e sua lógica foi centralizada nas bibliotecas para um melhor controle do fluxo.)*

## Como Usar

1.  **Clone o projeto (ou crie os arquivos manualmente):**
    ```bash
    # Exemplo: git clone https://github.com/marcelositr/i3-debian-installer.git
    cd seu-repositorio
    ```

2.  **Torne o script principal executável:**
    ```bash
    chmod +x gerenciador.sh
    ```

3.  **Execute o comando desejado (como usuário normal):**
    *   **Para instalar o ambiente:**
        ```bash
        ./gerenciador.sh install
        ```
    *   **Para remover grupos de pacotes:**
        ```bash
        ./gerenciador.sh remove
        ```
    *   **Para instalar drivers de hardware:**
        ```bash
        ./gerenciador.sh drivers
        ```
    *   **Para ver a ajuda:**
        ```bash
        ./gerenciador.sh help
        ```

## Customização

A beleza desta ferramenta está na sua flexibilidade.

*   **Para alterar pacotes:** Simplesmente edite as listas e os grupos no arquivo `pacotes.conf`.
*   **Para alterar a aparência:** Crie um arquivo `~/.dialogrc` para customizar as cores de todas as janelas do assistente.
*   **Para adicionar novas ações de pós-instalação:**
    1.  Adicione uma nova função `ui_...` no arquivo `lib/ui.sh`.
    2.  Chame essa nova função de dentro da função `run_post_install_flow` no `gerenciador.sh`, na ordem que desejar.

## Licença

Este projeto está sob a Licença MIT. Veja o arquivo `LICENSE` para mais detalhes. Sinta-se livre para usar, modificar e distribuir.
