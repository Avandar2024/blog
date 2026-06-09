#!/usr/bin/env janet

(import ./shell :as sh)

(def args (dyn :args))
(def input-file (get args 1))
(def new-ext (get args 2))
(def date (get args 3))
(def content-dir (get args 4))
(def content-build-dir (get args 5))

(defn usage
  []
  (eprintf "Usage: janet scripts/convert-file.janet <inputFileOrDir> <newExt> <date> <contentDir> <contentBuildDir>\n")
  (os/exit 1))

(defn resolve-conversion
  [input-path output-ext]
  (when (not (sh/file-exists? input-path))
    (error (string "Input does not exist: " input-path)))
  (if (sh/directory? input-path)
    (let [main-file (sh/join-path input-path "main.typ")]
      (when (not (sh/file-exists? main-file))
        (error (string "Typst project directory must contain main.typ: " input-path)))
      @{
        :input-file main-file
        :output-file (sh/join-path (sh/dirname input-path) (string (sh/basename input-path) "." output-ext))
        :title (sh/basename input-path)
      })
    (let [parent-dir (sh/dirname input-path)
          main-file (sh/join-path parent-dir "main.typ")
          input-base (sh/basename input-path)]
      (cond
        (and (sh/file-exists? main-file) (not= input-base "main.typ"))
        @{:skip true :main-file main-file}

        (= input-base "main.typ")
        (let [project-name (sh/basename parent-dir)]
          @{
            :input-file input-path
            :output-file (sh/join-path (sh/dirname parent-dir) (string project-name "." output-ext))
            :title project-name
          })

        @{
          :input-file input-path
          :output-file (sh/join-path parent-dir (string (sh/basename-without-extension input-path) "." output-ext))
          :title (sh/basename-without-extension input-path)
        }))))

(def ref-peg
  ~{:main (* "[\\[" (capture (some (if-not "\\" 1))) "\\]](#" (capture (some (if-not ")" 1))) "){.ref}")})

(def math-anchor-peg
  ~{:main (* "$$" (capture (any (if-not "\n" (if-not "$$ []{#" 1)))) "$$ []{#" (capture (some (if-not "}" 1))) "}")})

(def anchor-peg
  ~{:main (* "[]{#" (capture (some (if-not "}" 1))) "}")})

(defn normalize-pandoc-markdown
  [markdown]
  (let [with-refs (peg/replace-all ref-peg
                    (fn [_ label id] (string "[(" label ")](#" id ")"))
                    markdown)
        with-spaced-constraints (string/replace-all
                                  "\\\\\n\\text{s.t. }"
                                  "\\\\\\\\[0.65em]\n\\text{s.t. }"
                                  with-refs)
        with-math-anchors (peg/replace-all math-anchor-peg
                            (fn [_ math id] (string "<span id=\"" id "\"></span>$$" math " \\tag{" id "}$$"))
                            with-spaced-constraints)]
    (peg/replace-all anchor-peg
      (fn [_ id] (string "<span id=\"" id "\"></span>"))
      with-math-anchors)))

(when (or (nil? input-file) (nil? new-ext) (nil? date) (nil? content-dir) (nil? content-build-dir))
  (usage))

(sh/try-err (fn []
  (let [conversion (resolve-conversion input-file new-ext)]
    (if (get conversion :skip)
      (do
        (printf "Skipping module %s; converting %s instead.\n" input-file (get conversion :main-file))
        (os/exit 0))
      (do
        (printf "Processing %s...\n" (get conversion :input-file))
        (let [pandoc-output (sh/command-output ["pandoc" (get conversion :input-file) "-t" "markdown"])
              front-matter (string "+++\ntitle = \"" (get conversion :title) "\"\ndate = " date "\n+++\n\n")
              markdown (normalize-pandoc-markdown pandoc-output)]
          (spit (get conversion :output-file) (string front-matter markdown))
          (sh/command-run ["rsync" "-av" "--include=*/" "--include=*.md" "--exclude=*" content-dir content-build-dir])))))))
