std.loadScript("scripts/shell.js");

const owner = std.getenv("GITHUB_OWNER") || "";
const repo = std.getenv("GITHUB_REPO") || "";
const explicitBaseUrl = std.getenv("GITHUB_PAGES_BASE_URL") || "";

function stripTrailingSlash(value) {
  return value.replace(/\/+$/, "");
}

if (explicitBaseUrl !== "") {
  std.puts(`${stripTrailingSlash(explicitBaseUrl)}\n`);
  std.exit(0);
}

if (owner === "") {
  sh.fail("Set GITHUB_OWNER, or set GITHUB_PAGES_BASE_URL explicitly.");
}

if (repo === "") {
  sh.fail("Set GITHUB_REPO, or set GITHUB_PAGES_BASE_URL explicitly.");
}

if (repo.toLowerCase() === `${owner.toLowerCase()}.github.io`) {
  std.puts(`https://${owner}.github.io\n`);
} else {
  std.puts(`https://${owner}.github.io/${repo}\n`);
}
