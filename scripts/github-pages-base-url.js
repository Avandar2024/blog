#!/usr/bin/env qjs

import * as std from "std";

const owner = std.getenv("GITHUB_OWNER") || "";
const repo = std.getenv("GITHUB_REPO") || "";
const explicitBaseUrl = std.getenv("GITHUB_PAGES_BASE_URL") || "";

if (explicitBaseUrl) {
  console.log(stripTrailingSlash(explicitBaseUrl));
  std.exit(0);
}

if (!owner) {
  fail("Set GITHUB_OWNER, or set GITHUB_PAGES_BASE_URL explicitly.");
}

if (!repo) {
  fail("Set GITHUB_REPO, or set GITHUB_PAGES_BASE_URL explicitly.");
}

if (repo.toLowerCase() === `${owner.toLowerCase()}.github.io`) {
  console.log(`https://${owner}.github.io`);
} else {
  console.log(`https://${owner}.github.io/${repo}`);
}

function stripTrailingSlash(value) {
  return value.replace(/\/$/, "");
}

function fail(message) {
  console.error(message);
  std.exit(1);
}
