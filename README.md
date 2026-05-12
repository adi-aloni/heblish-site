# heblish-site

Source for **heblish.adialoni.com** — the marketing/download page for the
Heblish macOS app.

```
heblish-site/
├── index.html              landing page
├── styles.css              all styles, dark + light auto via prefers-color-scheme
├── appcast.xml             Sparkle update feed (stub until first release)
├── make_assets.swift       regenerates the PNGs in assets/ when the icon changes
├── assets/                 icons + OG share image (generated, but committed)
└── downloads/              (created after first release) hosts Heblish-*.dmg
```

## How to deploy this site (one-time)

### 1. Create a GitHub repo for the site

```
gh repo create adialoni/heblish-site --public --source . --remote origin --push
```

(or via github.com → New repo → push from this folder)

### 2. Connect Cloudflare Pages

1. Sign in at https://dash.cloudflare.com — sign up for free if needed.
2. Cloudflare Pages → **Create a project** → **Connect to Git** → authorise the
   GitHub app → pick `adialoni/heblish-site`.
3. Build settings: leave **build command** blank, **output directory** blank
   (this is a pure static site, no build step). Click **Save and Deploy**.
4. Wait ~30 seconds. Cloudflare will give you a preview URL like
   `heblish-site.pages.dev`. Visit it — the page should render with assets.

### 3. Point heblish.adialoni.com at it (DNS at GoDaddy)

In Cloudflare Pages → your project → **Custom domains** → **Set up a custom
domain** → enter `heblish.adialoni.com`. Cloudflare will show you a CNAME
target like `heblish-site.pages.dev`.

Now in GoDaddy:

1. Sign in → My Products → DNS for `adialoni.com`.
2. **Add** → choose **CNAME**.
3. **Name** (host): `heblish`
4. **Value** (points to): paste the target Cloudflare gave you
   (e.g. `heblish-site.pages.dev`).
5. **TTL**: 1 hour is fine.
6. Save.

Wait 2–10 minutes for DNS to propagate. You can watch with:
```
dig heblish.adialoni.com CNAME +short
```
Once that resolves, go back to Cloudflare Pages → Custom domains. It will
auto-issue a TLS certificate (free, ~1 minute). The page is then live at
**https://heblish.adialoni.com**.

Your `adialoni.com` MX records, the Google Workspace setup, and any other
records on the apex are untouched — we only added a new CNAME on a subdomain.

## How to publish a release

After the Apple Developer Program is active and we've signed + notarized a
build:

1. Drop the notarized DMG into `downloads/Heblish-<version>.dmg`.
2. Run Sparkle's `sign_update` against the DMG; copy the resulting
   `edSignature` and file `length`.
3. Add a new `<item>` to `appcast.xml`:
   ```xml
   <item>
       <title>0.1</title>
       <pubDate>Sun, 12 May 2026 12:00:00 +0000</pubDate>
       <sparkle:version>1</sparkle:version>
       <sparkle:shortVersionString>0.1</sparkle:shortVersionString>
       <description><![CDATA[
           <ul><li>First release.</li></ul>
       ]]></description>
       <enclosure
           url="https://heblish.adialoni.com/downloads/Heblish-0.1.dmg"
           sparkle:edSignature="..."
           length="...."
           type="application/octet-stream" />
       <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
   </item>
   ```
4. Also drop the same DMG at a stable name so the homepage's "Download" button
   keeps working:
   ```
   cp downloads/Heblish-0.1.dmg downloads/Heblish-latest.dmg
   ```
5. `git commit -am "release 0.1"` and `git push`. Cloudflare auto-redeploys
   within ~30 seconds.

## Regenerating images

If the icon ever changes, rerun `swift make_assets.swift` to refresh the PNGs.
The OG image is a 1200×630 share card; the icon variants are 32/64/256/512.
