# GitHub Pages Deployment

This project can deploy the generated `public/` directory to a GitHub Pages branch through the GitHub API.

## Required Values

Copy `.env.github.example` to your local environment file or export the values in your shell:

```sh
export GITHUB_OWNER=""
export GITHUB_REPO=""
export GITHUB_TOKEN=""
```

Use a fine-grained GitHub token with repository `Contents: Read and write`.

The Pages base URL is inferred automatically:

- `https://OWNER.github.io` when `GITHUB_REPO` is `OWNER.github.io`
- `https://OWNER.github.io/REPO` otherwise

Set `GITHUB_PAGES_BASE_URL` only when you need an override, for example a custom domain:

```text
https://example.com
```

## Manual Deployment

```sh
nix-shell --run 'just deploy-github-pages'
```

This infers the correct GitHub Pages base URL, runs `zola build --base-url ...`, and pushes the generated files to `GITHUB_PAGES_BRANCH`, defaulting to `gh-pages`.

## Automatic Deployment On Push

Install the repository-local hook once:

```sh
nix-shell --run 'just install-hooks'
```

Enable automatic deployment in your shell:

```sh
export GITHUB_AUTO_DEPLOY=1
```

When `git push` runs, `.githooks/pre-push` runs `just deploy-github-pages`.

Git does not provide a local `post-push` hook. The `pre-push` hook runs during `git push` before refs are sent to the remote.

## GitHub Pages Setting

In GitHub repository settings, configure Pages to serve from the branch named by `GITHUB_PAGES_BRANCH`, default `gh-pages`.
