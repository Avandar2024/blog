import * as std from "std";

export function commandOutput(args) {
  const file = std.popen(shellCommand(args), "r");
  const output = file.readAsString();
  const status = file.close();

  if (status !== 0) {
    throw new Error(`Command failed: ${args.join(" ")}`);
  }

  return output;
}

export function commandRun(args) {
  commandOutput(args);
}

export function isDirectory(path) {
  return std.system(`${shellCommand(["test", "-d", path])} >/dev/null 2>&1`) === 0;
}

export function isOk(status) {
  return status >= 200 && status < 300;
}

export function readTextFile(fileName) {
  const content = std.loadFile(fileName);

  if (content === null) {
    throw new Error(`Could not read ${fileName}`);
  }

  return content;
}

export function writeTextFile(fileName, content) {
  const file = std.open(fileName, "w");

  if (!file) {
    throw new Error(`Could not write ${fileName}`);
  }

  file.puts(content);
  file.close();
}

export function writeTempFile(content) {
  const tempFile = commandOutput(["mktemp"]).trim();
  writeTextFile(tempFile, content);
  return tempFile;
}

export function base64File(fileName) {
  return commandOutput(["base64", fileName]).replace(/\s/g, "");
}

export function base64String(value) {
  const tempFile = writeTempFile(value);

  try {
    return base64File(tempFile);
  } finally {
    commandRun(["rm", "-f", tempFile]);
  }
}

export function shellCommand(args) {
  return args.map(shellQuote).join(" ");
}

export function shellQuote(value) {
  return `'${String(value).replace(/'/g, "'\\''")}'`;
}

export function dirname(fileName) {
  const slash = fileName.lastIndexOf("/");
  if (slash < 0) return ".";
  if (slash === 0) return "/";
  return fileName.slice(0, slash);
}

export function basenameWithoutExtension(fileName) {
  const base = fileName.slice(fileName.lastIndexOf("/") + 1);
  const dot = base.lastIndexOf(".");
  return dot > 0 ? base.slice(0, dot) : base;
}

export function joinPath(...parts) {
  return parts
    .filter((part) => part !== "")
    .join("/")
    .replace(/\/+/g, "/");
}
