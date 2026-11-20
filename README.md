# no-ai-attribution

Un hook Git global et un outil de réécriture d'historique pour retirer les trailers
`Co-Authored-By` qui créditent une IA dans tes commits.

Le hook garde tout le reste : ton message, tes co-auteurs humains, tes trailers
`Signed-off-by`, `Reviewed-by`, etc. Il ne supprime que les lignes qui créditent un
agent ou un modèle d'IA.

```text
feat: ajouter le cache Redis

Co-Authored-By: Claude <noreply@anthropic.com>   <-- supprimé
Co-Authored-By: Jane Doe <jane@example.com>      <-- conservé
```

## Sommaire

- [Pourquoi](#pourquoi)
- [Comment ça marche](#comment-ça-marche)
- [Prérequis](#prérequis)
- [Installation en une ligne](#installation-en-une-ligne)
- [Interface interactive (TUI)](#interface-interactive-tui)
- [Installation sous Linux](#installation-sous-linux)
- [Installation sous macOS](#installation-sous-macos)
- [Installation sous Windows](#installation-sous-windows)
- [Installer pour un seul dépôt](#installer-pour-un-seul-dépôt)
- [Vérifier que ça fonctionne](#vérifier-que-ça-fonctionne)
- [Nettoyer un historique existant](#nettoyer-un-historique-existant)
- [Pousser sur GitHub après réécriture](#pousser-sur-github-après-réécriture)
- [Personnaliser la liste des IA](#personnaliser-la-liste-des-ia)
- [Désinstaller](#désinstaller)
- [Dépannage](#dépannage)
- [Limites](#limites)
- [Licence](#licence)

## Pourquoi

Beaucoup d'assistants de code ajoutent automatiquement un trailer :

```text
Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Copilot <noreply@github.com>
Co-Authored-By: Cursor Agent <agent@cursor.com>
```

GitHub affiche alors deux auteurs sur le commit, l'humain et l'IA. Ce dépôt propose
deux choses complémentaires :

1. **Un hook `commit-msg` global** qui empêche les futurs trailers IA d'entrer dans
   l'historique, dans tous tes dépôts.
2. **Un outil de réécriture** qui retire ceux déjà présents dans un dépôt existant.

## Comment ça marche

### Le hook `commit-msg`

Git exécute `commit-msg` après que tu as écrit ton message et avant de créer le
commit. Le hook reçoit le chemin d'un fichier temporaire qui contient le message.

Le script :

1. lit la liste des motifs d'IA dans `ai-agents.regex` ;
2. cherche les lignes de la forme `Co-Authored-By: ... <...>` qui contiennent un
   de ces motifs, sans tenir compte de la casse ;
3. supprime ces lignes du fichier ;
4. supprime les lignes vides laissées en fin de message ;
5. laisse Git créer le commit normalement.

Un trailer qui ne correspond à aucun motif, par exemple
`Co-Authored-By: Jane Doe <jane@example.com>`, n'est jamais touché.

Le hook ne peut pas échouer volontairement : si le fichier de message est absent,
il sort proprement avec le code 0.

### L'outil `git-purge-ai-attribution`

Le hook ne traite que les nouveaux commits. Pour l'existant, l'outil réécrit
l'historique avec [`git-filter-repo`](https://github.com/newren/git-filter-repo)
et applique la même règle à chaque message de commit, sur toutes les branches et
tous les tags.

L'outil :

1. vérifie que tu es dans un dépôt et que l'arbre de travail est propre ;
2. compte les trailers IA trouvés ;
3. crée un miroir de sauvegarde à côté du dépôt ;
4. réécrit les commits ;
5. vérifie qu'il n'en reste plus ;
6. affiche les commandes pour pousser.

La réécriture change **tous les SHA** du dépôt. C'est normal et c'est la partie à
comprendre avant de lancer quoi que ce soit sur un dépôt partagé.

## Prérequis

- Git 2.30 ou plus récent.
- Bash : natif sous Linux et macOS, fourni avec Git Bash sous Windows.
- `git-filter-repo` uniquement si tu veux nettoyer un historique existant :

```bash
# Debian, Ubuntu, Mint, Pop!_OS
sudo apt install git-filter-repo

# Fedora
sudo dnf install git-filter-repo

# Arch, Manjaro, Garuda
sudo pacman -S git-filter-repo

# macOS
brew install git-filter-repo

# Windows (PowerShell)
pip install --user git-filter-repo

# Sans gestionnaire de paquets, partout
pipx install git-filter-repo
```

Sous Linux, tu peux remplacer `sudo` par `pkexec` si tu préfères une boîte de
dialogue graphique. Les deux fonctionnent.

## Installation en une ligne

Le one-liner télécharge la dernière version du dépôt dans un dossier temporaire et
lance l'installateur. Rien n'est laissé derrière après l'opération.

### Linux et macOS

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash
```

Dans un terminal, cette commande ouvre l'[interface interactive](#interface-interactive-tui).
Sans terminal (script, CI), elle lance l'installation standard.

Installation directe sans menu :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash -s -- --yes
```

Désinstallation :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash -s -- --uninstall
```

### Windows

Dans PowerShell :

```powershell
irm https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.ps1 | iex
```

Le script télécharge l'archive, l'extrait dans le dossier temporaire, lance
`install.ps1`, puis nettoie le dossier temporaire.

### Vérifier avant d'exécuter

Un one-liner exécute du code distant. Si tu préfères lire avant, télécharge le
script et inspecte-le :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh -o get.sh
less get.sh
bash get.sh
```

## Interface interactive (TUI)

`tui.sh` fournit un menu en pur Bash, sans dépendance externe. Il fonctionne sous
Linux, macOS et Git Bash.

```bash
./tui.sh
```

Ou via le one-liner, sans argument :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash
```

Menu :

```text
  1. Installer / mettre à jour
  2. Vérifier l installation
  3. Voir l état
  4. Nettoyer l historique du dépôt courant
  5. Désinstaller
  6. Quitter
```

Navigation : flèches haut et bas, `j` et `k`, ou les chiffres. `Entrée` valide,
`q` quitte.

Chaque action fait ce qu'elle annonce :

- **Installer / mettre à jour** : copie le hook, la liste et l'outil, puis règle
  `core.hooksPath`.
- **Vérifier l installation** : contrôle les fichiers, la configuration, et exécute
  le hook sur un message de test pour confirmer que le trailer IA part et que le
  co-auteur humain reste.
- **Voir l état** : affiche l'OS, Git, les chemins, `core.hooksPath`, la présence de
  `git-filter-repo` et le nombre de trailers IA dans le dépôt courant.
- **Nettoyer l historique** : lance `git-purge-ai-attribution` sur le dépôt courant,
  avec dry run et confirmation intégrés.
- **Désinstaller** : retire les fichiers et désactive `core.hooksPath` s'il pointe
  vers ce dossier.

## Installation sous Linux

### Installation rapide

```bash
git clone https://github.com/MattiaPARRINELLO/no-ai-attribution.git
cd no-ai-attribution
./install.sh
```

Le script installe :

| Fichier | Destination |
| --- | --- |
| `hooks/commit-msg` | `~/.config/git/hooks/commit-msg` |
| `hooks/ai-agents.regex` | `~/.config/git/hooks/ai-agents.regex` |
| `bin/git-purge-ai-attribution` | `~/.local/bin/git-purge-ai-attribution` |

Puis il règle `core.hooksPath` :

```bash
git config --global core.hooksPath ~/.config/git/hooks
```

Un fichier existant qui diffère est sauvegardé en `.bak-<date>` avant d'être
remplacé. Rien n'est écrasé silencieusement.

Si `~/.local/bin` n'est pas dans ton `PATH`, le script te le signale. Ajoute ce
dossier à ton `PATH` pour lancer `git-purge-ai-attribution` directement :

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Installation manuelle

Si tu ne veux pas exécuter de script d'installation :

```bash
mkdir -p ~/.config/git/hooks ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/commit-msg \
  -o ~/.config/git/hooks/commit-msg
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/ai-agents.regex \
  -o ~/.config/git/hooks/ai-agents.regex
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/bin/git-purge-ai-attribution \
  -o ~/.local/bin/git-purge-ai-attribution
chmod +x ~/.config/git/hooks/commit-msg ~/.local/bin/git-purge-ai-attribution
git config --global core.hooksPath ~/.config/git/hooks
```

### Variables d'environnement

L'installeur Linux respecte les variables standard :

- `XDG_CONFIG_HOME` pour la configuration (défaut `~/.config`) ;
- `XDG_BIN_HOME` pour les binaires utilisateur (défaut `~/.local/bin`).

Exemple :

```bash
XDG_CONFIG_HOME="$HOME/.config" XDG_BIN_HOME="$HOME/.local/bin" ./install.sh
```

## Installation sous macOS

Le même `install.sh` fonctionne sous macOS. Il détecte le système et adapte les
messages.

### Prérequis macOS

Git est fourni par les Xcode Command Line Tools. Si `git --version` échoue :

```bash
xcode-select --install
```

Pour `git-filter-repo` :

```bash
brew install git-filter-repo
# ou, sans Homebrew
pipx install git-filter-repo
```

### Installation rapide

```bash
git clone https://github.com/MattiaPARRINELLO/no-ai-attribution.git
cd no-ai-attribution
./install.sh
```

Ou sans cloner :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash
```

### Installation manuelle

```bash
mkdir -p ~/.config/git/hooks ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/commit-msg \
  -o ~/.config/git/hooks/commit-msg
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/ai-agents.regex \
  -o ~/.config/git/hooks/ai-agents.regex
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/bin/git-purge-ai-attribution \
  -o ~/.local/bin/git-purge-ai-attribution
chmod +x ~/.config/git/hooks/commit-msg ~/.local/bin/git-purge-ai-attribution
git config --global core.hooksPath ~/.config/git/hooks
```

### Notes spécifiques à macOS

- **`~/.local/bin` n'est pas dans le `PATH` par défaut.** Sous zsh :

  ```bash
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  ```

- **Bash 3.2 suffit.** macOS livre Bash 3.2 par défaut. L'installeur et la TUI
  restent compatibles, il n'est pas nécessaire d'installer Bash 5 avec Homebrew.

- **Apple Silicon et Intel** : aucune différence, les scripts sont indépendants de
  l'architecture.

- **Gatekeeper** : si macOS refuse d'exécuter un script téléchargé, retire
  l'attribut de quarantaine :

  ```bash
  xattr -d com.apple.quarantine ./install.sh ./tui.sh ./get.sh 2>/dev/null || true
  chmod +x ./install.sh ./tui.sh ./get.sh
  ```

- **Homebrew** : si `brew` n'est pas installé, `pipx install git-filter-repo`
  fonctionne aussi.

## Installation sous Windows

Sous Windows, le hook fonctionne grâce à Git Bash, livré avec Git for Windows.
Il n'y a pas besoin de WSL.

### Installation rapide

Ouvre PowerShell dans le dossier où tu veux cloner le dépôt :

```powershell
git clone https://github.com/MattiaPARRINELLO/no-ai-attribution.git
cd no-ai-attribution
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Si tu utilises PowerShell 7 :

```powershell
pwsh -File .\install.ps1
```

Le script installe les mêmes fichiers que sous Linux, dans ton profil Windows :

| Fichier | Destination |
| --- | --- |
| `hooks\commit-msg` | `C:\Users\<nom>\.config\git\hooks\commit-msg` |
| `hooks\ai-agents.regex` | `C:\Users\<nom>\.config\git\hooks\ai-agents.regex` |
| `bin\git-purge-ai-attribution` | `C:\Users\<nom>\.local\bin\git-purge-ai-attribution` |

Puis il règle `core.hooksPath` avec des slashes, car Git exécute les hooks via
`sh` :

```text
C:/Users/<nom>/.config/git/hooks
```

Un fichier existant qui diffère est sauvegardé en `.bak-<date>`.

### Installation manuelle sous Windows

Dans Git Bash (menu Démarrer, Git Bash), les commandes sont identiques à Linux :

```bash
mkdir -p ~/.config/git/hooks ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/commit-msg \
  -o ~/.config/git/hooks/commit-msg
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/hooks/ai-agents.regex \
  -o ~/.config/git/hooks/ai-agents.regex
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/bin/git-purge-ai-attribution \
  -o ~/.local/bin/git-purge-ai-attribution
chmod +x ~/.config/git/hooks/commit-msg ~/.local/bin/git-purge-ai-attribution
git config --global core.hooksPath ~/.config/git/hooks
```

Dans Git Bash, `~` correspond à `C:\Users\<nom>`.

### Notes spécifiques à Windows

- **Le hook tourne dans Git Bash**, pas dans PowerShell. C'est Git qui l'appelle,
  donc les commits faits depuis PowerShell, VS Code ou GitHub Desktop passent
  aussi par le hook.
- **Utilise des slashes dans `core.hooksPath`.** Un chemin avec des antislashs
  peut empêcher Git de trouver le hook.
- **Le nettoyage d'historique se lance dans Git Bash**, pas dans PowerShell :
  le script de réécriture est un script Bash. Exemple :

  ```bash
  cd /c/Users/<nom>/Documents/mon-projet
  bash ~/.local/bin/git-purge-ai-attribution --dry-run
  ```

- **`git-filter-repo` doit être dans le `PATH` de Git Bash.** Après
  `pip install --user git-filter-repo`, vérifie dans Git Bash :

  ```bash
  git filter-repo --version
  ```

  Si la commande est introuvable, ajoute le dossier Scripts de Python au `PATH`,
  par exemple `~/AppData/Roaming/Python/Python312/Scripts`.

- **Antivirus et execution policy** : si PowerShell refuse d'exécuter
  `install.ps1`, la commande `powershell -ExecutionPolicy Bypass -File .\install.ps1`
  contourne la politique pour cette exécution seulement.

## Installer pour un seul dépôt

Sans configuration globale, copie le hook dans le dépôt.

Linux et Git Bash :

```bash
cp hooks/commit-msg hooks/ai-agents.regex .git/hooks/
chmod +x .git/hooks/commit-msg
```

PowerShell :

```powershell
Copy-Item hooks\commit-msg, hooks\ai-agents.regex .git\hooks\
```

Cette variante ne s'applique qu'à ce dépôt.

### Coexister avec des hooks existants

`core.hooksPath` remplace le dossier de hooks par défaut. Si tu as déjà des hooks
globaux, conserve-les dans le même dossier. Par exemple, si tu avais un
`post-checkout`, laisse-le à côté du nouveau `commit-msg`.

Si tu utilises un gestionnaire de hooks par dépôt (Husky, Lefthook, pre-commit),
vérifie qu'il ne réécrit pas `core.hooksPath`. Dans ce cas, installe plutôt le
hook par dépôt.

## Vérifier que ça fonctionne

Crée un commit de test dans n'importe quel dépôt. Les commandes fonctionnent sous
Linux, macOS, Git Bash et PowerShell :

```bash
git commit --allow-empty -m "test hook" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
git log -1 --format=%B
```

Sous Windows, tu peux aussi utiliser PowerShell :

```powershell
git commit --allow-empty -m "test hook" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
git log -1 --format=%B
```

Résultat attendu :

```text
test hook
```

Pour vérifier que les humains sont conservés :

```bash
git commit --allow-empty -m "test humain" -m "Co-Authored-By: Jane Doe <jane@example.com>"
git log -1 --format=%B
```

Résultat attendu :

```text
test humain

Co-Authored-By: Jane Doe <jane@example.com>
```

Supprime ensuite ces commits de test :

```bash
git reset --hard HEAD~2
```

## Nettoyer un historique existant

> **Lis cette section en entier avant de lancer la commande.**
> La réécriture change tous les SHA et casse les clones existants.

### 1. Se placer dans le dépôt

Sous Linux et macOS :

```bash
cd /chemin/vers/ton-depot
git status
```

Sous Windows, ouvre **Git Bash** et utilise un chemin au format Unix :

```bash
cd /c/Users/<nom>/Documents/mon-projet
git status
```

L'arbre doit être propre. Commite ou stash tes modifications avant.

### 2. Faire un dry run

Sous Linux et macOS :

```bash
git-purge-ai-attribution --dry-run
```

Sous Windows, dans Git Bash :

```bash
bash ~/.local/bin/git-purge-ai-attribution --dry-run
```

Tu vois le nombre de trailers trouvés et les lignes concernées. Rien n'est modifié.

### 3. Lancer la réécriture

Sous Linux et macOS :

```bash
git-purge-ai-attribution
```

Sous Windows, dans Git Bash :

```bash
bash ~/.local/bin/git-purge-ai-attribution
```

L'outil demande confirmation, crée une sauvegarde miroir
`<dépôt>.git-backup-<date>` puis réécrit l'historique.

Pour ne pas être interrompu :

```bash
git-purge-ai-attribution --yes
```

Sous Windows, préfixe toutes ces commandes par
`bash ~/.local/bin/git-purge-ai-attribution`.

### 4. Contrôler le résultat

```bash
git log --all --format='%h %s'
git log --all --format='%B' | grep -i "co-authored-by" || echo "aucun trailer restant"
```

### 5. Restaurer en cas de problème

La sauvegarde est un dépôt miroir complet :

```bash
git clone --mirror mon-depot.git-backup-20261120-143000 mon-depot-restaure.git
```

Tu peux aussi simplement supprimer le dossier réécrit et le recloner depuis la
sauvegarde.

### Ce que fait exactement `git-filter-repo`

L'outil passe un callback Python à `git-filter-repo`. Pour chaque message de
commit, le callback :

```python
pattern = re.compile(rb"^[ \t]*co-authored-by:.*(" + tokens + rb")", re.IGNORECASE)
return b"\n".join(line for line in message.split(b"\n") if not pattern.match(line))
```

Autrement dit : il découpe le message en lignes, supprime celles qui correspondent,
et recolle le reste. Aucun autre contenu n'est modifié.

## Pousser sur GitHub après réécriture

`git-filter-repo` retire le remote `origin` par précaution, pour éviter un
force-push accidentel. Après la réécriture :

```bash
git remote add origin git@github.com:utilisateur/depot.git
git push --force --all
git push --force --tags
```

Sous Windows, Git Bash accepte les mêmes commandes. Si tu utilises HTTPS à la
place de SSH, Git Credential Manager ouvre une fenêtre de connexion au premier
push. Tu peux aussi passer par PowerShell pour ces deux commandes `git push`.

Tu peux aussi garder le remote automatiquement :

```bash
git-purge-ai-attribution --keep-remote
```

Sous Windows : `bash ~/.local/bin/git-purge-ai-attribution --keep-remote`.
Mais le force-push reste à faire à la main.

### Attention aux collaborateurs

Après un force-push, les autres clones divergent. Chaque collaborateur doit soit
recloner, soit faire :

```bash
git fetch --all
git reset --hard origin/<branche>
```

Les pull requests ouvertes peuvent aussi avoir besoin d'être recréées ou
resynchronisées.

### Pull requests déjà mergées

GitHub conserve les commits d'une pull request mergée dans son historique interne.
Réécrire la branche ne change pas l'affichage de l'ancienne PR. Pour un nettoyage
complet côté GitHub, il faut aussi supprimer les références de PR ou recréer le
dépôt, ce qui sort du périmètre de cet outil.

## Personnaliser la liste des IA

La liste est un fichier unique, `ai-agents.regex`, installé à côté du hook. C'est
une expression régulière étendue, une seule ligne, insensible à la casse lors de
l'utilisation.

```bash
cat ~/.config/git/hooks/ai-agents.regex
```

Sous Windows, dans Git Bash :

```bash
cat ~/.config/git/hooks/ai-agents.regex
```

Ou dans PowerShell :

```powershell
Get-Content "$env:USERPROFILE\.config\git\hooks\ai-agents.regex"
```

Exemple de liste :

```text
claude|anthropic|openai|chatgpt|codex|copilot|gemini|cursor|aider|windsurf|opencode|mimocode|qwen|deepseek|mistral|grok|cline
```

Pour ajouter un outil, ajoute son nom séparé par `|`. Échappe les points avec
`\.` si tu écris un domaine. Exemple :

```text
claude|anthropic|mon-outil|mon-outil\.ai
```

Puis teste, sous Linux ou dans Git Bash :

```bash
printf 'sujet\n\nCo-Authored-By: Mon Outil <bot@mon-outil.ai>\n' > /tmp/msg
~/.config/git/hooks/commit-msg /tmp/msg
cat /tmp/msg
```

Sous Windows, Git Bash fournit `printf` et `/tmp`. Si tu préfères PowerShell,
crée le fichier autrement :

```powershell
"sujet`n`nCo-Authored-By: Mon Outil <bot@mon-outil.ai>" |
  Set-Content "$env:TEMP\msg" -NoNewline
bash "$env:USERPROFILE/.config/git/hooks/commit-msg" "$env:TEMP/msg"
Get-Content "$env:TEMP\msg"
```

Le fichier doit être vide de trailer.

### Changer la liste pour un seul dépôt

Si le hook est installé par dépôt, modifie simplement
`.git/hooks/ai-agents.regex` dans ce dépôt.

## Désinstaller

Le plus simple, avec le one-liner :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash -s -- --uninstall
```

Ou depuis la TUI, option 5.

Sous Linux et macOS, ou dans Git Bash :

```bash
rm -f ~/.config/git/hooks/commit-msg
rm -f ~/.config/git/hooks/ai-agents.regex
rm -f ~/.local/bin/git-purge-ai-attribution
git config --global --unset core.hooksPath
```

Sous Windows, dans PowerShell :

```powershell
Remove-Item "$env:USERPROFILE\.config\git\hooks\commit-msg" -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.config\git\hooks\ai-agents.regex" -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.local\bin\git-purge-ai-attribution" -ErrorAction SilentlyContinue
git config --global --unset core.hooksPath
```

Si tu utilises `core.hooksPath` pour autre chose, ne le supprime pas : retire
seulement les fichiers de ce dépôt.

Si tu avais un fichier `.bak-<date>`, restaure-le :

```bash
mv ~/.config/git/hooks/commit-msg.bak-20261120-143000 ~/.config/git/hooks/commit-msg
```

Sous Windows, dans PowerShell :

```powershell
Move-Item "$env:USERPROFILE\.config\git\hooks\commit-msg.bak-20261120-143000" `
  "$env:USERPROFILE\.config\git\hooks\commit-msg"
```

## Dépannage

### Le hook ne se déclenche pas

Vérifie la configuration :

```bash
git config --get core.hooksPath
git config --show-origin --get core.hooksPath
```

Le chemin doit pointer vers le dossier qui contient `commit-msg`. Vérifie aussi que
le fichier est exécutable :

```bash
ls -l ~/.config/git/hooks/commit-msg
chmod +x ~/.config/git/hooks/commit-msg
```

Sous Windows, vérifie la valeur et le contenu du dossier :

```powershell
git config --get core.hooksPath
Get-ChildItem "$env:USERPROFILE\.config\git\hooks"
```

La valeur doit ressembler à `C:/Users/<nom>/.config/git/hooks`, avec des slashes.
Si elle contient des antislashs, corrige-la :

```powershell
$hooks = (Join-Path $env:USERPROFILE ".config\git\hooks") -replace '\\', '/'
git config --global core.hooksPath $hooks
```

### Un trailer IA passe quand même

Le motif ne correspond probablement pas. Le hook cherche une ligne qui commence
par `Co-Authored-By:` et qui contient un motif de la liste. Vérifie la casse, les
espaces et le nom exact :

```bash
printf '%s\n' "$(git log -1 --format=%B)" | grep -i "co-authored"
```

Teste le hook à la main sur un fichier :

```bash
printf 'sujet\n\nCo-Authored-By: Le Nom Exact <mail@exemple.com>\n' > /tmp/msg
~/.config/git/hooks/commit-msg /tmp/msg
cat -A /tmp/msg
```

Ajoute le nom manquant dans `ai-agents.regex`.

### Le hook bloque un commit

Le hook ne doit jamais bloquer un commit. S'il échoue, ton dépôt local a un
problème de permissions ou de `mktemp`. Lance-le à la main pour voir l'erreur :

```bash
~/.config/git/hooks/commit-msg /tmp/msg
```

### `git-purge-ai-attribution: command not found`

`~/.local/bin` n'est pas dans le `PATH`. Lance l'outil par son chemin complet :

```bash
~/.local/bin/git-purge-ai-attribution --help
```

Sous Windows, lance-le depuis Git Bash avec `bash` :

```bash
bash ~/.local/bin/git-purge-ai-attribution --help
```

Ou ajoute ce dossier à ton `PATH` dans `~/.bashrc` ou `~/.zshrc` :

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### `git-filter-repo is required`

Installe-le (voir [Prérequis](#prérequis)). Vérifie ensuite :

```bash
git filter-repo --version
```

Sous Windows, `git-filter-repo` est un paquet Python. Installe-le avec :

```powershell
pip install --user git-filter-repo
```

Puis vérifie dans **Git Bash** :

```bash
git filter-repo --version
```

Si Git Bash ne trouve pas la commande alors que PowerShell la trouve, ajoute le
dossier Scripts de Python au `PATH` de Git Bash, par exemple :

```bash
export PATH="$HOME/AppData/Roaming/Python/Python312/Scripts:$PATH"
```

### `working tree is not clean`

L'outil refuse de réécrire un dépôt avec des modifications non commitées. Fais :

```bash
git status
git stash
git-purge-ai-attribution
git stash pop
```

### Le nettoyage a cassé mes branches

Utilise la sauvegarde créée automatiquement. Elle se trouve à côté du dépôt :

```bash
ls -d ../*.git-backup-*
```

### `fatal: refusing to merge unrelated histories`

Après un force-push, un collaborateur qui a tiré peut voir cette erreur. Il doit
repartir de la version réécrite :

```bash
git fetch origin
git reset --hard origin/main
```

### La TUI ne s'ouvre pas avec le one-liner

La TUI a besoin d'un terminal. Si tu lances la commande depuis un script, une CI
ou un gestionnaire de tâches, elle bascule automatiquement sur l'installation
standard. Pour forcer le menu :

```bash
curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh -o get.sh
bash get.sh
```

### `curl: (22) The requested URL returned error: 404`

Le dépôt ou la branche a changé. Vérifie l'URL, ou force une référence :

```bash
NO_AI_ATTRIBUTION_REF=main \
  curl -fsSL https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.sh | bash
```

### macOS refuse le script ou `brew` est absent

Installe les Xcode Command Line Tools (`xcode-select --install`) et utilise
`pipx install git-filter-repo` au lieu de Homebrew. Pour un script téléchargé :

```bash
xattr -d com.apple.quarantine ./install.sh 2>/dev/null || true
chmod +x ./install.sh
```

## Limites

- **Le hook ne traite que les nouveaux commits.** L'historique existant demande
  `git-purge-ai-attribution`.
- **La réécriture change tous les SHA.** C'est inévitable pour modifier des commits
  passés.
- **Un dépôt partagé doit être coordonné.** Préviens l'équipe avant un force-push.
- **GitHub garde une trace des PR mergées.** Réécrire les branches ne nettoie pas
  l'historique interne des pull requests.
- **Les forks ne sont pas nettoyés.** Chaque fork a son propre historique.
- **Ce n'est pas une garantie de non-détection.** Le but est de retirer une
  attribution automatique, pas de tromper un audit. Si ton employeur ou ta
  plateforme exige de déclarer l'usage de l'IA, continue de le déclarer.

## Licence

MIT, voir [LICENSE](LICENSE).
