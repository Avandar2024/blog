#!/usr/bin/env qjs

import * as std from "std";
import {
  basenameWithoutExtension,
  commandOutput,
  commandRun,
  dirname,
  isDirectory,
  joinPath,
  writeTextFile,
} from "./shell.js";

const [inputFile, newExt, date, contentDir, contentBuildDir] = scriptArgs.slice(1);

if (!inputFile || !newExt || !date || !contentDir || !contentBuildDir) {
  console.error(
    "Usage: qjs --module scripts/convert-file.js <inputFileOrDir> <newExt> <date> <contentDir> <contentBuildDir>",
  );
  std.exit(1);
}

try {
  const conversion = resolveConversion(inputFile, newExt);

  if (conversion.skip) {
    console.log(`Skipping module ${inputFile}; converting ${conversion.mainFile} instead.`);
    std.exit(0);
  }

  console.log(`Processing ${conversion.inputFile}...`);

  const pandocOutput = commandOutput(["pandoc", conversion.inputFile, "-t", "markdown"]);
  const frontMatter = `+++\ntitle = \"${conversion.title}\"\ndate = ${date}\n+++\n\n`;
  const markdown = normalizePandocMarkdown(pandocOutput);

  writeTextFile(conversion.outputFile, frontMatter + markdown);
  commandRun(["rsync", "-av", "--include=*/", "--include=*.md", "--exclude=*", contentDir, contentBuildDir]);
} catch (error) {
  console.error(error.message);
  std.exit(1);
}

function resolveConversion(inputPath, outputExt) {
  if (!fileExists(inputPath)) {
    throw new Error(`Input does not exist: ${inputPath}`);
  }

  if (isDirectory(inputPath)) {
    const mainFile = joinPath(inputPath, "main.typ");

    if (!fileExists(mainFile)) {
      throw new Error(`Typst project directory must contain main.typ: ${inputPath}`);
    }

    return {
      inputFile: mainFile,
      outputFile: joinPath(dirname(inputPath), `${basename(inputPath)}.${outputExt}`),
      title: basename(inputPath),
    };
  }

  const parentDir = dirname(inputPath);
  const mainFile = joinPath(parentDir, "main.typ");

  if (fileExists(mainFile) && basename(inputPath) !== "main.typ") {
    return { skip: true, mainFile };
  }

  if (basename(inputPath) === "main.typ") {
    const projectName = basename(parentDir);

    return {
      inputFile: inputPath,
      outputFile: joinPath(dirname(parentDir), `${projectName}.${outputExt}`),
      title: projectName,
    };
  }

  return {
    inputFile: inputPath,
    outputFile: joinPath(parentDir, `${basenameWithoutExtension(inputPath)}.${outputExt}`),
    title: basenameWithoutExtension(inputPath),
  };
}

function fileExists(fileName) {
  try {
    commandRun(["test", "-e", fileName]);
    return true;
  } catch {
    return false;
  }
}

function basename(fileName) {
  return fileName.replace(/\/+$/, "").slice(fileName.replace(/\/+$/, "").lastIndexOf("/") + 1);
}

function normalizePandocMarkdown(markdown) {
  return markdown
    .replace(/\[\\\[([^\]]+)\\\]\]\(#([^)]+)\)\{\.ref\}/g, "[($1)](#$2)")
    .replace(/^\$\$([^\n]*?)\$\$[ \t]+\[\]\{#([A-Za-z][\w:.-]*)\}/gm, "<span id=\"$2\"></span>$$$$$1 \\tag{$2}$$$$")
    .replace(/\\\\\n(\\text\{s\.t\. \})/g, (_match, nextLine) => `\\\\\\\\[0.65em]\n${nextLine}`)
    .replace(/\[\]\{#([A-Za-z][\w:.-]*)\}/g, "<span id=\"$1\"></span>");
}
