# qrme — link → 1000px QR code

OpenCode skill that turns any link into a **1000×1000 px** QR-code PNG, ready for
print or screen. Ask the agent in plain language (Uzbek or English) and it calls
the bundled script.

```bash
python3 skills/qrme/scripts/make_qr.py "https://forms.gle/pZUfvcYkPQbsXu8R8"
# OK /path/to/forms-gle-pzufvcykpqbsxu8r8.png 1000x1000
```

## Requirements

| Need       | Details                                                        |
| ---------- | -------------------------------------------------------------- |
| Python     | 3.6+ — standard library only, no `pip install`                  |
| Network    | downloads the image from `https://api.qrserver.com/v1/create-qr-code/` |
| OpenCode   | any recent V1/V2 install (skills dir is the same)              |

No API key, no secrets, no local QR library required.

## Install

### Linux / macOS

```bash
git clone <this-repo-url> qrme-skill
cd qrme-skill
./install.sh              # → ~/.config/opencode/skills/qrme
```

Options:

```bash
./install.sh --project    # install into ./.opencode/skills (this project only)
./install.sh --force      # overwrite an existing qrme skill
```

### Windows (PowerShell)

```powershell
git clone <this-repo-url> qrme-skill
cd qrme-skill
.\install.ps1             # → %USERPROFILE%\.config\opencode\skills\qrme
```

Options: `-Project`, `-Force`.

### Without git

Copy the `skills/qrme` folder to `~/.config/opencode/skills/qrme` manually —
that is the whole skill.

## Usage

In OpenCode:

```
@qrme https://example.com/registration
```

or just ask: *"shu linkni qr qilib ber: https://example.com"*.

Directly from a shell:

```bash
python3 ~/.config/opencode/skills/qrme/scripts/make_qr.py <link> [out.png] [--size N] [--svg]
```

| Argument      | Meaning                                                            |
| ------------- | ------------------------------------------------------------------ |
| `link`        | URL to encode. A missing scheme gets `https://` added.             |
| `out.png`     | Output path. Default: slug of the link in the current directory.   |
| `--size N`    | Pixel size, default `1000`. Minimum `100`.                         |
| `--svg`       | Also write a vector `.svg` next to the PNG.                        |

The PNG uses `ecc=M`, a 4-module margin and pure black on white — reliable on
phone cameras and in print.

## Layout

```text
qrme-skill/
├── install.sh
├── install.ps1
├── skills/qrme/
│   ├── SKILL.md
│   └── scripts/make_qr.py
├── LICENSE
└── README.md
```

## Troubleshooting

| Symptom                         | Fix                                                        |
| ------------------------------- | ---------------------------------------------------------- |
| `python3: command not found`    | install Python 3, or run `PYTHON=python ./install.sh`      |
| `could not download QR image`   | no/blocked network — check access to `api.qrserver.com`    |
| skill not listed in OpenCode    | confirm path `~/.config/opencode/skills/qrme/SKILL.md` exists, then `/reload` |
| wrong link encoded              | the script never edits the link; pass it exactly as given  |

## Uninstall

```bash
rm -rf ~/.config/opencode/skills/qrme          # Linux/macOS
Remove-Item -Recurse "$HOME\.config\opencode\skills\qrme"   # Windows
```

## License

MIT — see [LICENSE](LICENSE).
