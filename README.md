<img width="1595" height="793" alt="Captura de tela 2026-09-02 134346" src="https://github.com/user-attachments/assets/1df79682-47b3-4f46-9d38-3e34ebda92c1" />

# Nook

Caderninho digital para macOS. Cada **nook** é um ambiente separado com suas
próprias páginas, e cada página é uma folha livre onde você posiciona texto,
listas e figurinhas onde quiser

## O que dá pra fazer

**Escrever.** Caixas de texto com formatação de verdade: negrito, itálico,
sublinhado, sete fontes, sete tamanhos, dez cores e cinco marca-textos pastéis.

**Escolher a folha.** Lisa, pautada ou quadriculada, por página.

**Soltar templates.** Clique pra colocar em cascata ou arraste pra escolher o
lugar exato:

| | |
|---|---|
| **Semana** | sete dias datados, cada um com nota e listinha própria |
| **To-do list** | título editável, riscar, adicionar e remover itens |
| **Water track** | quantidade de copos e volume configuráveis |
| **Imagem / GIF** | busca no GIPHY, ou `Cmd+V`, ou arrastar do navegador |

**Desenhar.** Lápis à mão livre com oito cores, quatro espessuras e borracha.

**Modo claro e escuro**, seguindo o sistema ou fixo.

## Rodar

Precisa de macOS 14+ e Xcode 16+.

```bash
./Scripts/run.sh          # compila, empacota e abre
./Scripts/run.sh release  # build otimizada
swift test                # 9 testes
```

