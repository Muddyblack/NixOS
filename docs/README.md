# Showcase site

A static landing page for this NixOS config — single
[`index.html`](index.html), no build step. Screenshots and widget images live
in [`readme/`](readme/) and load locally on the live site.

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

The Open Graph preview image uses a raw GitHub URL and appears after the
changes reach `master`.
