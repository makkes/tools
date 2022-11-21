import os
import sys
import http.cookiejar
import urllib.request
import urllib.parse
import urllib.error
import json
from string import Template
from datetime import datetime, timezone


def req_all(opener, url):
    try:
        with opener.open(url) as resp:
            topic = json.loads(resp.read())
            res = topic["data"]
            purl = urllib.parse.urlparse(url)
            qs = urllib.parse.parse_qs(purl.query)
            if topic["has_more"]:
                qs["page_token"] = topic["next_page_token"]
                lpurl = list(purl)
                lpurl[4] = urllib.parse.urlencode(qs, doseq=True)
                res = res + req_all(opener, urllib.parse.urlunparse(lpurl))
            return res
    except urllib.error.HTTPError as e:
        print("HTTP error for {}: status {}".format(url, e.code))
        print("{}".format(e.read()))
        sys.exit(1)


topic_no = os.environ["TOPIC"]

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
login_values = {
    "email": os.environ["LISTS_CNCF_IO_USER"],
    "password": os.environ["LISTS_CNCF_IO_PASSWORD"],
}
login_values = urllib.parse.urlencode(login_values).encode("utf-8")
try:
    opener.open("https://lists.cncf.io/api/v1/login", login_values)
except urllib.error.HTTPError as e:
    print("HTTP error: status {}".format(e.code))
    print("{}".format(e.read()))
    sys.exit(1)


topics = req_all(
    opener, f"https://lists.cncf.io/api/v1/gettopic?topic_id={topic_no}&limit=10")
votes = 0
voters = []
toc = [
    "Davanum Srinivas",
    "Erin Boyd",
    "Dave Zolotusky",
    "Zhang, Cathy H",
    "Lei Zhang",
    "Justin Cormack",
    "Ricardo Rocha",
    "Emily Fox",
    "Matt Farina",
    "Richard Hartmann",
    "Katie Gamanji",
]
for topic in topics:
    snippet = topic["snippet"]
    if topic["name"] in toc and ("+1" in snippet):
        votes += 1
        voters.append(topic["name"])
        print("+1 from {}".format(topic["name"]))

with open("toc-voting.html.tmpl") as f:
    tmpl_content = f.read()
lastupdate = datetime.now(timezone.utc).strftime("%a %b %d %Y %X %Z")
tmpl = Template(tmpl_content)
html = tmpl.substitute(yesno="yes" if votes >=
                       8 else "no ({}/{} necessary votes so far)".format(votes, 8),
                       lastupdate=lastupdate,
                       voters="<br/>".join(voters),
                       topic_no=topic_no)
try:
    outdir = os.environ["OUTDIR"]
except KeyError:
    outdir = "."
with open(os.path.join(outdir, "index.html"), "w") as f:
    f.write(html)
