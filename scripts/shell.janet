(defn shell-quote
  [value]
  (string "'" (string/replace-all "'" "'\\''" (string value)) "'"))

(defn shell-command
  [args]
  (string/join (map shell-quote args) " "))

(defn temp-path
  []
  (let [clock (os/clock :monotonic :tuple)]
    (string "/tmp/blog-script-" (os/getpid) "-" (clock 0) "-" (clock 1))))

(defn command-run
  [args]
  (let [status (os/shell (shell-command args))]
    (when (not= status 0)
      (error (string "Command failed: " (string/join args " "))))
    status))

(defn command-output
  [args]
  (let [out (temp-path)
        status (os/shell (string (shell-command args) " > " (shell-quote out)))]
    (if (not= status 0)
      (do
        (os/shell (string "rm -f " (shell-quote out)))
        (error (string "Command failed: " (string/join args " "))))
      (let [output (slurp out)]
        (os/shell (string "rm -f " (shell-quote out)))
        output))))

(defn file-exists?
  [path]
  (= 0 (os/shell (string "test -e " (shell-quote path)))))

(defn directory?
  [path]
  (= 0 (os/shell (string "test -d " (shell-quote path)))))

(defn last-index-of
  [needle haystack]
  (var found nil)
  (var start 0)
  (while (< start (length haystack))
    (let [idx (string/find needle haystack start)]
      (if idx
        (do
          (set found idx)
          (set start (+ idx 1)))
        (set start (length haystack)))))
  found)

(defn basename
  [path]
  (let [trimmed (string/trimr path "/")
        slash (last-index-of "/" trimmed)]
    (if slash
      (string/slice trimmed (+ slash 1))
      trimmed)))

(defn dirname
  [path]
  (let [trimmed (string/trimr path "/")
        slash (last-index-of "/" trimmed)]
    (cond
      (nil? slash) "."
      (= slash 0) "/"
      (string/slice trimmed 0 slash))))

(defn basename-without-extension
  [path]
  (let [base (basename path)
        dot (last-index-of "." base)]
    (if (and dot (> dot 0))
      (string/slice base 0 dot)
      base)))

(defn join-path
  [& parts]
  (string/replace-all "//" "/" (string/join (filter |(not= $ "") parts) "/")))

(defn write-temp-file
  [content]
  (let [path (temp-path)]
    (spit path content)
    path))

(defn base64-file
  [path]
  (string/replace-all "\n" "" (command-output ["base64" path])))

(defn base64-string
  [value]
  (let [path (write-temp-file value)]
    (let [output (base64-file path)]
      (os/shell (string "rm -f " (shell-quote path)))
      output)))

(defn ok-status?
  [status]
  (and (>= status 200) (< status 300)))

(defn try-err
  "Run thunk in a try block; on error print it to stderr and exit with code 1."
  [thunk]
  (try
    (thunk)
    ([err]
      (eprintf "%s\n" err)
      (os/exit 1))))
