function shellQuote(value) {
  return `'${String(value).replaceAll("'", "'\\''")}'`;
}

function shellCommand(args) {
  return args.map(shellQuote).join(" ");
}

function displayArgs(args) {
  const display = [];
  for (const arg of args) {
    if (String(arg).startsWith("Authorization: Bearer ")) {
      display.push("Authorization: Bearer <redacted>");
    } else {
      display.push(arg);
    }
  }
  return display.join(" ");
}

function tempPath() {
  return `/tmp/blog-script-${os.getpid()}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function commandRun(args) {
  const status = os.exec(args, { block: true, usePath: true });
  if (status !== 0) {
    throw new Error(`Command failed: ${displayArgs(args)}`);
  }
  return status;
}

function commandOutput(args) {
  const pipe = std.popen(shellCommand(args), "r");
  const output = pipe.readAsString();
  const status = pipe.close();
  if (status !== 0) {
    throw new Error(`Command failed: ${displayArgs(args)}`);
  }
  return output;
}

function fileExists(path) {
  const [, err] = os.stat(path);
  return err === 0;
}

function directory(path) {
  const [stat, err] = os.stat(path);
  return err === 0 && (stat.mode & os.S_IFMT) === os.S_IFDIR;
}

function basename(path) {
  const trimmed = String(path).replace(/\/+$/, "");
  const slash = trimmed.lastIndexOf("/");
  return slash === -1 ? trimmed : trimmed.slice(slash + 1);
}

function dirname(path) {
  const trimmed = String(path).replace(/\/+$/, "");
  const slash = trimmed.lastIndexOf("/");
  if (slash === -1) return ".";
  if (slash === 0) return "/";
  return trimmed.slice(0, slash);
}

function basenameWithoutExtension(path) {
  const base = basename(path);
  const dot = base.lastIndexOf(".");
  return dot > 0 ? base.slice(0, dot) : base;
}

function joinPath(...parts) {
  return parts.filter((part) => part !== "").join("/").replace(/\/+/g, "/");
}

function normalizeRelativePath(path) {
  let normalized = String(path).replace(/\/+$/, "");
  while (normalized.startsWith("./")) {
    normalized = normalized.slice(2);
  }
  return normalized;
}

function relativePath(base, path) {
  const normalizedBase = normalizeRelativePath(base);
  const normalizedPath = normalizeRelativePath(path);
  const prefix = `${normalizedBase}/`;
  if (!normalizedPath.startsWith(prefix)) {
    throw new Error(`Path ${path} is not under ${base}`);
  }
  return normalizedPath.slice(prefix.length);
}

function ensureParentDir(path) {
  commandRun(["mkdir", "-p", dirname(path)]);
}

function cleanEmptyDirs(dir) {
  commandRun(["find", dir, "-mindepth", "1", "-type", "d", "-empty", "-delete"]);
}

function writeFile(path, content) {
  const file = std.open(path, "w");
  if (file === null) {
    throw new Error(`Could not open ${path} for writing`);
  }
  file.puts(content);
  file.close();
}

function readFile(path) {
  const content = std.loadFile(path);
  if (content === null) {
    throw new Error(`Could not read ${path}`);
  }
  return content;
}

function writeTempFile(content) {
  const path = tempPath();
  writeFile(path, content);
  return path;
}

function removeFile(path) {
  const err = os.remove(path);
  if (err !== 0 && err !== -2) {
    throw new Error(`Could not remove ${path}: ${std.strerror(-err)}`);
  }
}

function base64File(path) {
  return commandOutput(["base64", path]).replaceAll("\n", "");
}

function base64String(value) {
  const path = writeTempFile(value);
  try {
    return base64File(path);
  } finally {
    removeFile(path);
  }
}

function okStatus(status) {
  return status >= 200 && status < 300;
}

function fail(message) {
  std.err.puts(`${message}\n`);
  std.exit(1);
}

function main(thunk) {
  try {
    thunk();
  } catch (error) {
    fail(error && error.message ? error.message : String(error));
  }
}

globalThis.sh = {
  base64File,
  base64String,
  basename,
  basenameWithoutExtension,
  cleanEmptyDirs,
  commandOutput,
  commandRun,
  directory,
  dirname,
  ensureParentDir,
  fail,
  fileExists,
  joinPath,
  main,
  okStatus,
  readFile,
  relativePath,
  removeFile,
  shellQuote,
  tempPath,
  writeFile,
  writeTempFile,
};
