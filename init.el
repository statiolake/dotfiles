;; init.el --- Emacs configuration
;; https://emacs-jp.github.io/tips/emacs-in-2020 を参考にしている。

;; Emacs 27 における互換性設定
;;
;; `cl` なるパッケージは deprecated になったらしいが、多数のパッケージに依存されていて外すことはできないらしい。とりあ
;; えず警告を無視する設定を置く。
;; See also: https://www.ncaq.net/2020/05/13/21/16/35/
;;
(setq byte-compile-warnings '(not cl-functions obsolete))

;; package と、必要に応じて leaf を自動的にインストールする。
(eval-and-compile
  (customize-set-variable
   'package-archives '(("gnu"   . "https://elpa.gnu.org/packages/")
                       ("melpa" . "https://melpa.org/packages/")
                       ("org"   . "https://orgmode.org/elpa/")))
  (package-initialize)
  (unless (package-installed-p 'leaf)
    (package-refresh-contents)
    (package-install 'leaf))

  (leaf leaf-keywords
    :ensure t
    :init
    (leaf hydra :ensure t)
    (leaf el-get :ensure t)
    (leaf blackout :ensure t)
    :config (leaf-keywords-init)        ; leaf-keywords.el を初期化する
    ))

;; 各種設定

(leaf *language-environment
  :doc "言語環境"
  :config
  (prefer-coding-system 'utf-8)
  (set-file-name-coding-system 'cp932)
  (set-keyboard-coding-system 'cp932)
  (set-terminal-coding-system 'cp932))

(leaf cus-edit
  :doc "Emacs 標準および Emacs Lisp パッケージを管理するツール"
  :tag "builtin" "faces" "help"
  ;; init.el に custom が設定を追記しないようにする (leaf との二重管理を避けるため)
  :custom `((custom-file . ,(locate-user-emacs-file "custom.el"))))

(leaf cus-start
  :doc "Emacs 標準の設定定義"
  :tag "builtin" "internal"
  :custom '((user-full-name . "statiolake")
            (user-mail-address . "statiolake@gmail.com")
            (user-login-name . (getenv "USER"))
            (create-lockfiles . nil)
            (debug-on-error . nil)
            (history-length . 1000)
            (history-delete-duplicates . t)
            (scroll-preserve-screen-position . t)
            (mouse-wheel-scroll-amount . '(1 ((control) . 5)))
            (ring-bell-function . 'ignore)
            (text-quoting-style . 'straight)
            (menu-bar-mode . nil)
            (tool-bar-mode . nil)
            (scroll-bar-mode . nil)
            (indent-tabs-mode . nil)
            (tab-width . 4)
            (show-trailing-whitespace . nil)
            (enable-recursive-minibuffers . t)
            `(frame-title-format . ,(format "%%b - %s-%s@%s"
                                            invocation-name
                                            emacs-version (system-name)))))

(leaf startup
  :doc "起動時の設定"
  :tag "builtin"
  :custom ((inhibit-startup-screen . t)))

(leaf autorevert
  :doc "外部でファイルが書き換わったとき、自動的に読み直す機能"
  :tag "builtin"
  :custom ((auto-revert-internal . 1))
  :global-minor-mode global-auto-revert-mode)

(leaf paren
  :doc "マッチする括弧のハイライト"
  :tag "builtin"
  :custom ((show-paren-delay . 0.1))
  :global-minor-mode show-paren-mode)

(leaf simple
  :doc "Emacs の基本的な編集コマンドについての設定"
  :tag "builtin" "internal"
  :bind (("M-g" . goto-line))
  :hook (before-save-hook . delete-trailing-whitespace)
  :custom ((kill-whole-line . nil)
           (fill-column . 120)))

(leaf files
  :doc "Emacs のファイル入出力に関するコマンドの設定"
  :tag "builtin"
  :custom ((require-final-newline . t)  ; 最終行で改行を要求する
           (mode-require-final-newline . t)
           (auto-save-default . nil)    ; 自動保存・バックアップファイルの作成はしない
           (make-backup-files . nil)
           (undo-limit . 600000)        ; Undo 上限を引き上げる
           (undo-strong-limit . 900000)))

(leaf tr-ime
  :doc "IME 連携設定"
  :ensure t
  :custom (w32-ime-buffer-switch-p . nil)
  :config
  (tr-ime-advanced-install)
  ;; IM のデフォルトを IME に設定
  (setq default-input-method "W32-IME")
  ;; IME 初期化
  (w32-ime-initialize)
  ;; IME 制御 (yes/no などの入力の時に IME を off にする)
  (wrap-function-to-control-ime 'universal-argument t nil)
  (wrap-function-to-control-ime 'read-string nil nil)
  (wrap-function-to-control-ime 'read-char nil nil)
  (wrap-function-to-control-ime 'read-from-minibuffer nil nil)
  (wrap-function-to-control-ime 'y-or-n-p nil nil)
  (wrap-function-to-control-ime 'yes-or-no-p nil nil)
  (wrap-function-to-control-ime 'map-y-or-n-p nil nil)
  ;; フォント設定
  (modify-all-frames-parameters '((ime-font . "MeiryoKe_Gothic-11"))))

;; (leaf disable-mouse
;;   :doc "マウスイベントの無効化"
;;   :ensure t
;;   :global-minor-mode global-disable-mouse-mode)

(leaf window
  :doc "ウィンドウ移動"
  :tag "builtin"
  :bind ("C-:" . other-window))

(leaf rect
  :doc "矩形選択"
  :tag "builtin"
  :bind ("C-x C-SPC" . rectangle-mark-mode))

(leaf *user-functions
  :doc "ユーザー定義関数とキーバインディング"
  :config
  (leaf *edit-ext
    :doc "編集コマンドの拡張"
    :leaf-autoload nil
    :leaf-defer nil
    :bind (("M-y"   . duplicate-line)
           ("M-^"   . my-delete-indentation)
           ("M-d"   . kill-word-at-point)
           ("C-o"   . newline-next)
           ("C-S-o" . newline-previous))
    :config
    (defun duplicate-line (&optional numlines)
      "一行コピーする。"
      (interactive "p")
      (let* ((col (current-column))
             (bol (progn (beginning-of-line) (point)))
             (eol (progn (end-of-line) (point)))
             (line (buffer-substring bol eol)))
        (while (> numlines 0)
          (insert "\n" line)
          (setq numlines (- numlines 1)))
        (move-to-column col)))

    (defun my-delete-indentation (&optional arg beg end)
      "delete-indentation だが、日本語か英語かにより結合時に空白を入れるかどうかを判断する。"
      (interactive
       (progn (barf-if-buffer-read-only)
              (cons current-prefix-arg
                    (and (use-region-p)
                         (list (region-beginning) (region-end))))))
      ;; 動作完了後、常にリージョンを無効化する。
      (setq deactivate-mark t)
      (if (and beg (not arg))
          ;; リージョンがある。リージョンが複数行ある場合はリージョンの最後尾へ
          (and (goto-char beg)
               (> end (line-end-position))
               (goto-char end))
        ;; リージョンがない。ループの終了点を設定する。
        ;; (バッファの開始点と比較するために 1 を引いておく。)
        (setq beg (1- (line-beginning-position (and arg 2))))
        (when arg (forward-line)))
      (let ((prefix (and (> (length fill-prefix) 0)
                         (regexp-quote fill-prefix))))
        (while (and (> (line-beginning-position) beg)
                    (forward-line 0)
                    (= (preceding-char) ?\n))
          (delete-char -1)
          ;; くっつけたラインが prefix を含むならそれを削除する。
          (if (and prefix (looking-at prefix))
              (replace-match "" t t))
          ;; 一旦空白をすべて削除し、前後が ascii ならば空白を挿入する。
          ;; ただし前後が括弧類ならば空白を入れない。
          (delete-horizontal-space)
          (when (and (or (eq (char-charset (following-char)) 'ascii)
                         (eq (char-charset (preceding-char)) 'ascii))
                     (not (or (member (preceding-char) '(?\x28 ?\x5b))    ; (, [
                              (member (following-char) '(?\x29 ?\x5d))))) ; ), ]
            (insert-char ?\x20))))) ; SPC

    (defun kill-word-at-point ()
      "カーソル位置の単語を削除する。"
      (interactive)
      (let ((char (char-to-string (char-after (point)))))
        (cond
         ((string= "\n" char) (delete-char 1) (delete-horizontal-space))
         ((string= " " char) (delete-horizontal-space))
         ((string-match "[\t\n -@\[-`{-~]" char) (kill-word 1))
         (t (forward-char) (backward-word) (kill-word 1)))))

    (defun newline-next ()
      "下に改行して次の行へ行く。"
      (interactive)
      (end-of-line)
      (newline-and-indent))

    (defun newline-previous ()
      "上に改行して前の行へ行く。"
      (interactive)
      (beginning-of-line)
      (newline)
      (forward-line -1)))

  (leaf *indent
    :doc "インデントの手動調整"
    :leaf-autoload nil
    :leaf-defer nil
    :bind (("C-S-u" . up-indent)
           ("C-S-d" . down-indent)
           ("C-c i" . smart-indenter))
    :config
    (defun down-indent-once ()
      "インデントを一つ下げる。インデント量は tab-width を利用。"
      (save-excursion
        (beginning-of-line)
        (dotimes (_ tab-width)
          (cond ((string= (char-to-string (char-after (point))) " ")
                 (delete-char 1))))))

    (defun up-indent-once ()
      "インデントを一つ上げる。インデント量は tab-width を利用。"
      (save-excursion
        (beginning-of-line)
        (dotimes (_ tab-width) (insert " "))))

    (defun down-indent (&optional times)
      "インデントをいくつか下げる。"
      (interactive "p")
      (cond ((not times) (setq times 1)))
      (dotimes (_ times) (down-indent-once)))

    (defun up-indent (&optional times)
      "インデントをいくつか上げる。"
      (interactive "p")
      (cond ((not times) (setq times 1)))
      (dotimes (_ times) (up-indent-once)))

    (defun indent-all ()
      "ソースすべてをインデントする。"
      (interactive)
      (let ((pos (point))
            (mbeg (point-min-marker))
            (mend (point-max-marker)))
        (indent-region mbeg mend)
        (set-marker mbeg nil)
        (set-marker mend nil)))

    (defun smart-indenter ()
      (interactive)
      "賢くインデントする。"
      (if mark-active
          (indent-region (region-beginning) (region-end))
        (indent-region (line-beginning-position) (line-end-position)))))

  (leaf *move-ext
    :doc "カーソル移動の拡張"
    :leaf-autoload nil
    :leaf-defer nil
    :bind (("C-S-f" . search-forward-with-char)
           ("C-S-b" . search-backward-with-char)
           ("C-<" . search-invert-with-char)
           ("C-+" . search-repeat-with-char))
    :config
    (defvar last-search-char nil)
    (defvar last-search-direction 'forward)

    (defun search-forward-with-char (char)
      "順方向へ一文字検索"
      (interactive "cMove to Char: ")
      (search-direction-with-char 'forward char t))

    (defun search-backward-with-char (char)
      "逆方向へ一文字検索"
      (interactive "cMove backward to Char: ")
      (search-direction-with-char 'backward char t))

    (defun search-repeat-with-char ()
      "前回と同方向・同文字で検索"
      (interactive)
      (when (eq nil last-search-char) (message "You haven't searched yet."))
      (search-direction-with-char last-search-direction last-search-char nil))

    (defun search-invert-with-char ()
      "前回と逆方向・同文字で検索"
      (interactive)
      (when (eq nil last-search-char) (message "You haven't searched yet."))
      (search-direction-with-char
       (cond
        ((eq last-search-direction 'forward) 'backward)
        ((eq last-search-direction 'backward) 'forward))
       last-search-char nil))

    (defun search-direction-with-char (direction char save)
      "与えられた方向に、与えられた文字を検索"
      (cond
       ((eq direction 'backward)
        (search-backward (char-to-string char) nil t))
       ((eq direction 'forward)
        (if (eq (char-after (point)) char) (forward-char))
        (and (search-forward (char-to-string char) nil t)
             (backward-char)))
       (t (error "search-direction-with-char: invalid direction")))
      (when save (setq last-search-direction direction
                       last-search-char char))))

  (leaf *modeline-ext
    :config
    (defun count-lines-and-chars ()
      "リージョン内の行・単語・文字数をカウントする。"
      (if mark-active
          (format "[%dL%dW%dC]"
                  (count-lines (region-beginning) (region-end))
                  (how-many "\\w+" (region-beginning) (region-end))
                  (- (region-end) (region-beginning)))
        "")))

  (leaf *region-ext
    :leaf-autoload nil
    :leaf-defer nil
    :bind ("C-@" . mark-inside-paren)
    :config
    (defun mark-inside-paren ()
      "括弧の中を選択する。"
      (interactive)
      (let ((is-repeat (eq last-command this-command)))
        (cond (is-repeat (forward-char)))
        (condition-case err
            (let* ((pair (inside-paren-range-at (point) 1))
                   (beg (car pair))
                   (end (cdr pair)))
              (cond (is-repeat (set-mark beg))
                    (t (push-mark beg nil t)))
              (goto-char end))
          (scan-error (backward-char))
          )))

    (defun inside-paren-range-at (point depth)
      "括弧の中の範囲を取得する。"
      (save-excursion
        (goto-char point)
        (let ((beg nil)
              (end nil))
          (backward-up-list depth t t)
          (setq beg (+ (point) 1))
          (forward-sexp)
          (setq end (- (point) 1))
          (cons beg end)))))

  (leaf *file-ext
    :doc "ファイル操作に関連する拡張"
    :config
    (defun revert-buffer-noconfirm (&optional revert-forcefully)
      "ファイルの再読み込みを行う。"
      (interactive "p")
      (cond ((or revert-forcefully (not (buffer-modified-p)))
             (revert-buffer t t))
            (t (error "Buffer has been modified; save or call with C-u.")))))

  (leaf *eval-ext
    :doc "評価に関する拡張"
    :leaf-autoload nil
    :leaf-defer nil
    :bind ("C-x C-S-e" . eval-and-replace)
    :config
    (defun eval-and-replace ()
      "直前の Emacs Lisp 式を評価して置換する。"
      (interactive)
      (backward-kill-sexp)
      (condition-case nil
          (prin1 (eval (read (current-kill 0)))
                 (current-buffer))
        (error (message "Invalid expression")
               (insert (current-kill 0))))))

  (leaf *junkfile
    :doc "一時ファイル"
    :leaf-autoload nil
    :leaf-defer nil
    :bind ("C-c C-t" . open-junk-file)
    :config
    (defun open-junk-file (ext)
      "特定の拡張子を持つ一時ファイルを開く。"
      (interactive "sExtension: ")
      (let ((path (make-tmp-file-path-having-extension ext)))
        (find-file path)))

    (defun workspace-path ()
      "ワークスペースのパスを取得する。"
      (replace-regexp-in-string "\n+$" "" (shell-command-to-string "workspace_path -d")))

    (defun make-tmp-file-path-having-extension (ext)
      "特定の拡張子を持つ一時ファイルのパスを生成する。"
      (let ((filename (format-time-string "junk%H-%M-%S")))
        (concat (workspace-path) "/" filename "." ext)))))

(leaf *plugins-general-improvements
  :config
  (leaf visual-regexp
    :ensure t
    :commands vr/query-replace
    :bind ("M-%" . vr/query-replace))

  (leaf highlight-indent-guides
    :ensure t
    :hook ((prog-mode-hook yaml-mode-hook) . highlight-indent-guides-mode)
    :custom
    ((highlight-indent-guides-auto-enabled . t)
     (highlight-indent-guides-responsive . t)
     (highlight-indent-guides-method . 'bitmap)))

  (leaf yasnippet
    :ensure t
    :global-minor-mode yas-global-mode
    :bind (("C-c y i" . yas-insert-snippet)
           ("C-c y n" . yas-new-snippet)
           ("C-c y v" . yas-visit-snippet-file))
    :setq (yas-snippet-dirs . '("~/.emacs.d/snippets")))

  (leaf quickrun
    :ensure t
    :commands (quickrun quickrun-with-arg quickrun-region)
    :bind ("C-c C-x" . quickrun-shell)
    :custom (quickrun-timeout-seconds . nil)
    :config
    (quickrun-add-command "c++/clang++17"
      '((:command . "clang++")
        (:exec . ("%c -std=c++17 -Weverything %o -o %e %s" "%e %a"))
        (:remove . ("%s" "%e"))))
    (quickrun-add-command "c++/clang++20"
      '((:command . "clang++")
        (:exec . ("%c -std=c++20 -Weverything %o -o %e %s" "%e %a"))
        (:remove . ("%s" "%e")))
      :default "c++")
    (quickrun-add-command "c++/g++17"
      '((:command . "g++")
        (:exec . ("%c -std=c++17 -Wall -Wextra %o -o %e %s" "%e %a"))
        (:remove . ("%s" "%e"))))
    (quickrun-add-command "c++/g++20"
      '((:command . "g++")
        (:exec . ("%c -std=c++20 -Wall -Wextra %o -o %e %s" "%e %a"))
        (:remove . ("%s" "%e"))))
    (quickrun-add-command "rust/rust-runner"
      '((:command . "rust-runner")
        (:remove . ("%s")))
      :default "rust"))

  (leaf neotree
    :doc "フォルダツリー表示"
    :ensure t
    :commands (neotree-toggle)
    :bind (("C-c C-n" . neotree-toggle))
    :setq
    ((neo-show-hidden-files . t)
     (neo-theme . 'icons)))

  (leaf multiple-cursors
    :doc "マルチカーソル"
    :ensure t
    :preface (global-unset-key "\C-t")
    :bind (("C-t C-n" . mc/mark-next-like-this)
           ("C-t C-p" . mc/mark-previous-like-this)
           ("C-t C-*" . mc/mark-all-like-this)
           ("C-S-l"   . mc/mark-all-like-this)
           ("C-M-c"   . mc/edit-lines)))

  (leaf which-key
    :doc "キーバインド記憶補助"
    :ensure t
    :global-minor-mode which-key-mode)

  (leaf amx
    :doc "M-x でのキーバインド表示"
    :ensure t)

  (leaf *ivy/counsel
    :doc "補完インターフェース"
    :config
    (leaf ivy
      :ensure t
      ;; :global-minor-mode ivy-mode
      :custom ((ivy-use-virtual-buffers . t)
               (ivy-height . 15)
               (ivy-extra-directories . nil)))

    (leaf flx
      :doc "ファジーファインダ"
      :ensure t
      :config
      (setq ivy-re-builders-alist '((swiper . ivy--regex-plus)
                                    (t . ivy--regex-fuzzy)))
      (setq ivy-initial-inputs-alist nil))

    (leaf ivy-rich
      :ensure t
      :global-minor-mode ivy-rich-mode
      :config
      (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line))

    (leaf counsel
      :ensure t
      :custom (counsel-find-file-ignore-regexp . (regexp-opt '("./" "../")))
      :bind (("M-x"     . counsel-M-x)
             ("C-x C-f" . counsel-find-file)
             ("C-x b"   . counsel-ibuffer)
             ("C-x C-b" . counsel-ibuffer)
             ("C-c C-f" . counsel-rg)))

    (leaf all-the-icons-ivy
      :ensure t
      :hook (after-init-hook . all-the-icons-ivy-setup)
      :setq (all-the-icons-ivy-file-commands . '(counsel-find-file
                                                 counsel-file-jump
                                                 counsel-recentf
                                                 counsel-ibuffer
                                                 counsel-projectile-find-file
                                                 counsel-projectile-find-dir)))

    (leaf swiper
      :doc "C-s 拡張"
      :ensure t
      :bind ("C-S-s" . swiper))))

(leaf *languages
  :config
  (leaf *general
    :config
    (leaf company
      :doc "補完機能"
      :ensure t
      :global-minor-mode global-company-mode
      :custom ((company-idle-delay . 0)             ; デフォルトは0.5
               (company-minimum-prefix-length . 2)  ; デフォルトは4
               (w32-pipe-read-delay . 0)            ; パイプを読む前に待たない
               (company-selection-wrap-around . t)) ; 候補の一番下でさらに下に行こうとすると一番上に戻る
      :bind ((company-active-map
              ("<tab>" . company-complete-selection)
              ("M-n" . company-select-next)
              ("M-p" . company-select-previous)
              ("C-n" . company-select-next)
              ("C-p" . company-select-previous)
              ("C-h" . nil)))
      :config
      (add-to-list 'company-backends '(company-yasnippet company-capf)))

    (leaf company-box
      :doc "補完候補にアイコンをつけるなど"
      :ensure t
      :hook (company-mode-hook . company-box-mode)
      :config
      (setq company-box-doc-enable t)
      (setq company-box-icons-alist 'company-box-icons-all-the-icons)
      (setq company-box-icons-all-the-icons
            (let ((all-the-icons-scale-factor 1.0)
                  (all-the-icons-default-adjust 0.0))
              `((Unknown       . ,(all-the-icons-faicon "question" :face 'all-the-icons-purple))
                (Text          . ,(all-the-icons-faicon "file-text-o" :face 'all-the-icons-green))
                (Method        . ,(all-the-icons-faicon "cube" :face 'all-the-icons-dcyan))
                (Function      . ,(all-the-icons-faicon "cube" :face 'all-the-icons-dcyan))
                (Constructor   . ,(all-the-icons-faicon "cube" :face 'all-the-icons-dcyan))
                (Field         . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Variable      . ,(all-the-icons-faicon "tag" :face 'all-the-icons-dpurple))
                (Class         . ,(all-the-icons-faicon "cog" :face 'all-the-icons-red))
                (Interface     . ,(all-the-icons-faicon "cogs" :face 'all-the-icons-red))
                (Module        . ,(all-the-icons-alltheicon "less" :face 'all-the-icons-red))
                (Property      . ,(all-the-icons-faicon "wrench" :face 'all-the-icons-red))
                (Unit          . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Value         . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Enum          . ,(all-the-icons-faicon "file-text-o" :face 'all-the-icons-red))
                (Keyword       . ,(all-the-icons-material "format_align_center" :face 'all-the-icons-red))
                (Snippet       . ,(all-the-icons-material "content_paste" :face 'all-the-icons-red))
                (Color         . ,(all-the-icons-material "palette" :face 'all-the-icons-red))
                (File          . ,(all-the-icons-faicon "file" :face 'all-the-icons-red))
                (Reference     . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Folder        . ,(all-the-icons-faicon "folder" :face 'all-the-icons-red))
                (EnumMember    . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Constant      . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (Struct        . ,(all-the-icons-faicon "cog" :face 'all-the-icons-red))
                (Event         . ,(all-the-icons-faicon "bolt" :face 'all-the-icons-red))
                (Operator      . ,(all-the-icons-faicon "tag" :face 'all-the-icons-red))
                (TypeParameter . ,(all-the-icons-faicon "cog" :face 'all-the-icons-red))
                (Template      . ,(all-the-icons-faicon "bookmark" :face 'all-the-icons-dgreen))))))

    (leaf lsp-mode
      :ensure t
      :custom ((lsp-auto-guess-root . t)
               (lsp-document-sync-method . 2) ; 常にインクリメンタルに送信する (lsp--sync-incremental)
               (lsp-enable-semantic-highlighting . nil)
               (lsp-semantic-highlighting-warn-on-missing-face . nil)
               (lsp-signature-doc-lines . 0))
      :hook ((c-mode-common-hook rust-mode-hook python-mode-hook) . lsp)
      :bind ((lsp-mode-map
              ("C-c l R" . lsp-rename))
             (lsp-signature-mode-map
              ("M-n" . lsp-signature-next)
              ("M-p" . lsp-signature-previous)))
      :config (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration))

    (leaf lsp-ui
      :ensure t
      :custom
      ;; lsp-ui-doc
      ((lsp-ui-doc-enable . t)
       (lsp-ui-doc-header . t)
       (lsp-ui-doc-include-signature . t)
       (lsp-ui-doc-position . 'top) ;; top, bottom, at-point
       (lsp-ui-doc-max-width . 150)
       (lsp-ui-doc-max-height . 30)
       (lsp-ui-doc-use-childframe . t)
       (lsp-ui-doc-use-webkit . t)
       ;; lsp-ui-flycheck
       (lsp-ui-flycheck-enable . nil)
       ;; lsp-ui-sideline
       (lsp-ui-sideline-enable . nil)
       (lsp-ui-sideline-ignore-duplicate . t)
       (lsp-ui-sideline-show-symbol . t)
       (lsp-ui-sideline-show-hover . t)
       (lsp-ui-sideline-show-diagnostics . nil)
       (lsp-ui-sideline-show-code-actions . nil)
       ;; lsp-ui-imenu
       (lsp-ui-imenu-enable . nil)
       (lsp-ui-imenu-kind-position . 'top)
       ;; lsp-ui-peek
       (lsp-ui-peek-enable . t)
       (lsp-ui-peek-peek-height . 20)
       (lsp-ui-peek-list-width . 50)
       (lsp-ui-peek-fontify . 'on-demand)) ;; never, on-demand, always
      :preface
      ;; 一応 doc を無効化できるように
      (defun toggle-lsp-ui-doc ()
        (interactive)
        (if lsp-ui-doc-mode
            (progn
              (lsp-ui-doc-mode -1)
              (lsp-ui-doc--hide-frame))
          (lsp-ui-doc-mode 1)))
      :bind (lsp-mode-map
             ("C-c l r" . lsp-ui-peek-find-references)
             ("C-c l p" . lsp-ui-peek-find-definitions)
             ("C-c l i" . lsp-ui-peek-find-implementation)
             ("C-c l m" . lsp-ui-imenu)
             ("C-c l s" . lsp-ui-sideline-mode)
             ("C-c l d" . toggle-lsp-ui-doc))
      :hook lsp-mode-hook)

    (leaf lsp-ivy
      :ensure t
      :commands lsp-ivy-workspace-symbol)

    (leaf dap-mode
      :ensure t
      :custom (dap-print-io . t)))

  (leaf *c/c++
    :config
    (leaf cc-mode
      :doc "C family の言語サポート"
      :tag "builtin"
      :defvar (c-basic-offset)
      :hook ((c-mode-hook . c/c++-config)
             (c++-mode-hook . c/c++-config))
      :config
      ;; (leaf dap-cpptools
      ;;   :require t
      ;;   :config
      ;;   ;; VSCode のデバッガと同等のものを設定できるようにする
      ;;   ;; (dap-register-debug-provider
      ;;   ;;  "cppvsdbg"
      ;;   ;;  (lambda (conf)
      ;;   ;;    (plist-put conf
      ;;   ;;               :dap-server-path
      ;;   ;;               `(,(expand-file-name "~/.vscode/extensions/ms-vscode.cpptools-1.1.3/debugAdapters/vsdbg/bin/vsdbg.exe" "--interpreter=vscode")))
      ;;   ;;    conf))
      ;;   ;; (dap-register-debug-template "C++ :: Run Configuration"
      ;;   ;;                              (list :type "cppvsdbg"
      ;;   ;;                                    :request "launch"
      ;;   ;;                                    :program "${fileDirname}/${fileBasenameNoExtension}.exe"
      ;;   ;;                                    :cwd "${fileDirname}"
      ;;   ;;                                    :name "Run Configuration"))
      ;;   (dap-register-debug-template
      ;;    "C++ :: Run Configuration"
      ;;    (list :type "cppdbg"
      ;;          :request "launch"
      ;;          :name "Run Configuration"
      ;;          :MIMode "lldb"
      ;;          :MIDebuggerPath "C:/Program Files/LLVM/bin/lldb.exe"
      ;;          :program "${fileDirname}/${fileBasenameNoExtension}.exe"
      ;;          :cwd "${fileDirname}"))
      ;;   (dap-cpptools-setup))
      ;; 動かない...
      (leaf dap-lldb :require t
        :custom (dap-lldb-debug-program . '("C:/Program Files/LLVM/bin/lldb-vscode.exe")))
      (defun c/c++-config ()
        (setq c-basic-offset 4)
        (local-unset-key (kbd "C-c C-n")))
      ))

  (leaf *rust
    :config
    (leaf rust-mode
      :doc "Rust の言語サポート"
      :ensure t
      :hook (rust-mode-hook . rust-config)
      :custom-face
      ((lsp-face-semhl-enumMember . '((t :inherit lsp-face-semhl-constant)))
       (lsp-face-semhl-attribute . '((t :inherit lsp-face-semhl-macro)))
       (lsp-face-semhl-boolean . '((t :inherit lsp-face-semhl-constant)))
       (lsp-face-semhl-builtinType . '((t :inherit lsp-face-semhl-type)))
       (lsp-face-semhl-escapeSequence . '((t :inherit lsp-face-semhl-string)))
       (lsp-face-semhl-formatSpecifier . '((t :inherit lsp-face-semhl-string)))
       (lsp-face-semhl-generic . '((t :inherit lsp-face-semhl-type-parameter)))
       (lsp-face-semhl-lifetime . '((t :inherit lsp-face-semhl-label)))
       (lsp-face-semhl-punctuation . '((t :inherit lsp-face-semhl-operator)))
       (lsp-face-semhl-selfKeyword . '((t :inherit lsp-face-semhl-keyword)))
       (lsp-face-semhl-typeAlias . '((t :inherit lsp-face-semhl-type)))
       (lsp-face-semhl-union . '((t :inherit lsp-face-semhl-struct)))
       (lsp-face-semhl-unresolvedReference . '((t :inherit lsp-face-semhl-comment)))
       (lsp-face-semhl-documentation . '((t :inherit lsp-face-semhl-comment :weight bold)))
       )
      :config
      (setq lsp-rust-analyzer-server-command '("rust-analyzer-windows"))
      (defun rust-config ()
        (local-unset-key (kbd "C-c C-f"))
        (setq-local lsp-semantic-token-faces
                    '(("comment" . lsp-face-semhl-comment)
                      ("keyword" . lsp-face-semhl-keyword)
                      ("string" . lsp-face-semhl-string)
                      ("number" . lsp-face-semhl-number)
                      ("regexp" . lsp-face-semhl-regexp)
                      ("operator" . lsp-face-semhl-operator)
                      ("namespace" . lsp-face-semhl-namespace)
                      ("type" . lsp-face-semhl-type)
                      ("struct" . lsp-face-semhl-struct)
                      ("class" . lsp-face-semhl-class)
                      ("interface" . lsp-face-semhl-interface)
                      ("enum" . lsp-face-semhl-enum)
                      ("enumMember" . lsp-face-semhl-enumMember)
                      ("typeParameter" . lsp-face-semhl-typeParameter)
                      ("function" . lsp-face-semhl-function)
                      ("method" . lsp-face-semhl-method)
                      ("property" . lsp-face-semhl-property)
                      ("macro" . lsp-face-semhl-macro)
                      ("variable" . lsp-face-semhl-variable)
                      ("parameter" . lsp-face-semhl-parameter)
                      ("attribute" . lsp-face-semhl-attribute)
                      ("boolean" . lsp-face-semhl-boolean)
                      ("builtinType" . lsp-face-semhl-builtinType)
                      ("escapeSequence" . lsp-face-semhl-escapeSequence)
                      ("formatSpecifier" . lsp-face-semhl-formatSpecifier)
                      ("generic" . lsp-face-semhl-generic)
                      ("lifetime" . lsp-face-semhl-lifetime)
                      ("punctuation" . lsp-face-semhl-punctuation)
                      ("selfKeyword" . lsp-face-semhl-selfKeyword)
                      ("typeAlias" . lsp-face-semhl-typeAlias)
                      ("union" . lsp-face-semhl-union)
                      ("unresolvedReference" . lsp-face-semhl-unresolvedReference)))
        (setq-local lsp-semantic-token-modifier-faces
                    '(("documentation" . lsp-face-semhl-documentation)
                      ("declaration" . lsp-face-semhl-constant)
                      ("definition" . lsp-face-semhl-constant)
                      ("static" . lsp-face-semhl-constant)
                      ("abstract" . lsp-face-semhl-constant)
                      ("deprecated" . lsp-face-semhl-constant)
                      ("readonly" . lsp-face-semhl-constant)
                      ("constant" . lsp-face-semhl-constant)
                      ("controlFlow" . lsp-face-semhl-constant)
                      ("injected" . lsp-face-semhl-constant)
                      ("mutable" . lsp-face-semhl-constant)
                      ("consuming" . lsp-face-semhl-constant)
                      ("unsafe" . lsp-face-semhl-constant)
                      ("attribute" . lsp-face-semhl-constant)
                      ("callable" . lsp-face-semhl-constant))))))

  (leaf *python
    :custom
    ((lsp-pyls-plugins-pylint-enabled . t)
     (lsp-pyls-plugins-pyflakes-enabled . nil)
     (lsp-pyls-plugins-flake8-enabled . nil)
     (lsp-pyls-plugins-pycodestyle-enabled . nil)
     (lsp-pyls-plugins-pydocstyle-enabled . nil)
     (lsp-pyls-plugins-yapf-enabled . nil)
     (lsp-pyls-plugins-autopep8-enabled . nil)
     (lsp-pyls-plugins-black-enabled . t)
     (lsp-pyls-plugins-isort-enabled . t))
    :config
    (leaf dap-python
      :require t
      :custom (dap-python-debugger . 'debugpy)))

  (leaf *latex
    :config
    (leaf latex-math-preview
      :doc "LaTeX の数式プレビュー"
      :ensure t
      :setq
      (latex-math-preview-command-path-alist . ((latex . "uplatex.exe")

                                                (dvipng . "dvipng.exe")
                                                (dvips . "dvips.exe"))))))

(leaf *gui
  :config
  (leaf doom-themes
    :doc "テーマ"
    :ensure t
    :custom ((doom-themes-enable-italic . t)
             (doom-themes-enable-bold . t))
    :config
    (load-theme 'doom-tomorrow-night t)
    ;; (doom-themes-neotree-config)
    ;; (doom-themes-org-config)
    )

  (leaf doom-modeline
    :doc "モードライン"
    :ensure t
    :custom '((doom-modeline-buffer-file-name-style . 'truncate-with-project)
              (doom-modeline-icon . t)
              (doom-modeline-major-mode-icon . t)
              (doom-modeline-enable-word-count . t)
              (doom-modeline-buffer-encoding . t)
              (doom-modeline-indent-info . t)
              (doom-modeline-minor-modes . nil)
              (doom-modeline-height . 40))
    :global-minor-mode doom-modeline-mode
    :config
    (line-number-mode 1)
    (column-number-mode 1)
    (doom-modeline-def-modeline
      'main
      '(bar window-number matches buffer-info remote-host buffer-position parrot selection-info)
      '(misc-info persp-name lsp github debug minor-modes buffer-encoding major-mode process vcs checker)))

  (leaf hide-mode-line
    :doc "不要な場所でモードラインを非表示"
    :ensure t
    :hook ((neotree-mode) . hide-mode-line-mode))

  (leaf all-the-icons
    :doc "アイコン表示"
    :ensure t)

  (leaf *font
    :doc "フォント設定"
    :setq-default (line-spacing . 0)
    :config
    (defun do-font-settings (frame)
      (when window-system                   ; Window System が存在するときのみ
        (let* ((en-font "Consolas")
               (jp-font "MeiryoKe_Gothic")
               (en-size 16)
               (jp-size 16)
               ;; この下は変更の必要はなかろう
               (en-fontspec (font-spec :family en-font :size en-size))
               (jp-fontspec (font-spec :family jp-font :size jp-size)))
          (set-face-attribute 'default frame :font en-fontspec)
          (set-fontset-font nil 'japanese-jisx0213.2004-1 jp-fontspec frame)
          (set-fontset-font nil 'japanese-jisx0213-2      jp-fontspec frame)
          (set-fontset-font nil 'katakana-jisx0201        jp-fontspec frame) ; 半角カナ
          (set-fontset-font nil '(#x0080 . #x024F)        en-fontspec frame) ; 分音符付きラテン
          (set-fontset-font nil '(#x0370 . #x03FF)        en-fontspec frame) ; ギリシャ文字
          (set-fontset-font nil '(#x2160 . #x2183)        jp-fontspec frame) ; ローマ数字
          (set-fontset-font nil '#xFF45E                  jp-fontspec frame) ; '〜'
          )))
    (add-hook 'after-make-frame-functions #'do-font-settings)
    (do-font-settings nil)))

(provide 'init)

;; "package cl is deprecated" 対策
;; Local Variables:
;; byte-compile-warnings: (not cl-functions obsolete)
;; End:
