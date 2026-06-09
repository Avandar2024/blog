#!/usr/bin/env janet

(def owner (os/getenv "GITHUB_OWNER" ""))
(def repo (os/getenv "GITHUB_REPO" ""))
(def explicit-base-url (os/getenv "GITHUB_PAGES_BASE_URL" ""))

(defn strip-trailing-slash
  [value]
  (string/trimr value "/"))

(defn fail
  [message]
  (eprintf "%s\n" message)
  (os/exit 1))

(when (not= explicit-base-url "")
  (print (strip-trailing-slash explicit-base-url))
  (os/exit 0))

(when (= owner "")
  (fail "Set GITHUB_OWNER, or set GITHUB_PAGES_BASE_URL explicitly."))

(when (= repo "")
  (fail "Set GITHUB_REPO, or set GITHUB_PAGES_BASE_URL explicitly."))

(if (= (string/ascii-lower repo) (string (string/ascii-lower owner) ".github.io"))
  (print (string "https://" owner ".github.io"))
  (print (string "https://" owner ".github.io/" repo)))
