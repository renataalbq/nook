<img src="docs/icon.png" width="96" align="right" alt="">

# Nook

Caderninho digital para macOS. Cada **nook** é um ambiente separado com suas
próprias páginas, e cada página é uma folha livre onde você posiciona texto,
listas e figurinhas onde quiser — não é um documento que empurra tudo pra
baixo, é uma superfície.

## O que dá pra fazer

**Escrever.** Caixas de texto com formatação de verdade: negrito, itálico,
sublinhado, sete fontes, sete tamanhos, dez cores e cinco marca-textos pastéis.

**Escolher a folha.** Lisa, pautada ou quadriculada, por página. Em folha
pautada o texto encaixa nas linhas; os widgets ficam livres.

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

`Scripts/bundle.sh` monta o `.app` — SwiftPM sozinho só produz um binário solto,
sem `Info.plist` nem ícone.

Pra mexer no ícone: edita `variantA` em `Scripts/make_icon.swift` (é desenho em
CoreGraphics, não imagem) e roda `./Scripts/make_icon.sh`.

## Onde ficam suas notas

```
~/Library/Application Support/Nook/
  library.json                     tudo que você escreveu
  library-backup.json              cópia do último carregamento bom
  Assets/                          imagens e GIFs, copiados pra cá
```

Imagens são copiadas pra dentro do app, então a página continua funcionando se
você mover ou apagar o arquivo original.

Um `library.json` que o app não consiga ler nunca é sobrescrito — ele é movido
pra `library-unreadable-<data>.json` e preservado.

## Busca de GIF

A busca usa a GIPHY API e precisa de uma chave sua, criada em
[developers.giphy.com](https://developers.giphy.com) (tipo **API**, não SDK).
Cole no painel `✨` dentro de templates. A chave fica em `UserDefaults`, na sua
máquina — não está no código.

Sem chave, `Cmd+V` e arrastar do navegador continuam funcionando.

## Estrutura

```
Sources/Nook/
  Models/     dados e a decodificação tolerante do save
  Store/      persistência e seleção
  Input/      atalhos de teclado
  Services/   GIPHY, importação de imagem, formatação de texto
  Design/     paleta e geometria do papel
  Views/
    Chrome/   janela, barras, painéis
    Canvas/   folha, caixas, editor de texto, lápis
    Widgets/  os templates
Tests/
```

## Detalhes que valem saber

O editor de texto é um `NSTextView` embrulhado, não o `TextEditor` do SwiftUI —
esse último só aceita `String` pura e o app precisa de fonte, tamanho e cor por
trecho.

Os modelos decodificam à mão. O `Codable` sintetizado do Swift ignora valores
padrão: campo ausente no JSON lança `keyNotFound`, o que fazia cada campo novo
tornar ilegível todo arquivo salvo antes. `Tests/NookTests` guarda esse
comportamento com arquivos de versões antigas.

## Estado

Alpha, uso pessoal. Não tem sincronização, conta, nem versão iOS.
