#!/usr/bin/env bash
# Instala 8 ferramentas do Claude Code (Ubuntu). Pula o que já existe.
set -e
export PATH="$HOME/.local/bin:$PATH"
has() { command -v "$1" >/dev/null 2>&1; }
plug() { claude plugin list 2>/dev/null | grep -q "$1@" || claude plugin install "$1@$2"; }

has claude || { echo "instale o Claude Code antes"; exit 1; }
has pipx   || { sudo apt install -y pipx && pipx ensurepath; }

# plugins de marketplace
claude plugin marketplace add DietrichGebert/ponytail  2>/dev/null || true
claude plugin marketplace add JuliusBrussee/caveman    2>/dev/null || true
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
plug ponytail ponytail
plug caveman caveman
for p in superpowers code-review context7; do plug $p claude-plugins-official; done

# rtk: binário + hook global, sem perguntas, telemetria off
has rtk || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
rtk init -g --auto-patch </dev/null
rtk telemetry disable

# headroom e graphify (pipx)
has headroom || { pipx install "headroom-ai[all]" && headroom mcp install --agent claude; }
has graphify || { pipx install graphifyy && graphify install; }

echo "ok. reinicie o Claude Code."
