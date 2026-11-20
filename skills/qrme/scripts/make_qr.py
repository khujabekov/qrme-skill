#!/usr/bin/env python3
"""make_qr.py — turn a link into a QR-code PNG (default 1000x1000 px).

Usage:
    python3 make_qr.py <link> [output.png] [--size N] [--svg]

No third-party Python packages required.
"""

import os
import re
import struct
import sys
import urllib.parse
import urllib.request

API = "https://api.qrserver.com/v1/create-qr-code/"
DEFAULT_SIZE = 1000


def fail(msg, code=1):
    print("ERROR: " + msg, file=sys.stderr)
    sys.exit(code)


def png_dimensions(data):
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or len(data) < 24:
        return None
    if data[12:16] != b"IHDR":
        return None
    return struct.unpack(">II", data[16:24])


def slugify(link):
    text = re.sub(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", "", link)
    text = re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-").lower()
    return (text[:60].rstrip("-") or "qr")


def fetch(url, attempts=2):
    last = None
    for _ in range(attempts):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "qrme-skill/1.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read()
        except Exception as exc:  # network hiccup, retry once
            last = exc
    fail("could not download QR image: %s" % last)


def build_url(link, size, fmt):
    params = {
        "data": link,
        "size": "%dx%d" % (size, size),
        "margin": "32",
        "format": fmt,
        "ecc": "M",
        "color": "0-0-0",
        "bgcolor": "255-255-255",
    }
    return API + "?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote)


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0

    link = None
    out = None
    size = DEFAULT_SIZE
    also_svg = False

    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--svg":
            also_svg = True
        elif a == "--size":
            i += 1
            if i >= len(argv):
                fail("--size needs a number")
            try:
                size = int(argv[i])
            except ValueError:
                fail("--size must be a number")
            if size < 100:
                fail("--size must be at least 100")
        elif a in ("-h", "--help"):
            print(__doc__.strip())
            return 0
        elif link is None:
            link = a
        elif out is None:
            out = a
        else:
            fail("too many arguments")
        i += 1

    if link is None:
        fail("no link given\n" + __doc__.strip())
    if "://" not in link:
        link = "https://" + link

    if out is None:
        out = slugify(link) + ".png"
    if not os.path.splitext(out)[1]:
        out += ".png"

    data = fetch(build_url(link, size, "png"))
    dims = png_dimensions(data)
    if dims is None:
        fail("server did not return a PNG image")
    if dims != (size, size):
        fail("unexpected image size %dx%d (wanted %dx%d)" % (dims[0], dims[1], size, size))

    out = os.path.abspath(out)
    parent = os.path.dirname(out)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(out, "wb") as fh:
        fh.write(data)

    print("OK %s %dx%d" % (out, dims[0], dims[1]))
    print("link: " + link)

    if also_svg:
        svg_path = os.path.splitext(out)[0] + ".svg"
        svg = fetch(build_url(link, size, "svg"))
        if b"<svg" not in svg[:500]:
            fail("server did not return an SVG image")
        with open(svg_path, "wb") as fh:
            fh.write(svg)
        print("OK %s svg" % svg_path)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
