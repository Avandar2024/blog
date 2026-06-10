std.loadScript("scripts/shell.js");

const [inputFile, newExt, defaultDate, typContentDir, zolaContentDir] = scriptArgs.slice(1);

function usage() {
  sh.fail("Usage: qjs --std scripts/convert-file.js <inputFileOrDir> <newExt> <date> <typContentDir> <zolaContentDir>");
}

function resolveConversion(inputPath, outputExt) {
  if (!sh.fileExists(inputPath)) {
    throw new Error(`Input does not exist: ${inputPath}`);
  }

  if (sh.directory(inputPath)) {
    const mainFile = sh.joinPath(inputPath, "main.typ");
    if (!sh.fileExists(mainFile)) {
      throw new Error(`Typst project directory must contain main.typ: ${inputPath}`);
    }
    return {
      inputFile: mainFile,
      outputFile: sh.joinPath(sh.dirname(inputPath), `${sh.basename(inputPath)}.${outputExt}`),
      title: sh.basename(inputPath),
    };
  }

  const parentDir = sh.dirname(inputPath);
  const mainFile = sh.joinPath(parentDir, "main.typ");
  const inputBase = sh.basename(inputPath);

  if (sh.fileExists(mainFile) && inputBase !== "main.typ") {
    return { skip: true, mainFile };
  }

  if (inputBase === "main.typ") {
    const projectName = sh.basename(parentDir);
    return {
      inputFile: inputPath,
      outputFile: sh.joinPath(sh.dirname(parentDir), `${projectName}.${outputExt}`),
      title: projectName,
    };
  }

  return {
    inputFile: inputPath,
    outputFile: sh.joinPath(parentDir, `${sh.basenameWithoutExtension(inputPath)}.${outputExt}`),
    title: sh.basenameWithoutExtension(inputPath),
  };
}

function normalizePandocMarkdown(markdown) {
  return markdown
    .replace(/\[\[([^\]]+)\]\]\(#([^)]+)\)\{\.ref\}/g, "[($1)](#$2)")
    .replace(/\[\\\[([^\]]+)\\\]\]\(#([^)]+)\)\{\.ref\}/g, "[($1)](#$2)")
    .replaceAll("\\\\\n\\text{s.t. }", "\\\\\\\\[0.65em]\n\\text{s.t. }")
    .replaceAll("\\left\\|", "\\left\\Vert")
    .replaceAll("\\right\\|", "\\right\\Vert")
    .replace(/\$\$([^\n]*?)\$\$ \[\]\{#([^}]+)\}/g, (_, expression, id) => `<span id="${id}"></span>$$${expression} \\tag{${id}}$$`)
    .replace(/(^|\n)\$([^\n$]+)\$ \[\]\{#([^}]+)\}/g, (_, prefix, expression, id) => `${prefix}<span id="${id}"></span>$$${expression} \\tag{${id}}$$`)
    .replace(/\[\]\{#([^}]+)\}/g, '<span id="$1"></span>');
}

function zolaOutputFile(conversion) {
  return sh.joinPath(zolaContentDir, sh.relativePath(typContentDir, conversion.outputFile));
}

function escapeTomlString(value) {
  return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function splitFrontMatter(markdown) {
  if (!markdown.startsWith("+++\n")) return null;
  const end = markdown.indexOf("\n+++", 4);
  if (end === -1) return null;
  const bodyStart = end + "\n+++".length;
  return {
    frontMatter: markdown.slice(4, end),
    body: markdown.slice(bodyStart).replace(/^\n+/, ""),
  };
}

function frontMatterValue(frontMatter, key) {
  const match = frontMatter.match(new RegExp(`(?:^|\\n)\\s*${key}\\s*=\\s*([^\\n]+)`));
  if (!match) return null;
  return match[1].trim();
}

function existingGeneratedPage(conversion) {
  const outputFile = zolaOutputFile(conversion);
  if (!sh.fileExists(outputFile)) return null;

  const parts = splitFrontMatter(sh.readFile(outputFile));
  if (!parts) return null;

  return {
    date: frontMatterValue(parts.frontMatter, "date"),
    updated: frontMatterValue(parts.frontMatter, "updated"),
    body: parts.body,
  };
}

function frontMatter(conversion, existingPage, bodyChanged) {
  const date = existingPage && existingPage.date ? existingPage.date : defaultDate;
  const updated = bodyChanged ? defaultDate : existingPage && existingPage.updated;
  const updatedLine = updated && updated !== date ? `updated = ${updated}\n` : "";
  return `+++\ntitle = "${escapeTomlString(conversion.title)}"\ndate = ${date}\n${updatedLine}generated_from = "${escapeTomlString(conversion.inputFile)}"\n+++\n\n`;
}

function renderBody(conversion) {
  const pandocOutput = sh.commandOutput(["pandoc", conversion.inputFile, "-t", "markdown"]);
  return normalizePandocMarkdown(pandocOutput);
}

function renderMarkdown(conversion, existingPage) {
  const body = renderBody(conversion);
  const bodyChanged = existingPage && existingPage.body !== body;
  return frontMatter(conversion, existingPage, bodyChanged) + body;
}

function writeConversion(conversion) {
  const outputFile = zolaOutputFile(conversion);
  const existingPage = existingGeneratedPage(conversion);
  sh.ensureParentDir(outputFile);
  sh.writeFile(outputFile, renderMarkdown(conversion, existingPage));
  sh.cleanEmptyDirs(zolaContentDir);
}

if (!inputFile || !newExt || !defaultDate || !typContentDir || !zolaContentDir) {
  usage();
}

sh.main(() => {
  const conversion = resolveConversion(inputFile, newExt);
  if (conversion.skip) {
    std.printf("Skipping module %s; converting %s instead.\n", inputFile, conversion.mainFile);
    return;
  }
  std.printf("Processing %s...\n", conversion.inputFile);
  writeConversion(conversion);
});
