#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const [inputFile, newExt, date, contentDir, contentBuildDir] = process.argv.slice(2);

if (!inputFile || !newExt || !date || !contentDir || !contentBuildDir) {
  console.error(
    "Usage: node scripts/convert-file.js <inputFile> <newExt> <date> <contentDir> <contentBuildDir>",
  );
  process.exit(1);
}

console.log(`Processing ${inputFile}...`);

const parentDir = path.dirname(inputFile);
const fileName = path.parse(inputFile).name;
const newFile = path.join(parentDir, `${fileName}.${newExt}`);

const pandocResult = spawnSync("pandoc", [inputFile, "-t", "markdown"], {
  encoding: "utf8",
  stdio: ["ignore", "pipe", "inherit"],
});

if (pandocResult.status !== 0) {
  process.exit(pandocResult.status ?? 1);
}

const frontMatter = `+++\ntitle = \"${fileName}\"\ndate = ${date}\n+++\n\n`;
fs.writeFileSync(newFile, frontMatter + pandocResult.stdout, "utf8");

const rsyncResult = spawnSync(
  "rsync",
  ["-av", "--include=*/", "--include=*.md", "--exclude=*", contentDir, contentBuildDir],
  { stdio: "inherit" },
);

if (rsyncResult.status !== 0) {
  process.exit(rsyncResult.status ?? 1);
}
