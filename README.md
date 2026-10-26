# claude-skills

My Claude Code skills, published as a plugin marketplace so every machine and devcontainer gets the same version.

| Skill | Run as | What it does |
| --- | --- | --- |
| `review` | `/dev:review` | Code review in numbered rounds, saved as a review document. Asks whether custom code should exist when the platform already provides it. |
| `canonicalize` | `/dev:canonicalize` | Sweeps existing code for hand-written logic a built-in replaces, and fixes 5–10 cases per PR. |
| `pr-description` | `/dev:pr-description` | Writes a PR description from the branch diff. |

## Install

```bash
claude plugin marketplace add gatezh/claude-skills
claude plugin install dev@gatezh
```

Auto-update is off by default for third-party marketplaces. Turn it on in `/plugin` → **Marketplaces** → `gatezh` → **Enable auto-update**, or set `autoUpdate` in settings:

```json
{
  "extraKnownMarketplaces": {
    "gatezh": {
      "source": { "source": "github", "repo": "gatezh/claude-skills" },
      "autoUpdate": true
    }
  }
}
```

On a machine without a GitHub SSH key, set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, or updates fail.

## Editing

The plugin has no `version`, so every commit is a release: installs update when the commit changes.

To edit with live reload, add the marketplace from a local clone instead (`claude plugin marketplace add ~/Code/claude-skills`). Claude Code then reads the files in place, and an edit takes effect at the next session or after `/reload-plugins`.

Check the manifests after editing them:

```bash
claude plugin validate .
```
