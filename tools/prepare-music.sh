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
# O destino de cada arquivo vem de tools/music-map.txt, e NÃO da ordem
# alfabética: os nomes que o Pixabay gera não têm relação com a ordem das
# fases, então adivinhar pela ordem colocaria a faixa errada em cada slot.
#
# Uso:
#   brew install ffmpeg          # uma vez
#   tools/prepare-music.sh ~/Downloads/musicas

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-}"
DEST="$ROOT/audio/music"
MAP="$ROOT/tools/music-map.txt"

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Uso: $0 <pasta-com-as-musicas>" >&2
  exit 1
fi
if [[ ! -f "$MAP" ]]; then
  echo "Mapeamento não encontrado: $MAP" >&2
  exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg não encontrado. Instale com:  brew install ffmpeg" >&2
  exit 1
fi

mkdir -p "$DEST"

ok=0; missing=0; ambiguous=0

while IFS='|' read -r slot pattern; do
  slot="${slot%%[[:space:]]*}"
  [[ -z "$slot" || "$slot" == \#* ]] && continue
  pattern="$(echo "$pattern" | tr -d '\r' | sed 's/[[:space:]]*$//')"
  [[ -z "$pattern" ]] && continue

  # Procura arquivos de áudio cujo nome contenha o trecho.
  matches=()
  while IFS= read -r f; do matches+=("$f"); done < <(
    find "$SRC" -maxdepth 1 -type f \
      \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.m4a' -o -iname '*.ogg' -o -iname '*.flac' -o -iname '*.aac' \) \
      -iname "*${pattern}*" | sort
  )

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "  FALTA     $slot  (nenhum arquivo com \"$pattern\")"
    missing=$((missing+1)); continue
  fi
  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "  AMBÍGUO   $slot  (\"$pattern\" casou com ${#matches[@]} arquivos):"
    printf '              %s\n' "${matches[@]##*/}"
    echo "            Ajuste o trecho em tools/music-map.txt para algo único."
    ambiguous=$((ambiguous+1)); continue
  fi

  src="${matches[0]}"
  echo "  OK        $slot.mp3  <-  $(basename "$src")"
  ffmpeg -hide_banner -loglevel error -y \
    -i "$src" \
    -af loudnorm=I=-16:TP=-1.5:LRA=11 \
    -codec:a libmp3lame -b:a 128k -ar 44100 \
    "$DEST/${slot}.mp3"
  ok=$((ok+1))
done < "$MAP"

echo
echo "Convertidas: $ok   Faltando: $missing   Ambíguas: $ambiguous"

if [[ $ok -gt 0 ]]; then
  echo
  echo "Tamanhos:"
  for f in "$DEST"/*.mp3; do
    [[ -e "$f" ]] || continue
    printf '  %-14s %s\n' "$(basename "$f")" "$(du -h "$f" | cut -f1)"
  done
  total=$(du -ch "$DEST"/*.mp3 2>/dev/null | tail -1 | cut -f1)
  echo "  --------------------"
  echo "  TOTAL          $total  (soma ao download do app)"
fi

if [[ $missing -gt 0 || $ambiguous -gt 0 ]]; then
  echo
  echo "As faixas não resolvidas continuam usando a música procedural."
fi

echo
echo "Depois rode:  cp -R audio www/  &&  npx cap copy ios"
