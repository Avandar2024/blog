std.loadScript("scripts/shell.js");

const [contentDir] = scriptArgs.slice(1);

function usage() {
  sh.fail("Usage: qjs --std scripts/clean-generated-content.js <contentDir>");
}

function generatedSource(content) {
  const frontMatterEnd = content.indexOf("\n+++", 4);
  if (frontMatterEnd === -1) return null;
  const frontMatter = content.slice(0, frontMatterEnd);
  const match = frontMatter.match(/(?:^|\n)\s*generated_from\s*=\s*"([^"]+)"/);
  return match ? match[1] : null;
}

function cleanFile(file) {
  const source = generatedSource(sh.readFile(file));
  if (source && !sh.fileExists(source)) {
    std.printf("Removing stale generated content %s; missing %s\n", file, source);
    sh.removeFile(file);
  }
}

if (!contentDir) {
  usage();
}

sh.main(() => {
  for (const file of sh.commandOutput(["find", contentDir, "-type", "f", "-name", "*.md", "-print"]).split("\n")) {
    if (file !== "") {
      cleanFile(file);
    }
  }
  sh.cleanEmptyDirs(contentDir);
});
