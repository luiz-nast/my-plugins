# my-plugins

Instala 8 ferramentas de economia de tokens do Claude Code: ponytail, caveman, rtk, headroom, graphify, superpowers, code-review, context7.

Sem perguntas, pula o que já está instalado, telemetria do rtk desligada.

**Ubuntu**
```bash
curl -fsSL https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.ps1 | iex
```

Requer o Claude Code (`claude`) já instalado. No Windows usa `winget` e `uv`.

> ⚠️ ponytail tem bug conhecido no Windows: trava cada mensagem por alguns segundos.
> O `install.ps1` não foi testado (só o `install.sh`).

## Depois de instalar
- **headroom** só comprime se o Claude for aberto assim (terminal, não o app Desktop): `headroom wrap claude`
- **context7** pede login uma vez: dentro do Claude Code, `/mcp` → context7 → Authenticate
