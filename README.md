# learnapp

Documentação de bolso: guias técnicos com diagramas, gráficos e explicações robustas.
Sem login, sem rede — todo o conteúdo é empacotado no app.

```bash
flutter run          # rodar
flutter test         # valida todo o conteúdo e renderiza cada tópico
```

## Estrutura

```
assets/content/
  index.json           # ordem dos tópicos: { "topics": ["gitops.json", ...] }
  gitops.json          # um arquivo por tópico
lib/
  content/             # modelo (models.dart) e carregamento (repository.dart)
  theme/               # cores claro/escuro e tipografia (Geist)
  ui/
    home_page.dart     # busca + filtro por categoria + lista
    topic_page.dart    # índice, seções, barra de progresso
    blocks/            # um widget por tipo de bloco
```

O app usa só `flutter/widgets` (sem Material/Cupertino): ícones, botões e
transições são próprios.

## Adicionando um tópico

1. Crie `assets/content/<id>.json` e inclua o arquivo em `index.json`.
2. Rode `flutter test` — o teste falha se algum bloco for inválido, se um nó de
   diagrama sair da grade ou se uma tabela tiver colunas a mais/menos.

```json
{
  "id": "docker",
  "title": "Docker",
  "summary": "Uma frase.",
  "category": "DevOps",
  "level": "Iniciante",
  "minutes": 10,
  "updated": "out 2026",
  "tags": ["containers"],
  "sections": [
    { "id": "intro", "title": "Introdução", "blocks": [ ... ] }
  ]
}
```

### Séries (guias em partes)

Guias longos são quebrados em partes. Tópicos com o mesmo `series` formam uma
trilha: a lista mostra "PARTE n", a página do tópico ganha o selo "Parte n de N"
e um navegador com todas as partes, e o rodapé aponta para a próxima parte.
Liste as partes em sequência no `index.json`.

```json
{ "id": "kubernetes-2", "title": "Kubernetes 2 — Workloads…", "series": "Kubernetes", "part": 2, ... }
```

### Tipos de bloco

Texto aceita `**negrito**` e `` `código` `` inline.

| `type`    | Campos |
|-----------|--------|
| `p`       | `text` |
| `h`       | `text` (subtítulo dentro da seção) |
| `list`    | `items`, `ordered?` |
| `code`    | `code`, `lang` (`yaml`, `bash`, `json`, `go`, `tree`, `text`), `file?` |
| `callout` | `variant` (`note`, `tip`, `warning`, `danger`), `title?`, `text` |
| `table`   | `headers`, `rows` (3+ colunas viram cartões em telas estreitas) |
| `steps`   | `items: [{ title, text }]` |
| `terms`   | `items: [{ term, def }]` |
| `diagram` | ver abaixo |
| `chart`   | ver abaixo |

### Diagramas

Grade de `cols` × `rows` unidades; a largura da tela é dividida por `cols`.
Use `cols: 12` e posicione pensando em celular. Toque no diagrama abre em tela
cheia com zoom.

```json
{
  "type": "diagram", "title": "Push vs pull", "caption": "...",
  "cols": 12, "rows": 4.5,
  "nodes": [
    { "id": "git", "label": "Git", "sub": "estado desejado", "x": 0, "y": 0.8, "w": 5, "h": 2 },
    { "id": "agent", "label": "Agente", "x": 7, "y": 0.8, "w": 4.5, "h": 2, "variant": "accent" }
  ],
  "edges": [
    { "from": "agent", "to": "git", "label": "pull", "accent": true }
  ],
  "groups": [
    { "label": "Cluster", "x": 6.5, "y": 0, "w": 5.5, "h": 4.5, "labelAt": "bottom" }
  ]
}
```

- `variant` do nó: `normal`, `accent`, `muted`, `dashed`.
- Aresta: `dashed`, `both` (seta nas duas pontas), `accent`, `offset` (desloca
  arestas paralelas, em unidades).
- Deixe ~2 unidades entre nós ligados por aresta com rótulo.

### Gráficos

```json
{ "type": "chart", "kind": "line", "title": "...", "xLabel": "tempo (min)", "yLabel": "RÉPLICAS",
  "yMax": 4, "series": [ { "name": "Desejado", "tone": "muted", "dashed": true, "points": [[0, 3], [20, 3]] } ] }

{ "type": "chart", "kind": "bar", "title": "...", "unit": "s",
  "bars": [ { "label": "Webhook", "value": 5, "display": "segundos" } ] }
```

`tone`: `primary`, `accent`, `muted`. Gráficos de linha mostram crosshair ao
tocar/arrastar. Dados ilustrativos devem ser marcados como tal no `caption`.
