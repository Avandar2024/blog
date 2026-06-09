#!/usr/bin/env janet

(import ./shell :as sh)

(def root (string/trim (sh/command-output ["pwd"])))
(def public-dir (sh/join-path root "public"))
(def owner (os/getenv "GITHUB_OWNER" ""))
(def repo (os/getenv "GITHUB_REPO" ""))
(def token (os/getenv "GITHUB_TOKEN" ""))
(def branch (os/getenv "GITHUB_PAGES_BRANCH" "gh-pages"))
(def api-url (string/trimr (os/getenv "GITHUB_API_URL" "https://api.github.com") "/"))
(def cname (os/getenv "GITHUB_PAGES_CNAME" ""))

(defn require-config
  []
  (each name ["GITHUB_OWNER" "GITHUB_REPO" "GITHUB_TOKEN"]
    (when (= (os/getenv name "") "")
      (error (string "Set " name " before deploying.")))))

(defn json-escape
  [value]
  (-> (string value)
    (string/replace-all "\\" "\\\\")
    (string/replace-all "\"" "\\\"")
    (string/replace-all "\n" "\\n")))

(defn json-string
  [value]
  (string "\"" (json-escape value) "\""))

(defn json-field
  [name value]
  (string (json-string name) ":" (json-string value)))

(defn json-field-raw
  [name value]
  (string (json-string name) ":" value))

(defn json-string-after
  [body key &opt start]
  (let [key-text (json-string key)
        key-pos (string/find key-text body (or start 0))]
    (when (nil? key-pos)
      nil)
    (let [colon (string/find ":" body (+ key-pos (length key-text)))
          first-quote (string/find "\"" body (+ colon 1))
          second-quote (string/find "\"" body (+ first-quote 1))]
      (string/slice body (+ first-quote 1) second-quote))))

(defn response-sha
  [body]
  (or (json-string-after body "sha")
      (error (string "Response did not include sha: " body))))

(defn ref-sha
  [body]
  (let [object-pos (string/find (json-string "object") body)]
    (or (json-string-after body "sha" object-pos)
        (error (string "Ref response did not include object sha: " body)))))

(defn request
  [method resource &opt body]
  (let [output-file (sh/temp-path)
        args @["curl"
               "--silent"
               "--show-error"
               "--output" output-file
               "--write-out" "%{http_code}"
               "--request" method
               "--header" "Accept: application/vnd.github+json"
               "--header" (string "Authorization: Bearer " token)
               "--header" "X-GitHub-Api-Version: 2022-11-28"]
        body-file (when body (sh/write-temp-file body))]
    (when body
      (array/push args "--header")
      (array/push args "Content-Type: application/json")
      (array/push args "--data-binary")
      (array/push args (string "@" body-file)))
    (array/push args (string api-url resource))
    (let [status (scan-number (string/trim (sh/command-output args)))
          response-body (slurp output-file)]
      (os/shell (string "rm -f " (sh/shell-quote output-file)))
      (when body-file
        (os/shell (string "rm -f " (sh/shell-quote body-file))))
      @{:status status :body response-body})))

(defn collect-files
  [dir]
  (let [files @[]]
    (each file (string/split "\n" (sh/command-output ["find" dir "-type" "f" "-print"]))
      (when (not= file "")
        (array/push files @{
          :path (string/slice file (+ (length dir) 1))
          :content-base64 (sh/base64-file file)
        })))
    files))

(defn get-branch-ref
  []
  (let [response (request "GET" (string "/repos/" owner "/" repo "/git/ref/heads/" branch))]
    (cond
      (= (response :status) 404) nil
      (sh/ok-status? (response :status)) response
      (error (string "Could not read " branch " ref: HTTP " (response :status) " " (response :body))))))

(defn create-blob
  [content-base64]
  (let [body (string "{"
                     (json-field "content" content-base64)
                     ","
                     (json-field "encoding" "base64")
                     "}")
        response (request "POST" (string "/repos/" owner "/" repo "/git/blobs") body)]
    (when (not (sh/ok-status? (response :status)))
      (error (string "Could not create blob: HTTP " (response :status) " " (response :body))))
    (response-sha (response :body))))

(defn create-tree
  [files]
  (let [entries @[]]
    (each file files
      (let [sha (create-blob (file :content-base64))]
        (array/push entries
          (string "{"
                  (json-field "path" (file :path)) ","
                  (json-field "mode" "100644") ","
                  (json-field "type" "blob") ","
                  (json-field "sha" sha)
                  "}"))))
    (let [body (string "{" (json-field-raw "tree" (string "[" (string/join entries ",") "]")) "}")
          response (request "POST" (string "/repos/" owner "/" repo "/git/trees") body)]
      (when (not (sh/ok-status? (response :status)))
        (error (string "Could not create tree: HTTP " (response :status) " " (response :body))))
      (response-sha (response :body)))))

(defn current-commit-sha
  []
  (try
    (string/trim (sh/command-output ["git" "rev-parse" "HEAD"]))
    ([err] "")))

(defn create-commit
  [tree-sha parent-sha]
  (let [source-commit (current-commit-sha)
        message (os/getenv
          "GITHUB_PAGES_COMMIT_MESSAGE"
          (if (= source-commit "")
            "Deploy site"
            (string "Deploy site from " (string/slice source-commit 0 12))))
        parent-json (if parent-sha
          (string ",\"parents\":[" (json-string parent-sha) "]")
          "")
        body (string "{"
                     (json-field "message" message) ","
                     (json-field "tree" tree-sha)
                     parent-json
                     "}")
        response (request "POST" (string "/repos/" owner "/" repo "/git/commits") body)]
    (when (not (sh/ok-status? (response :status)))
      (error (string "Could not create commit: HTTP " (response :status) " " (response :body))))
    (response-sha (response :body))))

(defn create-ref
  [commit-sha]
  (let [body (string "{"
                     (json-field "ref" (string "refs/heads/" branch)) ","
                     (json-field "sha" commit-sha)
                     "}")
        response (request "POST" (string "/repos/" owner "/" repo "/git/refs") body)]
    (when (not (sh/ok-status? (response :status)))
      (error (string "Could not create " branch " ref: HTTP " (response :status) " " (response :body))))))

(defn update-ref
  [commit-sha]
  (let [body (string "{"
                     (json-field "sha" commit-sha)
                     ",\"force\":true"
                     "}")
        response (request "PATCH" (string "/repos/" owner "/" repo "/git/refs/heads/" branch) body)]
    (when (not (sh/ok-status? (response :status)))
      (error (string "Could not update " branch " ref: HTTP " (response :status) " " (response :body))))))

(try
  (do
    (require-config)
    (when (not (sh/directory? public-dir))
      (error "Missing public/. Run `just build-pages` before deploying."))
    (let [files (collect-files public-dir)]
      (array/push files @{:path ".nojekyll" :content-base64 ""})
      (when (not= cname "")
        (array/push files @{:path "CNAME" :content-base64 (sh/base64-string (string cname "\n"))}))
      (let [current-ref (get-branch-ref)
            parent-sha (when current-ref (ref-sha (current-ref :body)))
            tree-sha (create-tree files)
            commit-sha (create-commit tree-sha parent-sha)]
        (if current-ref
          (update-ref commit-sha)
          (create-ref commit-sha))
        (printf "Deployed %d files to %s/%s:%s at %s.\n" (length files) owner repo branch commit-sha))))
  ([err]
    (eprintf "%s\n" err)
    (os/exit 1)))
