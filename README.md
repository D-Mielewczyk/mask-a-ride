# mask-a-ride

[![Discord notify on main](https://github.com/D-Mielewczyk/mask-a-ride/actions/workflows/discord-on-merge.yml/badge.svg?branch=main)](https://github.com/D-Mielewczyk/mask-a-ride/actions/workflows/discord-on-merge.yml)

Game about car masks

## Linting

This project uses **gdtoolkit** for GDScript linting.

### CLI

```bash
pip install gdtoolkit
gdlint scripts/ scenes/
gdformat scripts/ scenes/  # Auto-fix
```

### VS Code

1. Install "Godot Tools" extension
2. Install gdtoolkit: `pip install gdtoolkit`
3. Add to `.vscode/settings.json`:

```json
{
  "gdscript.linting.enabled": true,
  "gdscript.linting.onSave": true,
  "[gdscript]": {
    "editor.formatOnSave": true
  }
}
```

### Godot Editor

- Linting warnings appear automatically in script editor
- Check the "Script" panel on the right for issues

### GitHub Actions

Linting runs automatically on push/PR to `main`, `develop`, and `feat/**` branches. Check the **Actions** tab for results.
