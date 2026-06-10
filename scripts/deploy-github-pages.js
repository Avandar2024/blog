std.loadScript("scripts/shell.js");

const [root] = os.getcwd();
const publicDir = sh.joinPath(root, "public");
const owner = std.getenv("GITHUB_OWNER") || "";
const repo = std.getenv("GITHUB_REPO") || "";
const token = std.getenv("GITHUB_TOKEN") || "";
const branch = std.getenv("GITHUB_PAGES_BRANCH") || "gh-pages";
const apiUrl = (std.getenv("GITHUB_API_URL") || "https://api.github.com").replace(/\/+$/, "");
const cname = std.getenv("GITHUB_PAGES_CNAME") || "";

function requireConfig() {
  for (const name of ["GITHUB_OWNER", "GITHUB_REPO", "GITHUB_TOKEN"]) {
    if ((std.getenv(name) || "") === "") {
      throw new Error(`Set ${name} before deploying.`);
    }
  }
}

function request(method, resource, body) {
  const outputFile = sh.tempPath();
  let bodyFile = null;
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

  if (body !== undefined) {
    bodyFile = sh.writeTempFile(body);
    args.push("--header", "Content-Type: application/json", "--data-binary", `@${bodyFile}`);
  }

  args.push(`${apiUrl}${resource}`);

  try {
    const status = Number(sh.commandOutput(args).trim());
    return { status, body: sh.readFile(outputFile) };
  } finally {
    sh.removeFile(outputFile);
    if (bodyFile !== null) {
      sh.removeFile(bodyFile);
    }
  }
}

function parseJsonResponse(body, context) {
  try {
    return JSON.parse(body);
  } catch (error) {
    throw new Error(`${context} returned invalid JSON: ${body}`);
  }
}

function responseSha(body, context) {
  const parsed = parseJsonResponse(body, context);
  if (!parsed.sha) {
    throw new Error(`${context} did not include sha: ${body}`);
  }
  return parsed.sha;
}

function refSha(body) {
  const parsed = parseJsonResponse(body, "Ref response");
  if (!parsed.object || !parsed.object.sha) {
    throw new Error(`Ref response did not include object sha: ${body}`);
  }
  return parsed.object.sha;
}

function collectFiles(dir) {
  const files = [];
  for (const file of sh.commandOutput(["find", dir, "-type", "f", "-print"]).split("\n")) {
    if (file === "") continue;
    files.push({
      path: file.slice(dir.length + 1),
      contentBase64: sh.base64File(file),
    });
  }
  return files;
}

function getBranchRef() {
  const response = request("GET", `/repos/${owner}/${repo}/git/ref/heads/${branch}`);
  if (response.status === 404) return null;
  if (sh.okStatus(response.status)) return response;
  throw new Error(`Could not read ${branch} ref: HTTP ${response.status} ${response.body}`);
}

function createBlob(contentBase64) {
  const body = JSON.stringify({
    content: contentBase64,
    encoding: "base64",
  });
  const response = request("POST", `/repos/${owner}/${repo}/git/blobs`, body);
  if (!sh.okStatus(response.status)) {
    throw new Error(`Could not create blob: HTTP ${response.status} ${response.body}`);
  }
  return responseSha(response.body, "Create blob response");
}

function createTree(files) {
  const tree = [];
  for (const file of files) {
    tree.push({
      path: file.path,
      mode: "100644",
      type: "blob",
      sha: createBlob(file.contentBase64),
    });
  }

  const response = request("POST", `/repos/${owner}/${repo}/git/trees`, JSON.stringify({ tree }));
  if (!sh.okStatus(response.status)) {
    throw new Error(`Could not create tree: HTTP ${response.status} ${response.body}`);
  }
  return responseSha(response.body, "Create tree response");
}

function currentCommitSha() {
  try {
    return sh.commandOutput(["git", "rev-parse", "HEAD"]).trim();
  } catch (error) {
    return "";
  }
}

function createCommit(treeSha, parentSha) {
  const sourceCommit = currentCommitSha();
  const message =
    std.getenv("GITHUB_PAGES_COMMIT_MESSAGE") ||
    (sourceCommit === "" ? "Deploy site" : `Deploy site from ${sourceCommit.slice(0, 12)}`);
  const payload = {
    message,
    tree: treeSha,
  };
  if (parentSha) {
    payload.parents = [parentSha];
  }

  const response = request("POST", `/repos/${owner}/${repo}/git/commits`, JSON.stringify(payload));
  if (!sh.okStatus(response.status)) {
    throw new Error(`Could not create commit: HTTP ${response.status} ${response.body}`);
  }
  return responseSha(response.body, "Create commit response");
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
  if (!sh.okStatus(response.status)) {
    throw new Error(`Could not create ${branch} ref: HTTP ${response.status} ${response.body}`);
  }
}

function updateRef(commitSha) {
  const response = request(
    "PATCH",
    `/repos/${owner}/${repo}/git/refs/heads/${branch}`,
    JSON.stringify({
      sha: commitSha,
      force: true,
    }),
  );
  if (!sh.okStatus(response.status)) {
    throw new Error(`Could not update ${branch} ref: HTTP ${response.status} ${response.body}`);
  }
}

sh.main(() => {
  requireConfig();
  if (!sh.directory(publicDir)) {
    throw new Error("Missing public/. Run `just build-pages` before deploying.");
  }

  const files = collectFiles(publicDir);
  files.push({ path: ".nojekyll", contentBase64: "" });
  if (cname !== "") {
    files.push({ path: "CNAME", contentBase64: sh.base64String(`${cname}\n`) });
  }

  const currentRef = getBranchRef();
  const parentSha = currentRef ? refSha(currentRef.body) : null;
  const treeSha = createTree(files);
  const commitSha = createCommit(treeSha, parentSha);

  if (currentRef) {
    updateRef(commitSha);
  } else {
    createRef(commitSha);
  }

  std.printf("Deployed %d files to %s/%s:%s at %s.\n", files.length, owner, repo, branch, commitSha);
});
