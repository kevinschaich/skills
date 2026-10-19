---
name: "google-images"
description: "Find and download 5-10 original full-resolution (4K+, long edge ≥3840px) images from a Google Images search. Use whenever the user wants high-res/4K/wallpaper-quality images from Google for a query."
---

# Google Images 4K downloader

Goal: for ONE search query, deliver 5-10 images whose **original source files** are 4K or larger (long edge ≥ 3840px, e.g. 3840×2160 or 2160×3840). Never deliver Google's thumbnail/preview (`encrypted-tbn*.gstatic.com`, `data:` URIs) — those are ~300px. Always the file the result links to.

## Why a browser is needed
Google redirects plain server-side requests (curl from the cloud container returns 302 to a consent/sorry page). So run the search in a real browser — the built-in browser (`mcp__remote-devices__Claude_Browser__*`), or Claude in Chrome if the user asks — and do the downloading/verification in the cloud shell.

## Steps

1. **Search with a size filter.** Open:
   `https://www.google.com/search?q=<url-encoded query>&tbm=isch&tbs=isz:lt,islt:8mp`
   (`islt:8mp` = larger than 8 MP; 3840×2160 ≈ 8.3 MP. Use `islt:10mp`/`12mp` if too many near-misses slip through.) Adding "4k" or "wallpaper" to the query is fine only if it fits the user's intent.

2. **Extract original URLs + Google's reported dimensions** with the browser's JavaScript tool. The page source embeds originals as `["https://…",height,width]` triples:
   ```js
   const html = document.documentElement.innerHTML;
   const re = /\["(https?:\/\/[^"]+?)",(\d+),(\d+)\]/g; const out=[]; const seen=new Set(); let m;
   while ((m = re.exec(html))) {
     const url = JSON.parse('"'+m[1]+'"'); const h=+m[2], w=+m[3];
     if (/gstatic\.com|google\.com/.test(url) || seen.has(url)) continue;
     seen.add(url); if (Math.max(w,h) >= 3840) out.push({url,w,h});
   }
   JSON.stringify(out.slice(0,40));
   ```
   If this returns nothing (Google changes markup), fall back to clicking results: click a thumbnail, then read the large preview's `src` in the side panel (the `img` whose src is not `encrypted-tbn`/`data:`), plus the "Visit" link. Scroll to load more results when you run short.

3. **Download and verify** in the cloud shell with `scripts/fetch_verify.py` (below). Pass the candidate list as JSON. It downloads each URL with a browser User-Agent and the source page as Referer, opens it with Pillow, and keeps it only if it is a real image with long edge ≥ 3840. Google's reported size is a hint, not proof — sites serve resized copies, HTML error pages, or hotlink blocks, so the actual pixel check is what counts.

4. **Repeat until ≥5 pass.** Discard failures. If fewer than 5 survive, take more candidates from the same results (scroll further, or page 2 via `&start=` / more scrolling), then retry. Stop at 10. If after ~3 rounds you still have <5, tell the user how many you got and why (e.g. the topic rarely has 4K originals) rather than lowering the bar silently.

5. **Deliver.** Copy the keepers to `/mnt/user-data/outputs/<query-slug>/` named `01_<WxH>.<ext>` etc., call SendUserFile on them, and reply with a short table: file, resolution, source domain/URL. Note that images may be copyrighted — the source list lets the user check licensing.

## scripts/fetch_verify.py
Create this in the working directory if not bundled:
```python
import json, sys, os, io, hashlib, urllib.parse, requests
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
cands = json.load(open(sys.argv[1])); outdir = sys.argv[2]; need_max = int(sys.argv[3]) if len(sys.argv)>3 else 10
os.makedirs(outdir, exist_ok=True)
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36'
kept, seen = [], set()
for c in cands:
    if len(kept) >= need_max: break
    u = c['url']
    try:
        ref = '{0.scheme}://{0.netloc}/'.format(urllib.parse.urlparse(u))
        r = requests.get(u, headers={'User-Agent': UA, 'Referer': ref}, timeout=40)
        r.raise_for_status()
        im = Image.open(io.BytesIO(r.content)); w, h = im.size
        digest = hashlib.md5(r.content).hexdigest()
        if max(w, h) < 3840 or digest in seen:
            print('REJECT', w, h, u); continue
        seen.add(digest)
        ext = (im.format or 'jpg').lower().replace('jpeg', 'jpg')
        name = f'{len(kept)+1:02d}_{w}x{h}.{ext}'
        open(os.path.join(outdir, name), 'wb').write(r.content)
        kept.append({'file': name, 'w': w, 'h': h, 'url': u}); print('KEEP', name, u)
    except Exception as e:
        print('FAIL', u, e)
json.dump(kept, open(os.path.join(outdir, 'manifest.json'), 'w'), indent=1)
print(len(kept), 'kept')
```
Run: `python fetch_verify.py candidates.json /mnt/user-data/outputs/<slug> 10` (install `requests pillow` with `--break-system-packages` if missing).

## Notes
- "4K+" means long edge ≥ 3840px. If the user says something stricter (e.g. both sides ≥ 3840×2160), apply that.
- Dedupe by file hash — the same photo often appears on several sites.
- Don't try to bypass paywalls, logins, or stock-site watermarking; skip those results.