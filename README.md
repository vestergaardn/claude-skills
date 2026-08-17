# claude-skills

Personal Claude Code setup, replayed into every Conductor **cloud** workspace.
Local Mac workspaces already read `~/.claude`, so `bootstrap.sh` exits early there.

Contents:

| Path                | What it is                                        |
| ------------------- | ------------------------------------------------- |
| `skills/`           | Personal skills (gstack-owned skills excluded)     |
| `CLAUDE.md`         | Global instructions, copied to `~/.claude/CLAUDE.md` |
| `marketplaces.txt`  | Plugin marketplaces to register                    |
| `plugins.txt`       | Plugins to install at user scope                   |
| `bootstrap.sh`      | The installer the setup script runs                |

## How it is wired

`~/.conductor/settings.toml` runs the bootstrap for every repository:

```toml
[scripts]
setup = "..."   # clone this repo, run bootstrap.sh
```

Conductor merges settings **per key**. A repo that sets its own `scripts.setup`
in `.conductor/settings.toml` or `.conductor/settings.local.toml` replaces the
user-level value. Those repos must call the bootstrap themselves:

```sh
[ "$CONDUCTOR_IS_LOCAL" = "1" ] || { rm -rf ~/.claude-setup \
  && git clone --depth 1 -q https://github.com/vestergaardn/claude-skills.git ~/.claude-setup \
  && bash ~/.claude-setup/bootstrap.sh; }
```

## Updating

Re-run the exporter from the Mac, then commit. Never commit `~/.claude/settings.json`:
it holds real API keys.
