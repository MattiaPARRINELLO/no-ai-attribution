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
- [Installation rapide](#installation-rapide)
- [Installation manuelle](#installation-manuelle)
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
- Bash.
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

# Sans gestionnaire de paquets
pipx install git-filter-repo
```

Sur ce système, `sudo` est remplacé par `pkexec` si tu préfères les boîtes de
dialogue graphiques. Les deux fonctionnent.

## Installation rapide

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
dossier à ton `PATH` pour lancer `git-purge-ai-attribution` directement.

### Variables d'environnement

L'installeur respecte les variables standard :

- `XDG_CONFIG_HOME` pour la configuration (défaut `~/.config`) ;
- `XDG_BIN_HOME` pour les binaires utilisateur (défaut `~/.local/bin`).

Exemple :

```bash
XDG_CONFIG_HOME="$HOME/.config" XDG_BIN_HOME="$HOME/.local/bin" ./install.sh
```

## Installation manuelle

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

### Installer pour un seul dépôt

Sans configuration globale, copie le hook dans le dépôt :

```bash
cp hooks/commit-msg hooks/ai-agents.regex .git/hooks/
chmod +x .git/hooks/commit-msg
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

Crée un commit de test dans n'importe quel dépôt :

```bash
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

```bash
cd /chemin/vers/ton-depot
git status
```

L'arbre doit être propre. Commite ou stash tes modifications avant.

### 2. Faire un dry run

```bash
git-purge-ai-attribution --dry-run
```

Tu vois le nombre de trailers trouvés et les lignes concernées. Rien n'est modifié.

### 3. Lancer la réécriture

```bash
git-purge-ai-attribution
```

L'outil demande confirmation, crée une sauvegarde miroir
`<dépôt>.git-backup-<date>` puis réécrit l'historique.

Pour ne pas être interrompu :

```bash
git-purge-ai-attribution --yes
```

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

Tu peux aussi garder le remote automatiquement :

```bash
git-purge-ai-attribution --keep-remote
```

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

Exemple de liste :

```text
claude|anthropic|openai|chatgpt|codex|copilot|gemini|cursor|aider|windsurf|opencode|mimocode|qwen|deepseek|mistral|grok|cline
```

Pour ajouter un outil, ajoute son nom séparé par `|`. Échappe les points avec
`\.` si tu écris un domaine. Exemple :

```text
claude|anthropic|mon-outil|mon-outil\.ai
```

Puis teste :

```bash
printf 'sujet\n\nCo-Authored-By: Mon Outil <bot@mon-outil.ai>\n' > /tmp/msg
~/.config/git/hooks/commit-msg /tmp/msg
cat /tmp/msg
```

Le fichier doit être vide de trailer.

### Changer la liste pour un seul dépôt

Si le hook est installé par dépôt, modifie simplement
`.git/hooks/ai-agents.regex` dans ce dépôt.

## Désinstaller

```bash
rm -f ~/.config/git/hooks/commit-msg
rm -f ~/.config/git/hooks/ai-agents.regex
rm -f ~/.local/bin/git-purge-ai-attribution
git config --global --unset core.hooksPath
```

Si tu utilises `core.hooksPath` pour autre chose, ne le supprime pas : retire
seulement les fichiers de ce dépôt.

Si tu avais un fichier `.bak-<date>`, restaure-le :

```bash
mv ~/.config/git/hooks/commit-msg.bak-20261120-143000 ~/.config/git/hooks/commit-msg
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

Ou ajoute ce dossier à ton `PATH` dans `~/.bashrc` ou `~/.zshrc` :

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### `git-filter-repo is required`

Installe-le (voir [Prérequis](#prérequis)). Vérifie ensuite :

```bash
git filter-repo --version
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
