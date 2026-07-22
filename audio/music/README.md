# Música do AstroSling

Coloque **6 arquivos** nesta pasta com exatamente estes nomes:

| Arquivo | Onde toca |
|---|---|
| `menu.mp3` | Tela de título, menu principal e seleção de fases |
| `galaxy1.mp3` | Gameplay (sorteada) |
| `galaxy2.mp3` | Gameplay (sorteada) |
| `galaxy3.mp3` | Gameplay (sorteada) |
| `galaxy4.mp3` | Gameplay (sorteada) |
| `galaxy5.mp3` | Gameplay (sorteada) |

A cada fase iniciada o jogo sorteia uma das cinco faixas de gameplay — é isso
que faz a música variar durante a partida. A troca usa crossfade de 700ms.

## Requisitos técnicos

- **Formato: MP3** (ou `.m4a`/AAC). **OGG não funciona no iOS/WKWebView.**
- Faixas devem ser feitas para **loop** — o player repete infinitamente, então
  evite silêncio ou fade-out no fim, senão o loop fica com um buraco audível.
- Mantenha cada arquivo **abaixo de ~3 MB** se possível. Os 6 arquivos entram
  no tamanho final do app; ~2 MB cada já dá ~12 MB a mais no download.
- Volume: o player toca a 50%, então masterize as faixas em nível parecido
  entre si. Faixas com volumes muito diferentes ficam desconfortáveis na troca.

## Comportamento se faltar arquivo

Qualquer faixa sem arquivo utilizável cai automaticamente na música procedural
embutida no jogo. Ou seja, o jogo **nunca fica mudo** por causa de um arquivo
faltando — dá para adicionar as faixas aos poucos.

## Licenças — leia antes de publicar

Você precisa ter direito de uso comercial de cada faixa, e **guardar a prova**.
Se a Apple questionar (ou se houver reclamação de copyright), a licença é sua
responsabilidade. Cuidados:

- "Grátis" **não** significa "livre para uso comercial". Verifique a licença.
- Muitas faixas gratuitas exigem **atribuição obrigatória** (ex.: CC BY). Se a
  sua exigir, o crédito precisa aparecer no app — a tela **About** já tem uma
  seção pronta para isso.
- Faixas de domínio público (CC0) não exigem atribuição, mas confirme a fonte.
- Guarde numa pasta os PDFs/prints das licenças e os links de origem.

Sugestão: crie aqui um arquivo `LICENSES.md` anotando, para cada faixa, a
origem, o autor, a licença e se exige atribuição.
