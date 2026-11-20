---
name: qrme
description: Convert a link (usually provided by the user) into a 1000x1000 px QR code PNG image and save it in the working directory. Use when the user gives a URL or short link and asks for a QR code / "qr qilib ber" / "qr-godga aylantir".
---

# qrme — link → 1000px QR

## Workflow

1. Take the link from the user's message. If it has no scheme, prepend `https://`.
2. Run the bundled script:

   ```bash
   python3 scripts/make_qr.py "<link>"
   ```

   Optional arguments:
   - second positional argument = output path (default `<slug>.png` in the current directory)
   - `--svg` = also write a vector `.svg` next to the PNG
   - `--size N` = override the pixel size (default **1000**)

3. Verify the result: the PNG must be exactly the requested size (the script asserts this and prints `OK <path> <WxH>`).
4. Reply in the user's language: give the absolute file path, the encoded link, and the pixel size.

## Notes

- Output is a black-and-white PNG with `ecc=M` and a 4-module margin, which scans reliably in print and on screen.
- The script uses the public endpoint `https://api.qrserver.com/v1/create-qr-code/`, so it needs network access. If the download fails, retry once, then report the error instead of silently producing a file.
- Never shorten or edit the link the user gave — encode it verbatim.
- Filename slug is derived from the link (example: `https://forms.gle/abc` → `forms-gle-abc.png`).
