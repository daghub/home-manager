;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Dag Ekengren"
      user-mail-address "dag@ekengren.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-solarized-light)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

(after! evil
  ;; Prevent Evil's default C-z binding from entering Emacs state.
  (define-key evil-insert-state-map (kbd "C-z") #'ignore)
  (define-key evil-motion-state-map (kbd "C-z") #'ignore))

(defun dek/tmux-clipboard-copy (text)
  "Copy TEXT to the outer clipboard through tmux."
  (let ((tmux (executable-find "tmux")))
    (if (not tmux)
        (message "tmux clipboard copy failed: tmux not found")
      (let ((output (generate-new-buffer " *tmux clipboard*")))
        (unwind-protect
            (with-temp-buffer
              (insert text)
              (let ((exit-code
                     (call-process-region
                      (point-min)
                      (point-max)
                      tmux
                      nil
                      output
                      nil
                      "load-buffer"
                      "-w"
                      "-")))
                (unless (zerop exit-code)
                  (message "tmux clipboard copy failed: %s"
                           (with-current-buffer output
                             (string-trim (buffer-string)))))))
          (when (buffer-live-p output)
            (kill-buffer output)))))
    text))

(define-minor-mode dek/tmux-clipboard-mode
  "Send clipboard copies from this buffer through tmux."
  :lighter " TmuxClip"
  (if dek/tmux-clipboard-mode
      (progn
        (when (bound-and-true-p clipetty-mode)
          (clipetty-mode -1))
        (setq-local interprogram-cut-function #'dek/tmux-clipboard-copy))
    (when (eq interprogram-cut-function #'dek/tmux-clipboard-copy)
      (kill-local-variable 'interprogram-cut-function))))

(define-globalized-minor-mode dek/global-tmux-clipboard-mode
  dek/tmux-clipboard-mode
  (lambda ()
    (when (and (not (display-graphic-p))
               (getenv "TMUX" (selected-frame)))
      (dek/tmux-clipboard-mode +1))))

;; TTY Emacs over SSH/tmux: copy via OSC 52 to the outer terminal.
(after! clipetty
  (setq clipetty-assume-nested-mux t)
  (if (and (not (display-graphic-p))
           (getenv "TMUX" (selected-frame)))
      (progn
        (global-clipetty-mode -1)
        (dek/global-tmux-clipboard-mode +1))
    (global-clipetty-mode +1)))

(setq auto-mode-alist (append
        '(("BUILD\\'" . bazel-build-mode))
        '(("WORKSPACE\\'" . bazel-workspace-mode))
        '(("\\.BUILD\\'" . bazel-mode))
        '(("\\.bzl\\'" . bazel-starlark-mode))
        '(("\\.bazelrc\\'" . bazelrc-mode))
        auto-mode-alist)
)

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]bazel-.*\\'")
)

(after! helm
  ;; Doom keeps Helm navigation within a result source.  Continue into the
  ;; adjacent source at the boundary, so arrows traverse Buffers and Recentf.
  (defun dek/helm-next-candidate-or-source ()
    (interactive)
    (if (with-helm-window (helm-end-of-source-p))
        (helm-next-source)
      (helm-next-line)))
  (defun dek/helm-previous-candidate-or-source ()
    (interactive)
    (if (with-helm-window (helm-beginning-of-source-p))
        (helm-previous-source)
      (helm-previous-line)))
  (define-key helm-map (kbd "<down>") #'dek/helm-next-candidate-or-source)
  (define-key helm-map (kbd "<up>") #'dek/helm-previous-candidate-or-source))

;; Codex IDE -----------------------------------------------------------------
;;
;; This branch uses the native Codex app-server client, rather than Agent
;; Shell.  Codex remains the owner of the durable thread history.

(use-package! codex-ide
  :commands (codex-ide
             codex-ide-continue
             codex-ide-menu
             codex-ide-prompt
             codex-ide-status
             codex-ide-switch-to-buffer
             codex-ide-session-buffer-list
             codex-ide-session-diff-open
             codex-ide-submit-image
             codex-ide-submit-clipboard-image
             codex-ide-set-model-and-reasoning-effort
             codex-ide-interrupt)
  :config
  ;; Resolve the executable through the active Home Manager session instead of
  ;; baking a Nix store path into the configuration.
  (setq codex-ide-cli-path (or (executable-find "codex") "codex")
        codex-ide-new-session-split 'vertical
        codex-ide-model "gpt-5.6-terra"
        codex-ide-reasoning-effort "medium"))

(defun dek/codex-ide--register-workspace-buffer (&optional buffer)
  "Keep BUFFER visible in Doom's current workspace."
  (let ((buffer (if buffer (get-buffer buffer) (current-buffer))))
    (when buffer
      (with-current-buffer buffer
        (setq-local doom-real-buffer-p t))
      (when (and (bound-and-true-p persp-mode)
                 (fboundp 'get-current-persp)
                 (fboundp 'persp-add-buffer))
        (let ((persp (get-current-persp)))
          (when persp
            (persp-add-buffer buffer persp nil nil)))))))

(defun dek/codex-ide-register-current-buffer-h ()
  "Treat Codex IDE buffers as real workspace buffers."
  (dek/codex-ide--register-workspace-buffer (current-buffer)))

(dolist (hook '(codex-ide-session-mode-hook
                codex-ide-status-mode-hook
                codex-ide-session-buffer-list-mode-hook))
  (add-hook hook #'dek/codex-ide-register-current-buffer-h))

(after! codex-ide-window
  (defun dek/codex-ide-display-buffer-register-workspace-a (buffer &rest _)
    "Register displayed Codex BUFFER with the current Doom workspace."
    (dek/codex-ide--register-workspace-buffer buffer))
  (unless (advice-member-p
           #'dek/codex-ide-display-buffer-register-workspace-a
           #'codex-ide-display-buffer)
    (advice-add #'codex-ide-display-buffer
                :after
                #'dek/codex-ide-display-buffer-register-workspace-a)))

(after! codex-ide-renderer
  ;; Keep Codex sessions visible when opening file links from transcript text.
  (advice-add #'codex-ide-renderer-open-file-link
              :override
              #'codex-ide-renderer-open-file-link-other-window))

;; These views are autoloaded directly by their leader commands.  Use an Evil
;; buffer-local map in their mode hooks, so Doom's global normal-state `RET'
;; binding cannot take precedence over the picker action.
(defun dek/codex-ide-status-evil-bindings ()
  (evil-local-set-key 'normal (kbd "j") #'next-line)
  (evil-local-set-key 'normal (kbd "k") #'previous-line)
  (evil-local-set-key 'normal (kbd "n") #'codex-ide-status-mode-nav-forward)
  (evil-local-set-key 'normal (kbd "p") #'codex-ide-status-mode-nav-backward)
  (evil-local-set-key 'normal (kbd "RET") #'codex-ide-status-mode-display-session-at-point)
  (evil-local-set-key 'normal (kbd "TAB") #'codex-ide-section-toggle-at-point)
  (evil-local-set-key 'normal (kbd "g r") #'codex-ide-status-mode-refresh)
  (evil-local-set-key 'normal (kbd "D") #'codex-ide-status-mode-delete-thing-at-point)
  (evil-local-set-key 'normal (kbd "K") #'codex-ide-status-mode-kill-buffer-at-point))

(defun dek/codex-ide-session-buffer-list-evil-bindings ()
  (evil-local-set-key 'normal (kbd "RET") #'codex-ide-session-list-display-session-at-point)
  (evil-local-set-key 'normal (kbd "g r") #'codex-ide-session-buffer-list-redisplay)
  (evil-local-set-key 'normal (kbd "K") #'codex-ide-session-buffer-list-delete-buffer))

(add-hook 'codex-ide-status-mode-hook #'dek/codex-ide-status-evil-bindings)
(add-hook 'codex-ide-session-buffer-list-mode-hook
          #'dek/codex-ide-session-buffer-list-evil-bindings)

(defun dek/codex-ide-session-evil-bindings ()
  "Use chat-style prompt submission in Codex session buffers."
  (evil-local-set-key 'normal (kbd "RET") #'codex-ide-submit)
  (evil-local-set-key 'insert (kbd "RET") #'codex-ide-submit)
  (evil-local-set-key 'insert (kbd "S-<return>") #'newline))

(add-hook 'codex-ide-session-mode-hook #'dek/codex-ide-session-evil-bindings)

(defun dek/codex-ide--set-thread-name (session thread-id default-name)
  "Prompt for and persist a human-readable name for THREAD-ID."
  (let ((name (string-trim (read-string "Rename Codex session: " default-name))))
    (when (string-empty-p name)
      (user-error "Codex session names cannot be empty"))
    (codex-ide--request-sync session "thread/name/set"
                             `((threadId . ,thread-id) (name . ,name)))
    (message "Renamed Codex session to: %s" name)))

(defun dek/codex-ide-rename-session ()
  "Rename the current Codex session or the stored thread at point."
  (interactive)
  (if (derived-mode-p 'codex-ide-status-mode)
      (let* ((section (codex-ide-status-mode--actionable-section-at-point))
             (value (codex-ide-section-value section))
             (thread (if (eq (codex-ide-section-type section) 'thread)
                         value
                       nil))
             (session (if thread
                          (codex-ide--ensure-query-session-for-thread-selection
                           codex-ide-status-mode--directory)
                        value))
             (thread-id (if thread
                            (alist-get 'id thread)
                          (codex-ide-session-thread-id session)))
             (default-name (or (and thread (alist-get 'name thread))
                               (and thread (alist-get 'preview thread))
                               "")))
        (unless thread-id
          (user-error "The selected Codex session has no thread ID"))
        (dek/codex-ide--set-thread-name session thread-id default-name)
        (codex-ide-status-mode-refresh))
    (let* ((session (codex-ide--get-default-session-for-current-buffer))
           (thread-id (and session (codex-ide-session-thread-id session))))
      (unless thread-id
        (user-error "No Codex session is associated with this buffer"))
      (dek/codex-ide--set-thread-name session thread-id ""))))

(defun dek/codex-ide-status-rename-binding ()
  (evil-local-set-key 'normal (kbd "r") #'dek/codex-ide-rename-session))

(add-hook 'codex-ide-status-mode-hook #'dek/codex-ide-status-rename-binding)

(defun dek/codex-ide--thread-short-id (thread)
  "Return a short display id for THREAD."
  (let ((thread-id (alist-get 'id thread)))
    (if (stringp thread-id)
        (substring thread-id 0 (min 8 (length thread-id)))
      "")))

(defun dek/codex-ide--thread-display-title (thread)
  "Return a title for THREAD."
  (or (alist-get 'name thread)
      (alist-get 'title thread)
      (alist-get 'preview thread)
      "Untitled"))

(defun dek/codex-ide--thread-subject (thread)
  "Return a concise, context-free subject for THREAD."
  (let* ((raw (seq-find
               (lambda (value)
                 (and (stringp value)
                      (not (string-empty-p (string-trim value)))))
               (list (alist-get 'name thread)
                     (alist-get 'title thread)
                     (alist-get 'preview thread))))
         (subject (dek/codex-ide--one-line
                   (codex-ide--thread-choice-preview raw))))
    (if (string-empty-p subject)
        "Untitled"
      (truncate-string-to-width subject 80 nil nil "…"))))

(defun dek/codex-ide--thread-subject-candidates (threads)
  "Return subject-only completion candidates for THREADS."
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (thread threads)
      (let ((subject (dek/codex-ide--thread-subject thread)))
        (puthash subject (1+ (gethash subject counts 0)) counts)))
    (mapcar
     (lambda (thread)
       (let ((subject (dek/codex-ide--thread-subject thread)))
         (cons (if (> (gethash subject counts 0) 1)
                   (format "%s [%s]"
                           subject
                           (dek/codex-ide--thread-short-id thread))
                 subject)
               thread)))
     threads)))

(defun dek/codex-ide--thread-display-time (thread)
  "Return a display timestamp for THREAD."
  (let ((timestamp (or (alist-get 'updatedAt thread)
                       (alist-get 'createdAt thread))))
    (if (and timestamp (fboundp 'codex-ide--format-thread-updated-at))
        (codex-ide--format-thread-updated-at timestamp)
      "")))

(defun dek/codex-ide--codex-threads (&optional directory page-limit)
  "Return Codex threads, optionally restricted to DIRECTORY."
  (codex-ide--prepare-session-operations)
  (let* ((session (codex-ide--ensure-query-session-for-thread-selection
                   (codex-ide--get-working-directory)))
         (page-limit (or page-limit codex-ide-thread-list-default-limit))
         (cursor nil)
         (threads nil)
         (done nil))
    (while (not done)
      (let* ((params (append `((limit . ,page-limit)
                               (sortKey . "updated_at")
                               (sortDirection . "desc"))
                             (when directory
                               `((cwd . ,directory)))
                             (when cursor
                               `((cursor . ,cursor)))))
             (result (codex-ide--request-sync session "thread/list" params))
             (data (append (alist-get 'data result) nil)))
        (setq threads (append threads data))
        (setq cursor (alist-get 'nextCursor result))
        (unless cursor
          (setq done t))))
    threads))

(defun dek/codex-ide--all-codex-threads (&optional page-limit)
  "Return Codex threads across all projects."
  (dek/codex-ide--codex-threads nil page-limit))

(defun dek/codex-ide--project-codex-threads (&optional page-limit)
  "Return Codex threads for the current project."
  (dek/codex-ide--codex-threads
   (codex-ide--get-working-directory)
   page-limit))

(defun dek/codex-ide--all-thread-candidates (threads)
  "Return completion candidates for THREADS."
  (mapcar
   (lambda (thread)
     (let* ((cwd (or (alist-get 'cwd thread) ""))
            (label (format "%s  [%s]  %s  %s"
                           (dek/codex-ide--thread-display-time thread)
                           (dek/codex-ide--thread-short-id thread)
                           (dek/codex-ide--thread-display-title thread)
                           (abbreviate-file-name cwd))))
       (cons label thread)))
   threads))

(defun dek/codex-ide-resume-any-session ()
  "Resume a stored Codex session from any recorded project."
  (interactive)
  (require 'codex-ide)
  (require 'codex-ide-threads)
  (let* ((threads (dek/codex-ide--all-codex-threads))
         (choices (dek/codex-ide--all-thread-candidates threads)))
    (unless choices
      (user-error "No Codex threads found"))
    (let* ((choice (completing-read "Resume Codex thread: " choices nil t))
           (thread (cdr (assoc choice choices)))
           (thread-id (alist-get 'id thread))
           (cwd (alist-get 'cwd thread)))
      (unless (and thread-id cwd)
        (user-error "Selected Codex thread is missing id or cwd"))
      (codex-ide--show-or-resume-thread thread-id cwd))))

(defun dek/codex-ide--one-line (text)
  "Return TEXT trimmed and collapsed to one line."
  (replace-regexp-in-string
   "[[:space:]]+"
   " "
   (string-trim (or text ""))))

(defun dek/codex-ide--sessions-directory ()
  "Return the local Codex sessions directory."
  (expand-file-name "sessions" (or (getenv "CODEX_HOME") "~/.codex")))

(defun dek/codex-ide--codex-program ()
  "Return the Codex CLI executable."
  (or (executable-find "codex")
      (let ((codex (expand-file-name "~/.local/bin/codex")))
        (when (file-executable-p codex)
          codex))
      (user-error "Could not find the codex executable")))

(defun dek/codex-ide--session-search-rg-query-args (query regex)
  "Return ripgrep query arguments for searching QUERY.
When REGEX is nil, search for QUERY as a literal string."
  (append '("--ignore-case")
          (unless regex '("--fixed-strings"))
          (list "--" query)))

(defun dek/codex-ide--session-search-rg-file-args (query regex)
  "Return ripgrep file-search arguments for QUERY."
  (append '("--glob" "*.jsonl")
          (dek/codex-ide--session-search-rg-query-args query regex)))

(defun dek/codex-ide--session-search-files (query &optional regex)
  "Return local Codex session files containing QUERY.
When REGEX is non-nil, treat QUERY as a ripgrep regular expression."
  (let ((rg (executable-find "rg"))
        (sessions-dir (dek/codex-ide--sessions-directory)))
    (unless rg
      (user-error "Searching Codex sessions requires rg"))
    (unless (file-directory-p sessions-dir)
      (user-error "Codex sessions directory does not exist: %s" sessions-dir))
    (with-temp-buffer
      (let ((exit-code
             (apply
              #'process-file
              rg
              nil
              t
              nil
              (append '("--files-with-matches")
                      (dek/codex-ide--session-search-rg-file-args
                       query regex)
                      (list sessions-dir)))))
        (cond
         ((zerop exit-code)
          (split-string (buffer-string) "\n" t))
         ((= exit-code 1)
          nil)
         (t
          (user-error "rg failed while searching Codex sessions: %s"
                      (string-trim (buffer-string)))))))))

(defun dek/codex-ide--json-string-field (field text)
  "Return JSON string FIELD from TEXT, or nil."
  (when (string-match
         (format "\"%s\":\"\\([^\"\\]*\\(?:\\\\.[^\"\\]*\\)*\\)\""
                 (regexp-quote field))
         text)
    (json-read-from-string (concat "\"" (match-string 1 text) "\""))))

(defun dek/codex-ide--session-file-metadata (path)
  "Return basic Codex session metadata from PATH."
  (with-temp-buffer
    (insert-file-contents path nil 0 262144)
    (let ((metadata-line
           (buffer-substring-no-properties
            (point-min)
            (line-end-position))))
      (list :id (dek/codex-ide--json-string-field "id" metadata-line)
            :session-id (dek/codex-ide--json-string-field "session_id"
                                                          metadata-line)
            :parent-thread-id
            (dek/codex-ide--json-string-field "parent_thread_id"
                                              metadata-line)
            :cwd (dek/codex-ide--json-string-field "cwd" metadata-line)))))

(defun dek/codex-ide--thread-search-text (thread)
  "Return searchable metadata text for THREAD."
  (let ((values (list (alist-get 'id thread)
                      (alist-get 'name thread)
                      (alist-get 'title thread)
                      (alist-get 'threadName thread)
                      (alist-get 'thread_name thread)
                      (alist-get 'preview thread)
                      (alist-get 'cwd thread))))
    (mapconcat #'identity
               (delq nil
                     (mapcar (lambda (value)
                               (when value
                                 (dek/codex-ide--one-line
                                  (format "%s" value))))
                             values))
               " ")))

(defun dek/codex-ide--thread-metadata-match-ids
    (threads query &optional regex)
  "Return ids for THREADS whose metadata matches QUERY.
When REGEX is non-nil, treat QUERY as a ripgrep regular expression."
  (let ((rg (executable-find "rg")))
    (unless rg
      (user-error "Searching Codex sessions requires rg"))
    (let ((output (generate-new-buffer " *codex metadata search*")))
      (unwind-protect
          (with-temp-buffer
            (dolist (thread threads)
              (when-let* ((thread-id (alist-get 'id thread)))
                (insert thread-id "\t"
                        (dek/codex-ide--thread-search-text thread)
                        "\n")))
            (let ((exit-code
                   (apply
                    #'call-process-region
                    (point-min)
                    (point-max)
                    rg
                    nil
                    output
                    nil
                    (append '("--line-number")
                            (dek/codex-ide--session-search-rg-query-args
                             query regex)))))
              (cond
               ((zerop exit-code)
                (with-current-buffer output
                  (goto-char (point-min))
                  (let ((seen (make-hash-table :test 'equal))
                        (thread-ids nil))
                    (while (re-search-forward
                            "^[0-9]+:\\([^\t\n]+\\)\t"
                            nil t)
                      (let ((thread-id (match-string 1)))
                        (unless (gethash thread-id seen)
                          (puthash thread-id t seen)
                          (push thread-id thread-ids))))
                    (nreverse thread-ids))))
               ((= exit-code 1)
                nil)
               (t
                (with-current-buffer output
                  (user-error
                   "rg failed while searching Codex session titles: %s"
                   (string-trim (buffer-string))))))))
        (when (buffer-live-p output)
          (kill-buffer output))))))

(defun dek/codex-ide--shorten (text max-width)
  "Return TEXT truncated to MAX-WIDTH display columns."
  (let ((text (or text "")))
    (if (> (string-width text) max-width)
        (concat (truncate-string-to-width text (- max-width 3)
                                          nil nil t)
                "...")
      text)))

(defun dek/codex-ide--thread-metadata-snippet (thread)
  "Return a compact metadata snippet for THREAD."
  (let* ((title (dek/codex-ide--one-line
                 (dek/codex-ide--thread-display-title thread)))
         (preview (dek/codex-ide--one-line
                   (or (alist-get 'preview thread) "")))
         (text (if (and (not (string-empty-p preview))
                        (not (string= title preview)))
                   (format "title: %s preview: %s" title preview)
                 (format "title: %s" title))))
    (dek/codex-ide--shorten text 220)))

(defun dek/codex-ide--session-file-regex-snippet (path query)
  "Return a compact ripgrep-regex snippet around QUERY in session file PATH."
  (let ((rg (executable-find "rg")))
    (when rg
      (with-temp-buffer
        (let ((exit-code
               (apply
                #'process-file
                rg
                nil
                t
                nil
                (append '("--json" "--max-count" "1")
                        (dek/codex-ide--session-search-rg-file-args
                         query t)
                        (list path)))))
          (when (zerop exit-code)
            (goto-char (point-min))
            (let (snippet)
              (while (and (not snippet) (not (eobp)))
                (let* ((json-object-type 'alist)
                       (json-array-type 'list)
                       (json-key-type 'symbol)
                       (event (ignore-errors
                                (json-read-from-string
                                 (buffer-substring-no-properties
                                  (line-beginning-position)
                                  (line-end-position))))))
                  (when (equal (alist-get 'type event) "match")
                    (let* ((data (alist-get 'data event))
                           (lines (alist-get 'lines data))
                           (text (or (alist-get 'text lines) ""))
                           (submatch (car (alist-get 'submatches data)))
                           (match-start (or (alist-get 'start submatch) 0))
                           (match-end (or (alist-get 'end submatch)
                                          match-start))
                           (text-length (length text))
                           (start (max 0
                                       (- (min match-start text-length) 80)))
                           (end (min text-length
                                     (+ (min match-end text-length) 120)))
                           (raw-snippet (substring text start end)))
                      (setq raw-snippet
                            (replace-regexp-in-string "\\\\n" " "
                                                      raw-snippet))
                      (setq raw-snippet
                            (replace-regexp-in-string "\\\\\"" "\""
                                                      raw-snippet))
                      (setq snippet
                            (concat (if (> start 0) "..." "")
                                    (dek/codex-ide--one-line raw-snippet)
                                    (if (< end text-length) "..." ""))))))
                (forward-line 1))
              (or snippet ""))))))))

(defun dek/codex-ide--session-file-snippet (path query &optional regex)
  "Return a compact snippet around QUERY in session file PATH."
  (if regex
      (or (dek/codex-ide--session-file-regex-snippet path query) "")
    (with-temp-buffer
      (insert-file-contents path)
      (let ((case-fold-search t))
        (if (search-forward query nil t)
            (let* ((start (max (point-min) (- (match-beginning 0) 80)))
                   (end (min (point-max) (+ (match-end 0) 120)))
                   (snippet (buffer-substring-no-properties start end)))
              (setq snippet (replace-regexp-in-string "\\\\n" " " snippet))
              (setq snippet (replace-regexp-in-string "\\\\\"" "\"" snippet))
              (concat (if (> start (point-min)) "..." "")
                      (dek/codex-ide--one-line snippet)
                      (if (< end (point-max)) "..." "")))
          "")))))

(defun dek/codex-ide--threads-by-id (threads)
  "Return a hash table mapping THREADS by id."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (thread threads)
      (when-let* ((thread-id (alist-get 'id thread)))
        (puthash thread-id thread table)))
    table))

(defun dek/codex-ide--thread-for-session-file (metadata threads-by-id)
  "Return the thread matching METADATA from THREADS-BY-ID."
  (let ((ids (list (plist-get metadata :id)
                   (plist-get metadata :session-id)
                   (plist-get metadata :parent-thread-id)))
        thread)
    (while (and ids (not thread))
      (when (car ids)
        (setq thread (gethash (car ids) threads-by-id)))
      (setq ids (cdr ids)))
    thread))

(defun dek/codex-ide--thread-search-candidate (match)
  "Return a completion candidate for MATCH."
  (let* ((thread (plist-get match :thread))
         (snippet (plist-get match :snippet))
         (cwd (or (alist-get 'cwd thread) ""))
         (title (dek/codex-ide--one-line
                 (dek/codex-ide--thread-display-title thread))))
    (cons (format "%s  [%s]  %s  %s  %s"
                  (dek/codex-ide--thread-display-time thread)
                  (dek/codex-ide--thread-short-id thread)
                  title
                  snippet
                  (abbreviate-file-name cwd))
          match)))

(defun dek/codex-ide--search-sessions (query &optional regex)
  "Search stored Codex sessions for QUERY.
When REGEX is non-nil, treat QUERY as a ripgrep regular expression."
  (require 'codex-ide)
  (require 'codex-ide-threads)
  (require 'json)
  (setq query (string-trim query))
  (when (string-empty-p query)
    (user-error "Search query cannot be empty"))
  (let* ((files (dek/codex-ide--session-search-files query regex))
         (threads (dek/codex-ide--all-codex-threads))
         (threads-by-id (dek/codex-ide--threads-by-id threads))
         (metadata-thread-ids
          (dek/codex-ide--thread-metadata-match-ids
           threads query regex))
         (seen (make-hash-table :test 'equal))
         (skipped 0)
         (matches nil))
    (message "Searching %d transcript file%s and %d title match%s..."
             (length files)
             (if (= (length files) 1) "" "s")
             (length metadata-thread-ids)
             (if (= (length metadata-thread-ids) 1) "" "es"))
    (dolist (thread-id metadata-thread-ids)
      (when-let* ((thread (gethash thread-id threads-by-id)))
        (puthash thread-id t seen)
        (push (list :thread thread
                    :snippet
                    (dek/codex-ide--thread-metadata-snippet thread))
              matches)))
    (dolist (path files)
      (condition-case _err
          (let* ((metadata (dek/codex-ide--session-file-metadata path))
                 (thread (dek/codex-ide--thread-for-session-file
                          metadata
                          threads-by-id))
                 (thread-id (and thread (alist-get 'id thread))))
            (if (or (not thread-id) (gethash thread-id seen))
                (setq skipped (1+ skipped))
              (puthash thread-id t seen)
              (push (list :thread thread
                          :snippet
                          (dek/codex-ide--session-file-snippet
                           path query regex))
                    matches)))
        (error
         (setq skipped (1+ skipped)))))
    (unless matches
      (user-error "No Codex sessions match: %s" query))
    (let* ((choices
            (mapcar (lambda (match)
                      (dek/codex-ide--thread-search-candidate match))
                    (nreverse matches)))
           (choice (completing-read "Resume Codex match: " choices nil t))
           (thread (plist-get (cdr (assoc choice choices)) :thread))
           (thread-id (alist-get 'id thread))
           (cwd (alist-get 'cwd thread)))
      (when (> skipped 0)
        (message "Skipped %d duplicate or unlisted Codex session file%s"
                 skipped
                 (if (= skipped 1) "" "s")))
      (unless (and thread-id cwd)
        (user-error "Selected Codex thread is missing id or cwd"))
      (codex-ide--show-or-resume-thread thread-id cwd))))

(defun dek/codex-ide-search-sessions (query)
  "Search stored Codex sessions by literal transcript content."
  (interactive (list (read-string "Search Codex sessions: ")))
  (dek/codex-ide--search-sessions query))

(defun dek/codex-ide-search-sessions-regex (query)
  "Search stored Codex sessions by ripgrep regular expression."
  (interactive (list (read-string "Regex search Codex sessions: ")))
  (dek/codex-ide--search-sessions query t))

(defun dek/codex-ide--select-thread
    (prompt &optional candidate-function threads-function)
  "Prompt with PROMPT for one stored Codex thread.

When CANDIDATE-FUNCTION is non-nil, call it with the stored threads to
construct the completion candidates.  When THREADS-FUNCTION is non-nil,
call it to obtain the threads."
  (let* ((current-session (codex-ide--session-for-current-buffer))
         (current-thread-id (and current-session
                                 (codex-ide-session-thread-id
                                  current-session)))
         (threads (funcall (or threads-function
                               #'dek/codex-ide--all-codex-threads)))
         (choices (funcall (or candidate-function
                               #'dek/codex-ide--all-thread-candidates)
                           threads))
         (default-choice
          (car (seq-find
                (lambda (choice)
                  (equal (alist-get 'id (cdr choice)) current-thread-id))
                choices))))
    (unless choices
      (user-error "No Codex threads found"))
    (cdr (assoc (completing-read prompt choices nil t nil nil default-choice)
                choices))))

(defun dek/codex-ide--status-thread-at-point ()
  "Return the Codex thread represented by the status entry at point."
  (when (derived-mode-p 'codex-ide-status-mode)
    (require 'codex-ide-status-mode)
    (when-let* ((section
                 (ignore-errors
                   (codex-ide-status-mode--actionable-section-at-point))))
      (pcase (codex-ide-section-type section)
        ('thread
         (codex-ide-section-value section))
        ('buffer
         (let* ((session (codex-ide-section-value section))
                (buffer (and (codex-ide-session-p session)
                             (codex-ide-session-buffer session))))
           (when (and (codex-ide-session-p session)
                      (codex-ide-session-thread-id session))
             `((id . ,(codex-ide-session-thread-id session))
               (name . ,(if (buffer-live-p buffer)
                            (buffer-name buffer)
                          "Live Codex session"))
               (cwd . ,(or codex-ide-status-mode--directory
                           default-directory))))))))))

(defun dek/codex-ide--current-session-thread ()
  "Return the stored thread for the current Codex session buffer."
  (when (derived-mode-p 'codex-ide-session-mode)
    (when-let* ((session (codex-ide--session-for-current-buffer))
                (thread-id (codex-ide-session-thread-id session)))
      (or (alist-get 'thread
                     (ignore-errors
                       (codex-ide--read-thread session thread-id nil)))
          `((id . ,thread-id)
            (name . "Current Codex session")
            (cwd . ,(codex-ide-session-directory session)))))))

(defun dek/codex-ide-archive-session (&optional all-projects)
  "Archive a stored Codex session using the Codex CLI.

By default, offer sessions from the current project.  When ALL-PROJECTS
is non-nil, offer sessions from every project."
  (interactive)
  (require 'codex-ide)
  (require 'codex-ide-delete-session-thread)
  (require 'codex-ide-threads)
  (let* ((status-buffer (and (derived-mode-p 'codex-ide-status-mode)
                             (current-buffer)))
         (thread (or (and (not all-projects)
                          (or (dek/codex-ide--current-session-thread)
                              (dek/codex-ide--status-thread-at-point)))
                     ;; Archive selection should show only the session
                     ;; subject, without transcript metadata or context.
                     (dek/codex-ide--select-thread
                      (if all-projects
                          "Archive Codex thread from any project: "
                        "Archive Codex thread from this project: ")
                      #'dek/codex-ide--thread-subject-candidates
                      (unless all-projects
                        #'dek/codex-ide--project-codex-threads))))
         (thread-id (alist-get 'id thread))
         (title (dek/codex-ide--thread-subject thread))
         (codex (dek/codex-ide--codex-program)))
    (unless thread-id
      (user-error "Selected Codex thread is missing id"))
    (unless (yes-or-no-p
             (format "Archive Codex thread %s (%s)? " thread-id title))
      (user-error "Canceled archive of Codex thread %s" thread-id))
    (when-let* ((session (codex-ide--session-for-thread-id-any thread-id)))
      (codex-ide--delete-live-thread-session session))
    (with-temp-buffer
      (let ((exit-code
             (process-file codex nil (list t t) nil "archive" thread-id))
            (output nil))
        (setq output (dek/codex-ide--one-line (buffer-string)))
        (if (zerop exit-code)
            (message "%s" (or (and (not (string-empty-p output)) output)
                              (format "Archived Codex thread %s" thread-id)))
          (user-error "Failed to archive Codex thread %s: %s"
                      thread-id
                      output))))
    (when (and status-buffer (buffer-live-p status-buffer))
      (with-current-buffer status-buffer
        (when (derived-mode-p 'codex-ide-status-mode)
          (codex-ide-status-mode-refresh))))))

(defun dek/codex-ide-archive-any-session ()
  "Archive a stored Codex session from any project."
  (interactive)
  (dek/codex-ide-archive-session t))

(defun dek/codex-ide-set-model ()
  "Set the Codex model for a selected scope."
  (interactive)
  (require 'codex-ide-config)
  (let* ((session (codex-ide--session-for-current-buffer))
         (model (codex-ide-config-read-value 'model session)))
    (codex-ide-config-apply-interactively
     'model
     (unless (string-empty-p model) model)
     session)))

(defun dek/codex-ide-set-reasoning-effort ()
  "Set Codex reasoning effort for a selected scope."
  (interactive)
  (require 'codex-ide-config)
  (let* ((session (codex-ide--session-for-current-buffer))
         (model (codex-ide-config-effective-value 'model session))
         (effort (codex-ide-config-read-value
                  'reasoning-effort session model)))
    (codex-ide-config-apply-interactively
     'reasoning-effort effort session)))

(defun dek/codex-ide-set-model-and-effort ()
  "Set Codex model and reasoning effort together."
  (interactive)
  (require 'codex-ide-config)
  (call-interactively #'codex-ide-set-model-and-reasoning-effort))

(defun dek/codex-ide-menu ()
  "Open a personal Codex command menu without transient."
  (interactive)
  (let* ((commands
          '(("Set model" . dek/codex-ide-set-model)
            ("Prompt from minibuffer" . codex-ide-prompt)
            ("Attach image file" . codex-ide-submit-image)
            ("Attach clipboard image" . codex-ide-submit-clipboard-image)))
         (choice (completing-read "Codex: " commands nil t)))
    (call-interactively (cdr (assoc choice commands)))))

(defalias 'codex-ide-menu #'dek/codex-ide-menu)

(after! codex-ide-transient
  (defalias 'codex-ide-menu #'dek/codex-ide-menu))

(after! codex-ide-session-mode
  (map! :map codex-ide-session-mode-map
        :localleader
        :desc "Codex menu" "m" #'dek/codex-ide-menu
        :desc "Session diff" "d" #'codex-ide-session-diff-open
        :desc "Interrupt turn" "k" #'codex-ide-interrupt
        :desc "Toggle detail" "v" #'codex-ide-session-transcript-toggle-detail-level))

(after! codex-ide-status-mode
  (define-key codex-ide-status-mode-map
              (kbd "a")
              #'dek/codex-ide-archive-session))

(map! :leader
      :prefix ("a" . "agents")
      :desc "New Codex session"       "n" #'codex-ide
      :desc "Continue latest session" "c" #'codex-ide-continue
      :desc "Codex menu"               "m" #'dek/codex-ide-menu
      :desc "Project session history" "s" #'codex-ide-status
      :desc "All Codex sessions"      "S" #'dek/codex-ide-resume-any-session
      :desc "Search Codex sessions"   "/" #'dek/codex-ide-search-sessions
      :desc "Regex search sessions"   "?" #'dek/codex-ide-search-sessions-regex
      :desc "Archive project session" "a" #'dek/codex-ide-archive-session
      :desc "Archive any session"     "A" #'dek/codex-ide-archive-any-session
      :desc "Live Codex sessions"     "l" #'codex-ide-session-buffer-list
      :desc "Current project session" "b" #'codex-ide-switch-to-buffer
      :desc "Set model and effort"    "M" #'dek/codex-ide-set-model-and-effort
      :desc "Set reasoning effort"    "e" #'dek/codex-ide-set-reasoning-effort
      :desc "Rename Codex session"    "r" #'dek/codex-ide-rename-session
      :desc "Session diff"             "d" #'codex-ide-session-diff-open
      :desc "Interrupt active turn"    "k" #'codex-ide-interrupt)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
