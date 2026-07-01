#!/usr/bin/env python3
"""Smart nix-prefetch-url: normalizes any link to a raw/direct URL and prefetches it."""
import os
import re
import subprocess
import sys
import urllib.parse

import requests

NIX_PREFETCH_URL = os.environ["NIX_PREFETCH_URL"]

# (pattern, replacement) - forge blob -> raw links. Add a forge = add a row.
BLOB_TO_RAW = [
    (r"^https://github\.com/(.+)/blob/(.+)$", r"https://raw.githubusercontent.com/\1/\2"),
    (r"(.+)/-/blob/(.+)$", r"\1/-/raw/\2"),  # GitLab
    (r"(.+)/src/(branch|commit|tag)/(.+)$", r"\1/raw/\2/\3"),  # Gitea/Forgejo/Codeberg
]

# (pattern, replacement) - GitHub refs that only exist as downloadable archives.
GITHUB_ARCHIVE = [
    (r"^(https://github\.com/[^/]+/[^/]+)/commit/(.+)$", r"\1/archive/\2.tar.gz"),
    (r"^(https://github\.com/[^/]+/[^/]+)/releases/tag/(.+)$", r"\1/archive/refs/tags/\2.tar.gz"),
    (r"^(https://github\.com/[^/]+/[^/]+)/tree/(.+)$", r"\1/archive/refs/heads/\2.tar.gz"),
]

OG_META_RE = re.compile(
    r'<meta[^>]+(?:property|name)=["\'](?:og:image|og:video(?::url)?|twitter:image|twitter:player:stream)["\'][^>]+content=["\']([^"\']+)["\']',
    re.IGNORECASE,
)

MEDIA_EXTENSIONS = (
    ".gif", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".mp4", ".webm",
    ".zip", ".tar.gz", ".tgz", ".mp3", ".flac", ".pdf",
)


def first_match(patterns, url):
    for pattern, replacement in patterns:
        new_url, count = re.subn(pattern, replacement, url)
        if count:
            return new_url
    return None


def resolve_page_media(url):
    """If url looks like an HTML page (reddit/pinterest/article/...), pull og:image et al."""
    if url.lower().endswith(MEDIA_EXTENSIONS):
        return url
    try:
        resp = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})
        resp.raise_for_status()
    except requests.RequestException:
        return url
    if "text/html" not in resp.headers.get("Content-Type", ""):
        return url
    match = OG_META_RE.search(resp.text)
    if match:
        print("🖼️  Resolved page to media via Open Graph tags")
        return urllib.parse.urljoin(url, match.group(1))
    return url


def safe_store_name(name):
    return re.sub(r"[^A-Za-z0-9+._?=-]", "_", name)


def main():
    url = sys.argv[1] if len(sys.argv) > 1 else input("🔗 Enter URL: ").strip()
    if not url:
        print("❌ No URL provided.")
        return 1

    unpack = False

    archive_url = first_match(GITHUB_ARCHIVE, url)
    if archive_url:
        url = archive_url
        unpack = True
        print("📦 Detected Github ref -> downloading archive")
    else:
        raw_url = first_match(BLOB_TO_RAW, url)
        if raw_url:
            url = raw_url
            print("🔄 Converted blob link to raw")
        else:
            url = resolve_page_media(url)

    prefetch_args = [NIX_PREFETCH_URL]
    if unpack:
        prefetch_args.append("--unpack")
    else:
        filename = os.path.basename(urllib.parse.urlparse(url).path)
        decoded_name = urllib.parse.unquote(filename)
        if filename and filename != decoded_name:
            prefetch_args += ["--name", safe_store_name(decoded_name)]
            print(f"✨ Decoded filename: '{decoded_name}'")

    print(f"🔗 Raw URL: {url}")
    prefetch_args.append(url)

    result = subprocess.run(prefetch_args, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        return 1

    print(f"🔑 SHA256: {result.stdout.strip()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
