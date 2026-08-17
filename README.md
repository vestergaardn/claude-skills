# claude-skills

Personal Claude Code setup, replayed into every Conductor **cloud** workspace.
Local Mac workspaces already read `~/.claude`, so `bootstrap.sh` exits early there.

Contents:

| Path                | What it is                                        |
| ------------------- | ------------------------------------------------- |
| `skills/`           | Personal skills (gstack-owned skills excluded)     |
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

## Environment variables

Conductor has no user-level variable store, and no API to write one. The only
place that spans every repository is the **Cloud Computer environment**
(Conductor → Settings → Cloud Computer). Keep exactly one secret there —
`VERCEL_TOKEN` — and let each project supply the rest:

1. `bootstrap.sh` installs the vercel CLI, which the cloud image lacks.
2. It runs `vercel env pull .env.local` for any workspace holding a
   `.vercel/project.json`, so a repo's own Vercel variables arrive with it.

Per-repo, non-secret values belong in `.conductor/settings.toml`:

```toml
[environment_variables.cloud]
CI = "1"
```

Never put a secret there — that file is committed and shared with the team.

## Updating

Re-run the exporter from the Mac, then commit. Never commit `~/.claude/settings.json`:
it holds real API keys.
