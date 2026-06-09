#!/usr/bin/env qjs

import * as std from "std";
import {
  basenameWithoutExtension,
  commandOutput,
  commandRun,
  dirname,
  joinPath,
  writeTextFile,
} from "./shell.js";

const [inputFile, newExt, date, contentDir, contentBuildDir] = scriptArgs.slice(1);

if (!inputFile || !newExt || !date || !contentDir || !contentBuildDir) {
  console.error(
    "Usage: qjs --module scripts/convert-file.js <inputFile> <newExt> <date> <contentDir> <contentBuildDir>",
  );
  std.exit(1);
}

console.log(`Processing ${inputFile}...`);

try {
  const parentDir = dirname(inputFile);
  const fileName = basenameWithoutExtension(inputFile);
  const newFile = joinPath(parentDir, `${fileName}.${newExt}`);
  const pandocOutput = commandOutput(["pandoc", inputFile, "-t", "markdown"]);

  writeTextFile(newFile, `+++\ntitle = \"${fileName}\"\ndate = ${date}\n+++\n\n${pandocOutput}`);
  commandRun(["rsync", "-av", "--include=*/", "--include=*.md", "--exclude=*", contentDir, contentBuildDir]);
} catch (error) {
  console.error(error.message);
  std.exit(1);
}
