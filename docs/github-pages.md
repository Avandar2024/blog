# GitHub Pages Deployment

This project can deploy the generated `public/` directory to a GitHub Pages branch through the GitHub API.

## Required Values

Copy `.env.github.example` to your local environment file or export the values in your shell:

```sh
export GITHUB_OWNER=""
export GITHUB_REPO=""
export GITHUB_TOKEN=""
export GITHUB_PAGES_BASE_URL=""
```

Use a fine-grained GitHub token with write access to repository contents. For a project page, `GITHUB_PAGES_BASE_URL` usually looks like:

```text
https://OWNER.github.io/REPO
```

For a user page, it usually looks like:

```text
https://OWNER.github.io
```

## Manual Deployment

```sh
nix-shell --run 'just deploy-github-pages'
```

This runs `zola build --base-url "$GITHUB_PAGES_BASE_URL"` and pushes the generated files to `GITHUB_PAGES_BRANCH`, defaulting to `gh-pages`.

## Automatic Deployment After Commit

Install the repository-local hook once:

```sh
nix-shell --run 'just install-hooks'
```

Enable automatic deployment in your shell:

```sh
export GITHUB_AUTO_DEPLOY=1
```

After each local `git commit`, `.githooks/post-commit` runs `just deploy-github-pages`.

## GitHub Pages Setting

In GitHub repository settings, configure Pages to serve from the branch named by `GITHUB_PAGES_BRANCH`, default `gh-pages`.
