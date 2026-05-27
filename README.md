# slides

Slidev decks, served at <https://slides.cagdas.io>.

Decks live in `decks/` (`decks/<name>/` or `decks/<group>/<name>/`, each with a `slides.md`).
Shared styles in `shared/style.css` are symlinked into each deck at build time.

## Develop

```
make dev <deck>      # live Slidev server, e.g. make dev claude101
```

## Build

```
make build           # builds each deck -> dist/<deck>/ (--base /<deck>/)
                     # + generates dist/index.html (cards from each deck's title/description)
```

Also run by the GitHub workflow.

## Deploy

```
make deploy          # build, then rsync dist/ -> archer:~/web/slides/
```

Served from there by the **Caddy edge** (`~/dotty/common/infra/core/edge`, route `slides.cagdas.io`)
— a `file_server` over the repo-deployed `~/web/slides`. No build/serve step runs on archer; this
repo is the source of truth and pushes its own `dist/`. Override the target with `REMOTE=` / `REMOTE_DIR=`.
