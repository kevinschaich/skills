---
name: "unsplash"
description: Download full-resolution, free-license (non-Unsplash+) photos from Unsplash for a search term via the official API, with photographer credits. Use whenever the user wants stock photos, reference images or wallpapers from Unsplash.
---

# Unsplash download

Search Unsplash with the official API, skip the paid Unsplash+ photos, and save each photo at its original, full upload resolution with a credits file.

## Access key

The script needs your Unsplash Access Key (never the Secret Key). It checks for the key in this order:

1. the `UNSPLASH_ACCESS_KEY` environment variable
2. `~/.config/unsplash/access_key`
3. `~/mnt/Pictures/unsplash/.access_key` (the Pictures folder as the device shell mounts it)
4. `~/Pictures/unsplash/.access_key`

The key is saved at `Pictures/unsplash/.access_key`, so connect the Pictures folder (request access if needed) and run the script with the device shell. If no key is found, ask the user for their Access Key and save it to that file. Unsplash's web pages and the unofficial `/napi` endpoint block scripts, so don't fall back to them.

Unsplash demo apps get 50 requests per hour. Each run uses one request per search page plus one download-tracking request per photo, and the script prints how many requests are left. For big batches, warn the user or suggest they apply for production access.

## Why these choices

- **Free license only:** regular photos are under the Unsplash License, which allows free commercial use. Unsplash+ photos are paid, so the script drops any result flagged `premium` or `plus`, or served from `plus.unsplash.com`.
- **Max resolution:** `urls.raw` with its query string removed returns the original file, often 6000px wide and several MB. The `full` and `regular` URLs are resized.
- **API guidelines:** Unsplash requires a request to `links.download_location` for every download, and the script makes it.
- **Credits:** every run writes `CREDITS.md` and `credits.json`.

## Steps

1. From the request, work out the query, the number of images (default 10) and any filters: `--orientation landscape|portrait|squarish`, `--color`, `--min-width` (for example 4000 for "4K+"), and `--order latest`. Don't stop to ask about details that have sensible defaults.
2. Choose the output folder. The default is `~/mnt/Pictures/unsplash/<query-slug>/`; use another connected folder if the user names one.
3. Write the script below to `$HOME/unsplash_dl.py` in the device shell, outside the user's folders. Then run `python3 $HOME/unsplash_dl.py "<query>" -n <count> -o <out_dir> [filters]` with a long timeout. For more than about 15 images, run it in batches.
4. Report back in one or two lines: how many images were saved, where, their typical resolution, and a note if fewer free matches turned up than were requested.

## Script

```python
#!/usr/bin/env python3
"""Download full-resolution, free-license Unsplash photos for a search via the official API."""
import argparse, json, os, re, sys, time, urllib.parse, urllib.request

API = "https://api.unsplash.com"
KEY_FILES = ["~/.config/unsplash/access_key", "~/mnt/Pictures/unsplash/.access_key", "~/Pictures/unsplash/.access_key"]

def load_key():
    k = os.environ.get("UNSPLASH_ACCESS_KEY")
    if k: return k.strip()
    for p in KEY_FILES:
        p = os.path.expanduser(p)
        if os.path.isfile(p): return open(p).read().strip()
    sys.exit("No Unsplash key: set UNSPLASH_ACCESS_KEY or create one of: " + ", ".join(KEY_FILES))

def get(url, key=None):
    h = {"Accept-Version": "v1"}
    if key: h["Authorization"] = f"Client-ID {key}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=120) as r:
        return r.read(), r.headers

def is_free(p):
    # Unsplash+ photos are paid; skip anything flagged premium/plus or served from plus.unsplash.com
    return not (p.get("premium") or p.get("plus") or "plus.unsplash.com" in p.get("urls", {}).get("raw", ""))

def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:60] or "photo"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("query")
    ap.add_argument("-n", "--count", type=int, default=10)
    ap.add_argument("-o", "--out", default=None)
    ap.add_argument("--orientation", choices=["landscape", "portrait", "squarish"])
    ap.add_argument("--color", help="black_and_white, black, white, yellow, orange, red, purple, magenta, green, teal, blue")
    ap.add_argument("--min-width", type=int, default=0)
    ap.add_argument("--order", choices=["relevant", "latest"], default="relevant")
    a = ap.parse_args()
    key = load_key()

    out = a.out or os.path.join("unsplash", slug(a.query))
    os.makedirs(out, exist_ok=True)
    picked, page, seen, remaining = [], 1, set(), "?"
    while len(picked) < a.count and page <= 10:
        q = {"query": a.query, "per_page": 30, "page": page, "order_by": a.order, "content_filter": "high"}
        if a.orientation: q["orientation"] = a.orientation
        if a.color: q["color"] = a.color
        body, hdr = get(f"{API}/search/photos?" + urllib.parse.urlencode(q), key)
        remaining = hdr.get("X-Ratelimit-Remaining", "?")
        res = json.loads(body).get("results", [])
        if not res: break
        for p in res:
            if p["id"] in seen or not is_free(p) or p.get("width", 0) < a.min_width: continue
            seen.add(p["id"]); picked.append(p)
            if len(picked) >= a.count: break
        page += 1

    credits = []
    for i, p in enumerate(picked, 1):
        # API guidelines: register the download, then fetch the original (raw URL without resize params)
        try: get(p["links"]["download_location"], key)
        except Exception: pass
        raw = p["urls"]["raw"].split("?")[0]
        data, hdr = get(raw)
        ctype = (hdr.get("Content-Type") or "").split(";")[0]
        ext = {"image/png": "png", "image/webp": "webp", "image/avif": "avif"}.get(ctype, "jpg")
        name = f"{i:02d}-{slug(p.get('alt_description') or p.get('description') or p['id'])}-{p['id']}.{ext}"
        with open(os.path.join(out, name), "wb") as f: f.write(data)
        u = p.get("user", {})
        credits.append({"file": name, "id": p["id"], "width": p["width"], "height": p["height"],
                        "bytes": len(data), "photographer": u.get("name"),
                        "profile": u.get("links", {}).get("html"), "page": p.get("links", {}).get("html"),
                        "license": "Unsplash License"})
        print(f"[{i}/{len(picked)}] {name} {p['width']}x{p['height']} {len(data)//1024}KB by {u.get('name')}")

    with open(os.path.join(out, "credits.json"), "w") as f: json.dump(credits, f, indent=2)
    with open(os.path.join(out, "CREDITS.md"), "w") as f:
        f.write(f"# Unsplash: {a.query}\n\n")
        for c in credits:
            f.write(f"- {c['file']} — Photo by [{c['photographer']}]({c['profile']}) on [Unsplash]({c['page']})\n")
    print(f"Saved {len(credits)} images to {out} (API requests left this hour: {remaining})")
    if len(credits) < a.count: print(f"Note: only {len(credits)} free matches found", file=sys.stderr)

if __name__ == "__main__":
    main()
```
