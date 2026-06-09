#!/usr/bin/env qjs

import * as std from "std";
import {
  base64File,
  base64String,
  commandOutput,
  commandRun,
  isDirectory,
  isOk,
  joinPath,
  readTextFile,
  writeTempFile,
} from "./shell.js";

const root = commandOutput(["pwd"]).trim();
const publicDir = joinPath(root, "public");
const owner = std.getenv("GITHUB_OWNER") || "";
const repo = std.getenv("GITHUB_REPO") || "";
const token = std.getenv("GITHUB_TOKEN") || "";
const branch = std.getenv("GITHUB_PAGES_BRANCH") || "gh-pages";
const apiUrl = (std.getenv("GITHUB_API_URL") || "https://api.github.com").replace(/\/$/, "");
const cname = std.getenv("GITHUB_PAGES_CNAME") || "";

try {
  main();
} catch (error) {
  console.error(error.message);
  std.exit(1);
}

function main() {
  requireConfig();

  if (!isDirectory(publicDir)) {
    throw new Error("Missing public/. Run `just build-pages` before deploying.");
  }

  const files = collectFiles(publicDir);
  files.push({ path: ".nojekyll", contentBase64: "" });

  if (cname) {
    files.push({ path: "CNAME", contentBase64: base64String(`${cname}\n`) });
  }

  const currentRef = getBranchRef();
  const parentSha = currentRef?.object?.sha || null;
  const treeSha = createTree(files);
  const commitSha = createCommit(treeSha, parentSha);

  if (currentRef) {
    updateRef(commitSha);
  } else {
    createRef(commitSha);
  }

  console.log(`Deployed ${files.length} files to ${owner}/${repo}:${branch} at ${commitSha}.`);
}

function requireConfig() {
  for (const name of ["GITHUB_OWNER", "GITHUB_REPO", "GITHUB_TOKEN"]) {
    if (!std.getenv(name)) throw new Error(`Set ${name} before deploying.`);
  }
}

function collectFiles(dir) {
  return commandOutput(["find", dir, "-type", "f", "-print"])
    .split("\n")
    .filter(Boolean)
    .map((file) => ({
      path: file.slice(dir.length + 1),
      contentBase64: base64File(file),
    }));
}

function getBranchRef() {
  const response = request("GET", `/repos/${owner}/${repo}/git/ref/heads/${encodeURIComponent(branch)}`);
  if (response.status === 404) return null;
  if (!isOk(response.status)) throw new Error(`Could not read ${branch} ref: HTTP ${response.status} ${response.body}`);
  return JSON.parse(response.body);
}

function createTree(files) {
  const tree = [];

  for (const file of files) {
    const blob = createBlob(file.contentBase64);
    tree.push({
      path: file.path,
      mode: "100644",
      type: "blob",
      sha: blob.sha,
    });
  }

  const response = request("POST", `/repos/${owner}/${repo}/git/trees`, JSON.stringify({ tree }));

  if (!isOk(response.status)) throw new Error(`Could not create tree: HTTP ${response.status} ${response.body}`);
  return JSON.parse(response.body).sha;
}

function createBlob(contentBase64) {
  const response = request(
    "POST",
    `/repos/${owner}/${repo}/git/blobs`,
    JSON.stringify({
      content: contentBase64,
      encoding: "base64",
    }),
  );

  if (!isOk(response.status)) throw new Error(`Could not create blob: HTTP ${response.status} ${response.body}`);
  return JSON.parse(response.body);
}

function createCommit(treeSha, parentSha) {
  const sourceCommit = currentCommitSha();
  const message =
    std.getenv("GITHUB_PAGES_COMMIT_MESSAGE") ||
    `Deploy site${sourceCommit ? ` from ${sourceCommit.slice(0, 12)}` : ""}`;
  const body = { message, tree: treeSha };

  if (parentSha) {
    body.parents = [parentSha];
  }

  const response = request("POST", `/repos/${owner}/${repo}/git/commits`, JSON.stringify(body));

  if (!isOk(response.status)) throw new Error(`Could not create commit: HTTP ${response.status} ${response.body}`);
  return JSON.parse(response.body).sha;
}

function createRef(commitSha) {
  const response = request(
    "POST",
    `/repos/${owner}/${repo}/git/refs`,
    JSON.stringify({
      ref: `refs/heads/${branch}`,
      sha: commitSha,
    }),
  );

  if (!isOk(response.status)) throw new Error(`Could not create ${branch} ref: HTTP ${response.status} ${response.body}`);
}

function updateRef(commitSha) {
  const response = request(
    "PATCH",
    `/repos/${owner}/${repo}/git/refs/heads/${encodeURIComponent(branch)}`,
    JSON.stringify({
      sha: commitSha,
      force: true,
    }),
  );

  if (!isOk(response.status)) throw new Error(`Could not update ${branch} ref: HTTP ${response.status} ${response.body}`);
}

function currentCommitSha() {
  try {
    return commandOutput(["git", "rev-parse", "HEAD"]).trim();
  } catch {
    return "";
  }
}

function request(method, resource, body = "") {
  const outputFile = commandOutput(["mktemp"]).trim();
  const args = [
    "curl",
    "--silent",
    "--show-error",
    "--output",
    outputFile,
    "--write-out",
    "%{http_code}",
    "--request",
    method,
    "--header",
    "Accept: application/vnd.github+json",
    "--header",
    `Authorization: Bearer ${token}`,
    "--header",
    "X-GitHub-Api-Version: 2022-11-28",
  ];
  let bodyFile = "";

  if (body) {
    bodyFile = writeTempFile(body);
    args.push("--header", "Content-Type: application/json", "--data-binary", `@${bodyFile}`);
  }

  args.push(`${apiUrl}${resource}`);

  try {
    const status = Number(commandOutput(args).trim());
    const responseBody = readTextFile(outputFile);
    return { status, body: responseBody };
  } finally {
    commandRun(["rm", "-f", outputFile]);
    if (bodyFile) commandRun(["rm", "-f", bodyFile]);
  }
}
