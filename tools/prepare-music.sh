#!/usr/bin/env bash
# Prepara as músicas baixadas para o AstroSling.
#
# O que faz com cada arquivo:
#   - converte para MP3 (o iOS/WKWebView não toca OGG)
#   - normaliza o volume para -16 LUFS, para que as faixas não fiquem com
#     volumes diferentes entre si na hora do crossfade
#   - reduz para 128 kbps, mantendo o tamanho do app sob controle
#   - grava com o nome exato que o jogo espera
#
# Uso:
#   brew install ffmpeg          # uma vez
#   tools/prepare-music.sh ~/Downloads/musicas
#
# A pasta de origem deve conter 6 arquivos de áudio. Eles são atribuídos em
# ordem alfabética a: menu, galaxy1..galaxy5. Renomeie os originais com um
# prefixo (1-menu, 2-galaxy...) para controlar a ordem.

set -euo pipefail

SRC="${1:-}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/audio/music"
NAMES=(menu galaxy1 galaxy2 galaxy3 galaxy4 galaxy5)

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Uso: $0 <pasta-com-as-musicas>" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg não encontrado. Instale com:  brew install ffmpeg" >&2
  exit 1
fi

# Coleta os arquivos de áudio em ordem alfabética.
files=()
while IFS= read -r f; do files+=("$f"); done < <(
  find "$SRC" -maxdepth 1 -type f \
    \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.m4a' -o -iname '*.ogg' -o -iname '*.flac' -o -iname '*.aac' \) \
    | sort
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Nenhum arquivo de áudio encontrado em: $SRC" >&2
  exit 1
fi

echo "Encontrados ${#files[@]} arquivo(s). Destino: $DEST"
echo

mkdir -p "$DEST"

count=0
for i in "${!files[@]}"; do
  [[ $i -ge ${#NAMES[@]} ]] && { echo "Ignorando extra: $(basename "${files[$i]}")"; continue; }
  src="${files[$i]}"
  out="$DEST/${NAMES[$i]}.mp3"
  echo "→ $(basename "$src")"
  echo "   vira ${NAMES[$i]}.mp3"
  ffmpeg -hide_banner -loglevel error -y \
    -i "$src" \
    -af loudnorm=I=-16:TP=-1.5:LRA=11 \
    -codec:a libmp3lame -b:a 128k -ar 44100 \
    "$out"
  count=$((count+1))
done

echo
echo "Convertidos: $count"
echo
echo "Tamanhos finais:"
ls -lh "$DEST"/*.mp3 2>/dev/null | awk '{printf "  %-16s %s\n", $9, $5}' | sed "s|$DEST/||"
total=$(du -ch "$DEST"/*.mp3 2>/dev/null | tail -1 | cut -f1)
echo "  ------------------------"
echo "  TOTAL            $total   (soma ao tamanho do download do app)"
echo
if [[ $count -lt ${#NAMES[@]} ]]; then
  echo "Faltam $(( ${#NAMES[@]} - count )) faixa(s). As ausentes usam a música procedural."
fi
echo "Agora rode:  npx cap copy ios"
