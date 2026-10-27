#!/usr/bin/env python3
"""Checks a rendered page's audit form against FORM-CONTRACT.md.

    script/launch/form-contract.py http://localhost:3000/

The contract freezes action, method, data-form-slug, every field name, every
select option value, the required flags and the honeypot. The wrapper's
classes, labels and layout are free. Exit status is the number of breaks.
"""
import re, subprocess, sys

ACTION = "/api/forms/audit/submissions"
FIELDS = ["audit_type", "name", "email", "company", "website_url",
          "monthly_ad_spend", "message", "_hp", "utm_source", "utm_medium",
          "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid",
          "msclkid", "v", "landing_path", "referrer", "source", "form_path"]
REQUIRED = ["audit_type", "name", "email", "company", "monthly_ad_spend"]
OPTIONS = {
    "audit_type": ["Full system (web + search + ads)", "Website",
                   "Local + AI search", "Ad account"],
    "monthly_ad_spend": ["", "Not running ads yet", "Under $2,000",
                         "$2,000 – $10,000", "$10,000 – $50,000", "$50,000+"],
}

html = subprocess.run(["curl", "-sSL", "--max-time", "30", sys.argv[1]],
                      capture_output=True, text=True).stdout
forms = re.findall(r"<form\b[^>]*data-audit-form.*?</form>", html, re.S)
fails = 0


def check(name, ok, detail=""):
    global fails
    print("  %s  %s" % ("PASS" if ok else "FAIL", name))
    if not ok:
        fails += 1
        if detail:
            print("        " + detail)


print("Checking %s against FORM-CONTRACT.md\n" % sys.argv[1])
check("the page carries at least one audit form", bool(forms))
for f in forms:
    fid = (re.search(r'id="([^"]+)"', f) or [None, "?"])[1]
    print("\nform #%s" % fid)
    tag = re.match(r"<form\b[^>]*>", f).group(0)
    check("action is %s" % ACTION, 'action="%s"' % ACTION in tag)
    check('method="post"', 'method="post"' in tag)
    check('data-form-slug="audit"', 'data-form-slug="audit"' in tag)
    names = re.findall(r'name="([^"]+)"', f)
    missing = [n for n in FIELDS if n not in names]
    extra = [n for n in names if n not in FIELDS]
    check("all %d field names present" % len(FIELDS), not missing, "missing: " + ", ".join(missing))
    check("no field names added", not extra, "extra: " + ", ".join(sorted(set(extra))))
    for n in REQUIRED:
        m = re.search(r"<(input|select)[^>]*name=\"%s\"[^>]*>" % re.escape(n), f)
        check("%s is required" % n, bool(m) and "required" in m.group(0))
    for sel, want in OPTIONS.items():
        blk = re.search(r"<select[^>]*name=\"%s\".*?</select>" % sel, f, re.S)
        got = re.findall(r'<option[^>]*value="([^"]*)"', blk.group(0)) if blk else []
        check("%s option values verbatim" % sel, got == want,
              "got:  %r\n        want: %r" % (got, want))
    hp = re.search(r'<input[^>]*name="_hp"[^>]*>', f)
    wrapper = f[:hp.start()] if hp else ""
    hidden = "visually-hidden" in wrapper[-400:] or "left:-9999px" in wrapper[-400:].replace(" ", "")
    check("honeypot present and visually hidden", bool(hp) and hidden)

print("\n%d contract breaks" % fails)
sys.exit(fails)
