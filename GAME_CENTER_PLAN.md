# AstroSling — Plano de Integração Game Center

> Objetivo: adicionar Game Center nativo (leaderboards + achievements) para
> fortalecer a defesa contra a rejeição **4.3(a) — Spam**. O sinal mais forte
> não é o código JavaScript, e sim a **capability Game Center** que o Xcode
> grava no arquivo de entitlements (`com.apple.developer.game-center`). Isso
> é um binding nativo verificável pela Apple — algo que um "template WebView
> genérico" não possui.
>
> **NÃO aplicar enquanto o build 4 estiver em revisão.** Este é o plano de
> contingência caso a Apple recuse novamente.

---

## Visão geral do que será adicionado

| Item | Onde | O que faz |
|------|------|-----------|
| Capability Game Center | Xcode → Signing & Capabilities | Grava o entitlement nativo (sinal anti-spam) |
| Plugin `@openforge/capacitor-game-connect` | `npm` + `npx cap sync` | Ponte JS ↔ GameKit nativo |
| 2 Leaderboards | App Store Connect | Endless high score + Speed Run best time |
| Achievements no Game Center | App Store Connect | Espelham os achievements internos que já existem |
| Módulo `GameCenter` (JS) | `index.html` | Wrapper que envia scores/achievements |
| 4 pontos de engate | `index.html` | Chamam o wrapper nos lugares certos |

---

## Passo 1 — Instalar o plugin

```bash
cd /Users/arassink/Documents/GitHub/AstroSling
npm install @openforge/capacitor-game-connect
npx cap sync ios
```

> `@openforge/capacitor-game-connect` é o plugin de Game Center para Capacitor
> mais mantido. **Confirme os nomes exatos dos métodos** na versão instalada
> (`node_modules/@openforge/capacitor-game-connect/README.md`) — a API abaixo
> segue a v6/v7. Se algum método tiver nome diferente (ex.: `submitScore` vs
> `saveScore`), ajuste o wrapper — a lógica de engate permanece igual.

API esperada do plugin:
- `GameConnect.signIn()`
- `GameConnect.submitScore({ leaderboardID, totalScoreAmount })`
- `GameConnect.showLeaderboard({ leaderboardID })` / `showAllLeaderboards()`
- `GameConnect.unlockAchievement({ achievementID })`
- `GameConnect.showAchievements()`

---

## Passo 2 — Ativar a capability no Xcode (o passo mais importante)

1. Abra `ios/App/App.xcodeproj` no Xcode.
2. Selecione o target **App** → aba **Signing & Capabilities**.
3. Clique em **+ Capability** → adicione **Game Center**.
4. Isso cria/atualiza `ios/App/App/App.entitlements` com:
   ```xml
   <key>com.apple.developer.game-center</key>
   <true/>
   ```
5. Confirme que o App ID no Developer Portal tem "Game Center" habilitado
   (o Xcode normalmente faz isso automaticamente com signing automático).

> Só esse passo já diferencia o binário. Os passos seguintes dão a
> funcionalidade real por trás dele.

---

## Passo 3 — Criar os Leaderboards no App Store Connect

App Store Connect → seu app → **Recursos** (Features) → **Game Center** →
**Leaderboards** → **+**.

### Leaderboard 1 — Endless High Score
| Campo | Valor |
|-------|-------|
| Leaderboard ID | `endless_highscore` |
| Tipo | Classic |
| Score Format Type | Integer |
| Sort Order | **High to Low** |
| Score Range (opcional) | 0 – 999999 |

### Leaderboard 2 — Speed Run Best Time
| Campo | Valor |
|-------|-------|
| Leaderboard ID | `speedrun_besttime` |
| Tipo | Classic |
| Score Format Type | **Elapsed Time — to the Hundredth of a Second** |
| Sort Order | **Low to High** (menor tempo = melhor) |

> Para o tempo, o Game Center guarda **inteiros**. Enviamos o tempo em
> centésimos de segundo (`segundos * 100`). O formato "Elapsed Time to the
> Hundredth" faz o Game Center exibir como `M:SS.CC` automaticamente.

---

## Passo 4 — Criar os Achievements no App Store Connect

App Store Connect → **Game Center** → **Achievements** → **+**.

