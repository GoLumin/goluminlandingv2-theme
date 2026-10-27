#!/usr/bin/env python3
"""Launch checks for golumin.io.

Reproduces the defects that are live today so a fix can be verified, and
enforces the redesign's own rules from redesign/HANDOFF.md.

    script/check-site.py https://golumin.io          # the live site
    script/check-site.py http://localhost:3000       # a local dev server
    script/check-site.py --snapshot ~/cms-projects/golumin.io-snapshot-2026-10-26

Exit status is the number of failing checks, so it drops straight into CI.
Fetching goes through curl: Cloudflare fronts the live origin and turns away
urllib's user agent.
"""
import os, re, subprocess, sys
from urllib.parse import urlsplit

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0 Safari/537.36")

# The crawlers the business depends on: GoLumin sells placement in AI answers,
# so blocking these on its own site contradicts the product.
AI_CRAWLERS = ["GPTBot", "ClaudeBot", "anthropic-ai", "Claude-Web",
               "Google-Extended", "PerplexityBot", "OAI-SearchBot"]

BANNED_WORD = re.compile(r'\bfree\b', re.I)
PHONE_OK = "(415) 283-6736"
PHONE_ANY = re.compile(r'\(?\d{3}\)?[ .-]?\d{3}-\d{4}')


class Source:
    """Either a live host or the on-disk snapshot, read the same way."""

    def __init__(self, base=None, snapshot=None):
        self.base, self.snapshot = base, snapshot
        self.host = urlsplit(base).netloc if base else "golumin.io"

    def get(self, path):
        if self.snapshot:
            p = path.split("?")[0].lstrip("/") or "index.html"
            cand = [os.path.join(self.snapshot, "raw", p),
                    os.path.join(self.snapshot, "raw", p, "index.html")]
            for c in cand:
                if os.path.isfile(c):
                    return 200, open(c, "rb").read().decode("utf-8", "replace")
            return 404, ""
        r = subprocess.run(["curl", "-sSL", "--compressed", "--max-time", "30",
                            "-A", UA, "-w", "\n%{http_code}", self.base + path],
                           capture_output=True, text=True)
        out = r.stdout or ""
        code = out[-3:] if out[-3:].isdigit() else "0"
        return int(code), out[:-4]


class Report:
    def __init__(self): self.failed = 0
    def check(self, name, ok, detail=""):
        print("  %s  %s" % ("PASS" if ok else "FAIL", name))
        if not ok:
            self.failed += 1
            for line in (detail or "").splitlines()[:12]:
                print("        " + line)


def sitemap_paths(src):
    _, xml = src.get("/sitemap.xml")
    locs = re.findall(r"<loc>([^<]+)</loc>", xml)
    return locs


def main():
    args = sys.argv[1:]
    if args[:1] == ["--snapshot"]:
        src = Source(snapshot=os.path.expanduser(args[1]))
        label = "snapshot " + args[1]
    elif args:
        src = Source(base=args[0].rstrip("/"))
        label = args[0]
    else:
        print(__doc__); return 2

    print("Checking %s\n" % label)
    r = Report()
    locs = sitemap_paths(src)

    # 1. Every URL the sitemap advertises has to resolve.
    print("Sitemap")
    bad = []
    for loc in locs:
        path = urlsplit(loc).path or "/"
        code, _ = src.get(path)
        if code != 200:
            bad.append("%s %s" % (code, path))
    r.check("all %d sitemap URLs return 200" % len(locs), not bad,
            "\n".join(bad) + ("\n... and %d more" % (len(bad) - 12) if len(bad) > 12 else ""))

    # 2. The sitemap must advertise the public host, not the origin.
    off = sorted({urlsplit(l).netloc for l in locs} - {src.host})
    r.check("sitemap <loc> entries use %s" % src.host, not off,
            "advertises: " + ", ".join(off))

    # 3. Canonical and og:url must name the public host on every page.
    print("\nCanonical URLs")
    wrong = []
    pages = [urlsplit(l).path or "/" for l in locs]
    checked = 0
    for path in pages:
        code, html = src.get(path)
        if code != 200:
            continue
        checked += 1
        for tag, pat in (("canonical", r'<link[^>]+rel="canonical"[^>]+href="([^"]+)"'),
                         ("og:url", r'<meta[^>]+property="og:url"[^>]+content="([^"]+)"')):
            for v in re.findall(pat, html):
                if urlsplit(v).netloc and urlsplit(v).netloc != src.host:
                    wrong.append("%s  %s -> %s" % (path, tag, urlsplit(v).netloc))
    r.check("canonical and og:url name %s on all %d pages" % (src.host, checked), not wrong,
            "\n".join(wrong[:12]) + ("\n... and %d more" % (len(wrong) - 12) if len(wrong) > 12 else ""))

    # 4. robots.txt must not shut out the AI crawlers the product is about.
    print("\nrobots.txt")
    _, robots = src.get("/robots.txt")
    blocked, agent = [], None
    for line in robots.splitlines():
        line = line.split("#")[0].strip()
        if not line: continue
        k, _, v = line.partition(":")
        k, v = k.strip().lower(), v.strip()
        if k == "user-agent":
            agent = v
        elif k == "disallow" and v == "/" and agent in AI_CRAWLERS:
            blocked.append(agent)
    r.check("AI answer crawlers are allowed", not blocked,
            "Disallow: / for " + ", ".join(sorted(set(blocked))))

    # 5. The redesign's own copy rules.
    print("\nRedesign rules")
    freebies, phones = [], set()
    for path in pages:
        code, html = src.get(path)
        if code != 200: continue
        text = re.sub(r"(?s)<(script|style)\b.*?</\1>", " ", html)
        text = re.sub(r"<[^>]+>", " ", text)
        if BANNED_WORD.search(text):
            freebies.append(path)
        phones.update(PHONE_ANY.findall(text))
    r.check("the word \"free\" appears nowhere", not freebies,
            "on: " + ", ".join(freebies[:10]))
    others = sorted(p for p in phones if p != PHONE_OK)
    r.check("the only phone number is %s" % PHONE_OK, not others,
            "also found: " + ", ".join(others[:10]))

    print("\n%d checks failed" % r.failed)
    return r.failed


sys.exit(main())
