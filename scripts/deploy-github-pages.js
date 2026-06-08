#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const root = process.cwd();
const publicDir = path.join(root, "public");
const owner = process.env.GITHUB_OWNER || "";
const repo = process.env.GITHUB_REPO || "";
const token = process.env.GITHUB_TOKEN || "";
const branch = process.env.GITHUB_PAGES_BRANCH || "gh-pages";
const apiUrl = (process.env.GITHUB_API_URL || "https://api.github.com").replace(/\/$/, "");
const cname = process.env.GITHUB_PAGES_CNAME || "";

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

async function main() {
  requireConfig();

  if (!fs.existsSync(publicDir)) {
    throw new Error("Missing public/. Run `just build-pages` before deploying.");
  }

  const files = collectFiles(publicDir);
  files.push({ path: ".nojekyll", content: "" });

  if (cname) {
    files.push({ path: "CNAME", content: `${cname}\n` });
  }

  const currentRef = await getBranchRef();
  const parentSha = currentRef?.object?.sha || null;
  const treeSha = await createTree(files);
  const commitSha = await createCommit(treeSha, parentSha);

  if (currentRef) {
    await updateRef(commitSha);
  } else {
    await createRef(commitSha);
  }

  console.log(`Deployed ${files.length} files to ${owner}/${repo}:${branch} at ${commitSha}.`);
}

function requireConfig() {
  for (const name of ["GITHUB_OWNER", "GITHUB_REPO", "GITHUB_TOKEN"]) {
    if (!process.env[name]) throw new Error(`Set ${name} before deploying.`);
  }
}

function collectFiles(dir) {
  const files = [];

  walk(dir, (file) => {
    const relativePath = path.relative(dir, file).split(path.sep).join("/");
    files.push({
      path: relativePath,
      content: fs.readFileSync(file),
    });
  });

  return files;
}

function walk(dir, visit) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath, visit);
    } else if (entry.isFile()) {
      visit(fullPath);
    }
  }
}

async function getBranchRef() {
  const response = await request(`/repos/${owner}/${repo}/git/ref/heads/${encodeURIComponent(branch)}`);
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Could not read ${branch} ref: HTTP ${response.status} ${await response.text()}`);
  return response.json();
}

async function createTree(files) {
  const tree = [];

  for (const file of files) {
    const blob = await createBlob(file.content);
    tree.push({
      path: file.path,
      mode: "100644",
      type: "blob",
      sha: blob.sha,
    });
  }

  const response = await request(`/repos/${owner}/${repo}/git/trees`, {
    method: "POST",
    body: JSON.stringify({ tree }),
  });

  if (!response.ok) throw new Error(`Could not create tree: HTTP ${response.status} ${await response.text()}`);
  return (await response.json()).sha;
}

async function createBlob(content) {
  const buffer = Buffer.isBuffer(content) ? content : Buffer.from(String(content));
  const response = await request(`/repos/${owner}/${repo}/git/blobs`, {
    method: "POST",
    body: JSON.stringify({
      content: buffer.toString("base64"),
      encoding: "base64",
    }),
  });

  if (!response.ok) throw new Error(`Could not create blob: HTTP ${response.status} ${await response.text()}`);
  return response.json();
}

async function createCommit(treeSha, parentSha) {
  const sourceCommit = currentCommitSha();
  const message =
    process.env.GITHUB_PAGES_COMMIT_MESSAGE ||
    `Deploy site${sourceCommit ? ` from ${sourceCommit.slice(0, 12)}` : ""}`;
  const body = { message, tree: treeSha };

  if (parentSha) {
    body.parents = [parentSha];
  }

  const response = await request(`/repos/${owner}/${repo}/git/commits`, {
    method: "POST",
    body: JSON.stringify(body),
  });

  if (!response.ok) throw new Error(`Could not create commit: HTTP ${response.status} ${await response.text()}`);
  return (await response.json()).sha;
}

async function createRef(commitSha) {
  const response = await request(`/repos/${owner}/${repo}/git/refs`, {
    method: "POST",
    body: JSON.stringify({
      ref: `refs/heads/${branch}`,
      sha: commitSha,
    }),
  });

  if (!response.ok) throw new Error(`Could not create ${branch} ref: HTTP ${response.status} ${await response.text()}`);
}

async function updateRef(commitSha) {
  const response = await request(`/repos/${owner}/${repo}/git/refs/heads/${encodeURIComponent(branch)}`, {
    method: "PATCH",
    body: JSON.stringify({
      sha: commitSha,
      force: true,
    }),
  });

  if (!response.ok) throw new Error(`Could not update ${branch} ref: HTTP ${response.status} ${await response.text()}`);
}

function currentCommitSha() {
  const result = spawnSync("git", ["rev-parse", "HEAD"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  });

  if (result.status !== 0) return "";
  return result.stdout.trim();
}

async function request(resource, options = {}) {
  const headers = {
    Accept: "application/vnd.github+json",
    Authorization: `Bearer ${token}`,
    "X-GitHub-Api-Version": "2022-11-28",
    ...(options.headers || {}),
  };

  if (options.body) headers["Content-Type"] = "application/json";

  return fetch(`${apiUrl}${resource}`, {
    ...options,
    headers,
  });
}