Não precisa espelhar todos os 39 achievements internos. Comece com um conjunto
curado de marcos (os mais significativos). Cada um precisa de um **Achievement
ID** único. Sugestão de mapeamento (ID interno → Achievement ID no Game Center):

| Interno (`ACHIEVEMENT_DEFS.id`) | Game Center Achievement ID | Pontos | Descrição |
|------|------|------|------|
| `first_steps` | `ach_first_steps` | 5 | Complete seu primeiro nível |
| `master_sling` | `ach_master_sling` | 50 | Complete todos os 25 níveis |
| `galaxy_explorer` | `ach_galaxy_explorer` | 20 | Complete as 10 galáxias originais |
| `stargazer` | `ach_stargazer` | 15 | Colete 30 estrelas no total |
| `sharpshooter` | `ach_sharpshooter` | 10 | Complete um nível no 1º tiro |
| `bounce_master` | `ach_bounce_master` | 10 | 10 rebotes em paredes |
| `portal_jumper` | `ach_portal_jumper` | 10 | Use portais 5 vezes |
| `gravity_dancer` | `ach_gravity_dancer` | 10 | Complete um nível de gravidade reversa |
| `endless_drifter` | `ach_endless_drifter` | 20 | 500+ pontos no modo Endless |
| `daily_ace` | `ach_daily_ace` | 15 | Complete um desafio diário |

> Você pode adicionar os 25 achievements por nível depois. O `ACH_MAP` no
> código só reporta os que existirem no App Store Connect; os demais são
> ignorados silenciosamente, então dá pra crescer aos poucos sem quebrar nada.

---

## Passo 5 — Adicionar o módulo `GameCenter` no `index.html`

Cole este bloco **logo após o objeto `AdManager`** (ele termina por volta da
linha 1130), mantendo o mesmo estilo dos outros managers:

```javascript
// ── GAME CENTER (GameKit via @openforge/capacitor-game-connect) ──
const GameCenter = {
  _authed: false,
  LEADERBOARDS: {
    endless:  'endless_highscore',
    speedrun: 'speedrun_besttime',
  },
  // ID interno (ACHIEVEMENT_DEFS) → Achievement ID no App Store Connect.
  // Só reporta os que existem aqui; os outros são ignorados.
  ACH_MAP: {
    first_steps:    'ach_first_steps',
    master_sling:   'ach_master_sling',
    galaxy_explorer:'ach_galaxy_explorer',
    stargazer:      'ach_stargazer',
    sharpshooter:   'ach_sharpshooter',
    bounce_master:  'ach_bounce_master',
    portal_jumper:  'ach_portal_jumper',
    gravity_dancer: 'ach_gravity_dancer',
    endless_drifter:'ach_endless_drifter',
    daily_ace:      'ach_daily_ace',
  },

  async init() {
    if (!window.Capacitor?.isNativePlatform()) return;
    try {
      const { GameConnect } = Capacitor.Plugins;
      if (!GameConnect) return;
      await GameConnect.signIn();          // mostra o overlay "Welcome back" do GC
      this._authed = true;
    } catch (e) {
      console.warn('GameCenter sign-in failed:', e);
    }
  },

  async submitEndless(score) {
    if (!this._authed) return;
    try {
      const { GameConnect } = Capacitor.Plugins;
      await GameConnect.submitScore({
        leaderboardID: this.LEADERBOARDS.endless,
        totalScoreAmount: Math.round(score),
      });
    } catch (e) { console.warn('submitEndless:', e); }
  },

  // elapsed em segundos (float). Enviamos em centésimos (inteiro).
  async submitSpeedRun(seconds) {
    if (!this._authed) return;
    try {
      const { GameConnect } = Capacitor.Plugins;
      await GameConnect.submitScore({
        leaderboardID: this.LEADERBOARDS.speedrun,
        totalScoreAmount: Math.round(seconds * 100),
      });
    } catch (e) { console.warn('submitSpeedRun:', e); }
  },

  async reportAchievement(internalId) {
    if (!this._authed) return;
    const gcId = this.ACH_MAP[internalId];
    if (!gcId) return;                       // achievement sem espelho no GC
    try {
      const { GameConnect } = Capacitor.Plugins;
      await GameConnect.unlockAchievement({ achievementID: gcId });
    } catch (e) { console.warn('reportAchievement:', e); }
  },

  async showLeaderboards() {
    if (!window.Capacitor?.isNativePlatform()) return;
    try {
      const { GameConnect } = Capacitor.Plugins;
      await GameConnect.showAllLeaderboards();
    } catch (e) { console.warn('showLeaderboards:', e); }
  },

  async showAchievements() {
    if (!window.Capacitor?.isNativePlatform()) return;
    try {
      const { GameConnect } = Capacitor.Plugins;
      await GameConnect.showAchievements();
    } catch (e) { console.warn('showAchievements:', e); }
  },
};
```

