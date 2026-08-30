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
(setq doom-theme 'doom-acario-dark)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Enable clipetty everywhere. This should not be needed, but it.
(after! clipetty
  (global-clipetty-mode 1))
(xclip-mode 1)

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

;; Codex IDE -----------------------------------------------------------------
;;
;; This branch uses the native Codex app-server client, rather than Agent
;; Shell.  Codex remains the owner of the durable thread history.

(use-package! codex-ide
  :commands (codex-ide
             codex-ide-continue
             codex-ide-menu
             codex-ide-status
             codex-ide-switch-to-buffer
             codex-ide-session-buffer-list
             codex-ide-session-diff-open
             codex-ide-interrupt)
  :config
  ;; Resolve the executable through the active Home Manager session instead of
  ;; baking a Nix store path into the configuration.
  (setq codex-ide-cli-path (or (executable-find "codex") "codex")
        codex-ide-new-session-split 'vertical)

  ;; The upstream package uses ordinary local maps.  Define the important
  ;; actions explicitly for Doom's Evil normal state.
  (require 'codex-ide-status-mode)
  (require 'codex-ide-session-buffer-list)
  (evil-define-key* 'normal codex-ide-status-mode-map
    "j" #'next-line
    "k" #'previous-line
    "n" #'codex-ide-status-mode-nav-forward
    "p" #'codex-ide-status-mode-nav-backward
    "RET" #'codex-ide-status-mode-display-session-at-point
    "TAB" #'codex-ide-section-toggle-at-point
    "g" #'codex-ide-status-mode-refresh
    "D" #'codex-ide-status-mode-delete-thing-at-point
    "K" #'codex-ide-status-mode-kill-buffer-at-point)
  (evil-define-key* 'normal codex-ide-session-buffer-list-mode-map
    "RET" #'codex-ide-session-list-display-session-at-point
    "g" #'codex-ide-session-buffer-list-redisplay
    "K" #'codex-ide-session-buffer-list-delete-buffer)

  (map! :map codex-ide-session-mode-map
        :localleader
        :desc "Codex menu" "m" #'codex-ide-menu
        :desc "Session diff" "d" #'codex-ide-session-diff-open
        :desc "Interrupt turn" "k" #'codex-ide-interrupt
        :desc "Toggle detail" "v" #'codex-ide-session-transcript-toggle-detail-level))

(map! :leader
      :prefix ("a" . "agents")
      :desc "New Codex session"       "n" #'codex-ide
      :desc "Continue latest session" "c" #'codex-ide-continue
      :desc "Codex menu"               "m" #'codex-ide-menu
      :desc "Project session history" "s" #'codex-ide-status
      :desc "Live Codex sessions"     "l" #'codex-ide-session-buffer-list
      :desc "Current project session" "b" #'codex-ide-switch-to-buffer
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
