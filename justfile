# Blog workflow entrypoint.

src_dir := "./typ_content/"
out_dir := "./content/"
src_ext := "typ"
out_ext := "md"
today := `date -I`

# Show available commands.
default:
    @just --list

# Convert all non-empty Typst sources into content Markdown.
convert: clean-typ-md
    @find {{src_dir}} -type f -name "*.{{src_ext}}" ! -size 0 -exec just _convert-file "{}" \;
    @just clean-typ-md

# Convert one Typst source, for example:
# just convert-one typ_content/posts/BFGS及其不跳步推导.typ
# just convert-one typ_content/posts/my-modular-post
convert-one file: clean-typ-md
    @just _convert-file "{{file}}"
    @just clean-typ-md

# Validate the site after regenerating Markdown from Typst sources.
check: convert
    @zola check

# Build the production site into public/.
build: convert
    @zola build

# Build for GitHub Pages. Defaults to https://GITHUB_OWNER.github.io/GITHUB_REPO.
build-pages: convert
    @zola build --base-url "$(qjs --module ./scripts/github-pages-base-url.js)"

# Build and deploy public/ to the GitHub Pages branch through the GitHub API.
deploy-github-pages: build-pages
    @qjs --module ./scripts/deploy-github-pages.js

# Install repository-local Git hooks from .githooks/.
install-hooks:
    @git config core.hooksPath .githooks

# Regenerate content and start the local preview server.
serve: convert
    @zola serve

# Run the full pre-publish validation pipeline.
publish-check: convert
    @zola check
    @zola build

# Remove temporary Markdown files created beside Typst sources.
clean: clean-typ-md

# Remove temporary Markdown files created beside Typst sources.
clean-typ-md:
    @find {{src_dir}} -type f -name "*.{{out_ext}}" -delete

# Create a new Typst post source:
# just new-post "My Post Title"
new-post title:
    @mkdir -p {{src_dir}}posts
    @test ! -e "{{src_dir}}posts/{{title}}.{{src_ext}}" || (echo "Post already exists: {{src_dir}}posts/{{title}}.{{src_ext}}" && exit 1)
    @printf '= {{title}}\n\n' > "{{src_dir}}posts/{{title}}.{{src_ext}}"

[private]
_convert-file file:
    @qjs --module ./scripts/convert-file.js "{{file}}" "{{out_ext}}" "{{today}}" "{{src_dir}}" "{{out_dir}}"