---

## Passo 6 — Os 4 pontos de engate (edições cirúrgicas)

Todas pequenas e não-destrutivas. Localização pelas linhas atuais do
`index.html`.

### 6.1 — Login no Game Center ao iniciar (`GameState.init`, ~linha 2779)
```javascript
// ANTES:
    Achievements.init();SkinManager.init();
// DEPOIS:
    Achievements.init();SkinManager.init();
    GameCenter.init();
```

### 6.2 — Reportar achievement ao desbloquear (`Achievements._unlock`, ~linha 1219)
```javascript
  function _unlock(id){
    if(_unlocked.has(id))return;
    _unlocked.add(id);_save();_notify(id);
    GameCenter.reportAchievement(id);   // ← ADICIONAR esta linha
  }
```
> Um único ponto central — cobre **todos** os achievements automaticamente,
> presentes e futuros, sem espalhar chamadas pelo código.

### 6.3 — Enviar score do Endless (`GameState`, ~linha 2817)
No trecho onde o `cosmo_best` é salvo quando o score melhora:
```javascript
// ANTES:
          if(this.endlessScore>this.endlessBest){this.endlessBest=this.endlessScore;localStorage.setItem('cosmo_best',this.endlessBest);}
// DEPOIS:
          if(this.endlessScore>this.endlessBest){this.endlessBest=this.endlessScore;localStorage.setItem('cosmo_best',this.endlessBest);GameCenter.submitEndless(this.endlessScore);}
```

### 6.4 — Enviar tempo do Speed Run (`onLevelWin`, ~linha 2866)
```javascript
// ANTES:
              const improved=SpeedRun.saveBest();SpeedRun.stop();
// DEPOIS:
              const improved=SpeedRun.saveBest();SpeedRun.stop();
              GameCenter.submitSpeedRun(elapsed);
```

---

## Passo 7 — (Opcional) Botões nativos de Leaderboard/Achievements

O app já tem um modal de achievements próprio. Para expor os painéis nativos
do Game Center (reforça ainda mais o uso do framework), adicione botões que
chamem:
```javascript
GameCenter.showLeaderboards();   // painel nativo de rankings
GameCenter.showAchievements();   // painel nativo de conquistas
```
Ex.: um botão "🎮 Game Center" na tela de título ou dentro do modal About.

---

## Passo 8 — Sincronizar, versionar e subir

```bash
# copiar o index.html atualizado para o www/ e para o iOS
cp index.html www/index.html
npx cap copy ios

# subir o build (bump para 5)
# em ios/App/App.xcodeproj/project.pbxproj: CURRENT_PROJECT_VERSION = 5
```
Depois: Archive no Xcode → Distribute → aguardar processar → selecionar build 5
na versão → responder no Resolution Center mencionando a nova integração
Game Center → reenviar para revisão.

---

## Checklist de validação antes de subir

- [ ] Capability Game Center aparece em Signing & Capabilities
- [ ] `App.entitlements` contém `com.apple.developer.game-center`
- [ ] Leaderboards `endless_highscore` e `speedrun_besttime` criados no ASC
- [ ] Achievements do `ACH_MAP` criados no ASC (mesmos IDs)
- [ ] Testado em device real: overlay "Welcome back" do Game Center aparece no launch
- [ ] Score de Endless e Speed Run aparecem no painel nativo
- [ ] Build number incrementado
- [ ] `index.html` copiado para `www/` e `npx cap copy ios` executado

---

## Por que isso ajuda no 4.3(a) (resumo para o Resolution Center)

Ao reenviar, vale mencionar algo como:

> "This build adds native Game Center integration — two leaderboards
> (Endless and Speed Run) and achievements backed by GameKit, with the
> Game Center capability enabled in the app's entitlements. This ties the
> app to native Apple frameworks and a unique Game Center configuration
> under my developer account, confirming it is an original, independently
> built game and not a repackaged template."
