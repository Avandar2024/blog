# Repository Guidelines

## Project Structure & Module Organization

This repository is a Zola static blog. Site configuration lives in `zola.toml`. Markdown content is under `content/`, with posts in `content/posts/` and standalone pages such as `content/about.md` and `content/search.md`. Typst source drafts live in `typ_content/` and are converted into Markdown before building. Tera templates are in `templates/`, Sass styles are in `sass/main.scss`, static files belong in `static/`, deployment docs are in `docs/`, and automation lives in `justfile` plus `scripts/`.

## Build, Test, and Development Commands

- `nix-shell`: enter the development shell with Node.js, Just, Pandoc, rsync, and Zola.
- `just`: list available tasks.
- `just convert`: convert non-empty `typ_content/**/*.typ` sources to Markdown and sync generated files into `content/`.
- `just check`: convert content and run `zola check`.
- `just build`: run `zola build` and write the static site to `public/`.
- `just serve`: convert content and preview locally with Zola.
- `just build-pages`: build for GitHub Pages using `GITHUB_OWNER` and `GITHUB_REPO`; `GITHUB_PAGES_BASE_URL` is only an override.
- `just deploy-github-pages`: build and deploy `public/` through the GitHub API.

`just convert` invokes Pandoc through `scripts/convert-file.js`. Do not rely on generated temporary Markdown inside `typ_content/`; the recipes clean it.

## Coding Style & Naming Conventions

Use TOML front matter delimited by `+++` for content files. Prefer source-first edits in `typ_content/posts/`; generated Markdown in `content/posts/` should come from `just convert` unless the post has no Typst source. JavaScript uses QuickJS modules, two-space indentation, double quotes, and semicolons. Templates use Zola/Tera syntax and should keep presentation logic minimal. Keep Sass centralized in `sass/main.scss` unless the stylesheet is intentionally split later.

## Testing Guidelines

There is no dedicated unit test suite. Before submitting changes, run `just check` and `just build`. For template, style, or search changes, also run `just serve` and inspect affected pages. The search page uses Zola's `search_index.en.js` data with `static/search.js`, including simple Chinese substring matching.

## Commit & Pull Request Guidelines

Use short imperative commit subjects such as `Add search page` or `Fix post list ordering`. Pull requests should describe the change, list validation commands run, link related issues when available, and include screenshots for visible layout or styling changes.

## Deployment Notes

GitHub Pages deployment is documented in `docs/github-pages.md`. Unknown values stay in environment variables: `GITHUB_OWNER`, `GITHUB_REPO`, and `GITHUB_TOKEN`. Run `just install-hooks` to use `.githooks/post-commit`; automatic deploys only run when `GITHUB_AUTO_DEPLOY=1`.

## Agent-Specific Instructions

Do not edit generated output in `public/`. Prefer changing source files in `content/`, `typ_content/`, `templates/`, `sass/`, `static/`, or `scripts/`. If a Typst conversion changes Markdown under `content/`, keep it consistent with the source draft. Do not commit secrets; use local environment variables or ignored `.env` files.
