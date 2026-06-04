# Showcase site

A static landing page for this NixOS config — single self-contained
[`index.html`](index.html), no build step. Screenshots are pulled from
`assets/readme/` on `master` via raw GitHub URLs, so they render on the live
site without duplicating the (large) image files here.

## Hosting on GitHub Pages

**Recommended — GitHub Actions** (already wired up in
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml)):

1. Repo → **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Push to `master`. The workflow publishes `docs/` to
   `https://muddyblack.github.io/NixOS/`.

**Alternative — deploy from branch** (no Actions):

- Settings → Pages → Source: **Deploy from a branch** → `master` / `/docs`.

## Local preview

```sh
python3 -m http.server -d docs 8000   # then open http://localhost:8000
```

Screenshots only appear once the referenced assets exist on `master`; until
then the layout shows with empty image slots.
