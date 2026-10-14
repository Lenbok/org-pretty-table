;; -*- lexical-binding: t -*-

(require 'buttercup)
(require 'org-pretty-table)

(defun opt-assert-display (expected)
  (string-match-p expected (get-text-property (point) 'display)))

(defun opt-search-and-backward (str)
  (re-search-forward str)
  (backward-char 1))

(defun opt-faces-at (pos)
  "Return the `face' at POS as a list."
  (let ((f (get-text-property pos 'face))) (if (listp f) f (list f))))

(defun opt-face-p (pos face)
  (and (memq face (opt-faces-at pos)) t))

(defun opt-goto (str)
  "Go to the start of the first STR in the buffer; return that position."
  (goto-char (point-min))
  (search-forward str)
  (goto-char (match-beginning 0))
  (point))

(defun opt-refontify ()
  (font-lock-flush)
  (font-lock-ensure)
  ;; `jit-lock-fontify-now' fails when no jit-lock function is registered,
  ;; which is the case in a temp buffer once the mode is off.
  (when jit-lock-functions
    (jit-lock-refontify)
    (jit-lock-fontify-now)))

(defun opt-glyphs ()
  "Return the buffer's lines with `display' strings substituted, as a list."
  (save-excursion
    (goto-char (point-min))
    (let (lines)
      (while (not (eobp))
        (let ((line ""))
          (while (not (or (eolp) (eobp)))
            (setq line (concat line (or (get-text-property (point) 'display)
                                        (string (char-after)))))
            (forward-char 1))
          (push line lines))
        (forward-line 1))
      (nreverse lines))))

(defmacro with-org-text (text &rest body)
  "Insert TEXT in an Org buffer, enable the mode, fontify, run BODY."
  (declare (indent 1))
  `(with-temp-buffer
     (org-mode)
     (insert ,text)
     (org-pretty-table-mode 1)
     (font-lock-mode 1)
     (opt-refontify)
     ,@body))

(defmacro with-org-table (&rest body)
  (declare (indent 0))
  (let ((prefix (plist-get body :prefix))
        (suffix (plist-get body :suffix)))
    `(with-temp-buffer
       (org-mode)
       (insert "|------+-----|
| name | age |
|------+-----|
| bob  |  10 |
|------+-----|")
       (when ,prefix
         (goto-char (point-min))
         (insert ,prefix))
       (when ,suffix
         (goto-char (point-max))
         (insert ,suffix))

       (org-pretty-table-mode 1)
       (font-lock-mode 1)
       (font-lock-ensure)
       (jit-lock-refontify)
       (jit-lock-fontify-now)
       ,@body)))

(describe "org-pretty-table"

  (before-each
    (setq org-pretty-table-charset "┌┐└┘┬┤┴├┼─│"))

  (describe "horizontal bar"

    (it "should not prettify segments not ending in + or |"
      (with-org-table
        :prefix "|------+-----|\n| ---- | --- |\n"
        (goto-char (point-min))
        (forward-line 1)
        (re-search-forward "----")
        (backward-char 4)
        (expect (get-text-property (point) 'display) :to-be nil))))

  (describe "top row"

    (describe "at beginning of buffer"

      (it "should prettify up-left corner"
        (with-org-table
          (goto-char (point-min))
          (expect (opt-assert-display "┌") :to-be-truthy)))

      (it "should prettify up-right corner"
        (with-org-table
          (goto-char (point-min))
          (end-of-line)
          (backward-char 1)
          (expect (opt-assert-display "┐") :to-be-truthy)))

      (it "should prettify down facing T"
        (with-org-table
          (goto-char (point-min))
          (opt-search-and-backward "+")
          (expect (opt-assert-display "┬") :to-be-truthy))))

    (describe "with empty line above"

      (it "should prettify up-left corner"
        (with-org-table
          :prefix "hello world \n\n"
          (goto-char (point-min))
          (opt-search-and-backward "|")
          (expect (opt-assert-display "┌") :to-be-truthy)))

      (it "should prettify up-right corner"
        (with-org-table
          :prefix "hello world \n\n"
          (goto-char (point-min))
          (re-search-forward "+")
          (end-of-line)
          (backward-char 1)
          (expect (opt-assert-display "┐") :to-be-truthy)))

      (it "should prettify down facing T"
        (with-org-table
          :prefix "hello world \n\n"
          (goto-char (point-min))
          (opt-search-and-backward "+")
          (expect (opt-assert-display "┬") :to-be-truthy))))

    (describe "with content line above"

      (it "should prettify up-left corner"
        (with-org-table
          :prefix "** headline\n"
          (goto-char (point-min))
          (opt-search-and-backward "|")
          (expect (opt-assert-display "┌") :to-be-truthy)))

      (it "should prettify up-right corner"
        (with-org-table
          :prefix "** headline\n"
          (goto-char (point-min))
          (re-search-forward "+")
          (end-of-line)
          (backward-char 1)
          (expect (opt-assert-display "┐") :to-be-truthy)))

      (it "should prettify down facing T"
        (with-org-table
          :prefix "** headline\n"
          (goto-char (point-min))
          (opt-search-and-backward "+")
          (expect (opt-assert-display "┬") :to-be-truthy)))))

  (describe "middle row"

    (it "should prettify left facing T"
      (with-org-table
        (goto-char (point-min))
        (re-search-forward "age")
        (forward-line 1)
        (end-of-line)
        (backward-char 1)
        (expect (opt-assert-display "┤") :to-be-truthy)))

    (it "should prettify right facing T"
      (with-org-table
        (goto-char (point-min))
        (re-search-forward "age")
        (forward-line 1)
        (beginning-of-line)
        (expect (opt-assert-display "├") :to-be-truthy)))

    (it "should prettify cross"
      (with-org-table
        (goto-char (point-min))
        (re-search-forward "+")
        (opt-search-and-backward "+")
        (expect (opt-assert-display "┼") :to-be-truthy))))

  (describe "bottom row"

    (describe "at the end of buffer"

      (it "should render bottom left corner"
        (with-org-table
          (goto-char (point-max))
          (re-search-backward "|")
          (beginning-of-line)
          (expect (opt-assert-display "└") :to-be-truthy)))

      (it "should render bottom right corner"
        (with-org-table
          (goto-char (point-max))
          (re-search-backward "|")
          (expect (opt-assert-display "┘") :to-be-truthy)))

      (it "should render up facing T"
        (with-org-table
          (goto-char (point-max))
          (re-search-backward "+")
          (expect (opt-assert-display "┴") :to-be-truthy))))

    (describe "with empty line below"

      (it "should render bottom left corner"
        (with-org-table
          :suffix "\n\nhello"
          (goto-char (point-max))
          (re-search-backward "|")
          (beginning-of-line)
          (expect (opt-assert-display "└") :to-be-truthy)))

      (it "should render bottom right corner"
        (with-org-table
          :suffix "\n\nhello"
          (goto-char (point-max))
          (re-search-backward "|")
          (expect (opt-assert-display "┘") :to-be-truthy)))

      (it "should render up facing T"
        (with-org-table
          :suffix "\n\nhello"
          (goto-char (point-max))
          (re-search-backward "+")
          (expect (opt-assert-display "┴") :to-be-truthy))))

    (describe "with content line below"

      (it "should render bottom left corner"
        (with-org-table
          :suffix "\n** headline\n"
          (goto-char (point-max))
          (re-search-backward "|")
          (beginning-of-line)
          (expect (opt-assert-display "└") :to-be-truthy)))

      (it "should render bottom right corner"
        (with-org-table
          :suffix "\n** headline\n"
          (goto-char (point-max))
          (re-search-backward "|")
          (expect (opt-assert-display "┘") :to-be-truthy)))

      (it "should render up facing T"
        (with-org-table
          :suffix "\n** headline\n"
          (goto-char (point-max))
          (re-search-backward "+")
          (expect (opt-assert-display "┴") :to-be-truthy)))))

  (describe "faces"

    (it "defines the four faces with the expected inheritance"
      (expect (face-attribute 'org-pretty-table :inherit nil t) :to-be 'org-table)
      (expect (face-attribute 'org-pretty-table-header :inherit nil t) :to-be 'org-pretty-table)
      (expect (face-attribute 'org-pretty-table-header :weight nil t) :to-be 'bold)
      (expect (face-attribute 'org-pretty-table-border :inherit nil t)
              :to-equal '(shadow org-pretty-table))
      (expect (face-attribute 'org-pretty-table-zebra :inherit nil t)
              :to-equal '(hl-line org-pretty-table)))

    (it "gives hline characters the border face first"
      (with-org-text "|---+---|\n| a | b |\n|---+---|"
        (dolist (pos '(1 5 9))
          (expect (opt-face-p pos 'org-pretty-table-border) :to-be-truthy)
          (expect (car (opt-faces-at pos)) :to-be 'org-pretty-table-border))))

    (it "gives data-row pipes the border face"
      (with-org-text "|---+---|\n| a | b |\n|---+---|"
        (let ((pos (opt-goto "| a")))
          (expect (opt-face-p pos 'org-pretty-table-border) :to-be-truthy))
        (goto-char (point-min))
        (forward-line 1)
        (end-of-line)
        (expect (opt-face-p (1- (point)) 'org-pretty-table-border) :to-be-truthy)))

    (it "leaves cell text without the border face"
      (with-org-text "|---+---|\n| a | b |\n|---+---|"
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-border) :to-be nil)))

    (it "does not style pipes outside tables"
      (with-org-text "#+begin_src text\n| not a table\n#+end_src\n"
        (expect (opt-face-p (opt-goto "| not") 'org-pretty-table-border) :to-be nil))))

  (describe "header rows"

    (it "styles header cells and padding, but not borders"
      (with-org-text "|---+---|\n| name | age |\n|---+---|\n| bob | 10 |\n|---+---|"
        (let ((name (opt-goto "name")))
          (expect (opt-face-p name 'org-pretty-table-header) :to-be-truthy)
          (expect (opt-face-p (+ name 4) 'org-pretty-table-header) :to-be-truthy)
          (expect (opt-face-p (1- name) 'org-pretty-table-header) :to-be-truthy)
          (expect (opt-face-p (- name 2) 'org-pretty-table-header) :to-be nil)
          (expect (opt-face-p (- name 2) 'org-pretty-table-border) :to-be-truthy))))

    (it "gives data cells the base face only"
      (with-org-text "|---+---|\n| name | age |\n|---+---|\n| bob | 10 |\n|---+---|"
        (let ((bob (opt-goto "bob")))
          (expect (opt-face-p bob 'org-pretty-table) :to-be-truthy)
          (expect (opt-face-p bob 'org-pretty-table-header) :to-be nil)
          (expect (opt-face-p (- bob 2) 'org-pretty-table-border) :to-be-truthy))))

    (it "treats rows above the first hline as header without a leading hline"
      (with-org-text "| h |\n|---|\n| a |"
        (expect (opt-face-p (opt-goto "h") 'org-pretty-table-header) :to-be-truthy)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-header) :to-be nil)))

    (it "has no header when the table has no hline"
      (with-org-text "| a | b |\n| c | d |"
        (dotimes (i (buffer-size))
          (expect (opt-face-p (1+ i) 'org-pretty-table-header) :to-be nil))))

    (it "only treats the first group as header"
      (with-org-text "| a |\n|---|\n| b |\n|---|\n| c |"
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-header) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-header) :to-be nil)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-header) :to-be nil)))

    (it "keeps inline Org faces alongside the row face"
      (with-org-text "| *bold* |\n|---|\n| x |"
        (let ((pos (opt-goto "bold")))
          (expect (opt-face-p pos 'bold) :to-be-truthy)
          (expect (opt-face-p pos 'org-pretty-table-header) :to-be-truthy)))))

  (describe "org-table face"

    (it "is not left in front of our faces, so remapping it cannot override them"
      (with-org-text "|---+---|\n| name | age |\n|---+---|\n| bob | 10 |\n|---+---|"
        (dotimes (i (buffer-size))
          (unless (eq (char-after (1+ i)) ?\n)
            (expect (opt-face-p (1+ i) 'org-table) :to-be nil)
            (expect (opt-face-p (1+ i) 'org-table-row) :to-be nil)))
        (expect (car (opt-faces-at (opt-goto "name"))) :to-be 'org-pretty-table-header))))

  (describe "zebra"

    (defconst opt-zebra-text
      "| h1 | h2 |\n|----+----|\n| a  | 1  |\n| b  | 2  |\n| c  | 3  |\n| d  | 4  |")

    (it "stripes every second data row, starting with the second"
      (with-org-text opt-zebra-text
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be-truthy)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "d") 'org-pretty-table-zebra) :to-be-truthy)))

    (it "shades padding but not borders"
      (with-org-text opt-zebra-text
        (let ((b (opt-goto "b")))
          (expect (opt-face-p (1+ b) 'org-pretty-table-zebra) :to-be-truthy)
          (expect (opt-face-p (1- b) 'org-pretty-table-zebra) :to-be-truthy)
          (expect (opt-face-p (- b 2) 'org-pretty-table-zebra) :to-be nil)
          (expect (opt-face-p (- b 2) 'org-pretty-table-border) :to-be-truthy))))

    (it "never stripes header or hline rows"
      (with-org-text opt-zebra-text
        (dolist (pos (list (opt-goto "h1") (opt-goto "----")))
          (expect (opt-face-p pos 'org-pretty-table-zebra) :to-be nil))))

    (it "is off when the option is nil"
      (let ((org-pretty-table-zebra-stripe nil))
        (with-org-text opt-zebra-text
          (dotimes (i (buffer-size))
            (expect (opt-face-p (1+ i) 'org-pretty-table-zebra) :to-be nil)))))

    (it "stripes tables without a header too"
      (with-org-text "| a |\n| b |\n| c |"
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be-truthy)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-zebra) :to-be nil)))

    (it "gets parity right when fontifying a region that starts mid-table"
      (with-org-text opt-zebra-text
        (font-lock-unfontify-buffer)
        (font-lock-fontify-region (progn (opt-goto "c") (line-beginning-position))
                                  (point-max))
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table) :to-be-truthy)
        (expect (opt-face-p (opt-goto "d") 'org-pretty-table-zebra) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table) :to-be nil)))

    (it "updates open buffers when the option is set"
      (with-org-text opt-zebra-text
        (unwind-protect
            (progn
              (customize-set-variable 'org-pretty-table-zebra-stripe nil)
              (font-lock-ensure)
              (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be nil))
          (customize-set-variable 'org-pretty-table-zebra-stripe t)))))

  (describe "row cache"

    (defconst opt-cache-text
      "| h |\n|---|\n| a |\n| b |\n| c |\n| d |")

    (before-each
      (spy-on 'org-pretty-table--compute-rows :and-call-through))

    (it "computes each table once while the buffer text is unchanged"
      (with-org-text opt-cache-text
        (opt-refontify)
        (opt-refontify)
        (expect 'org-pretty-table--compute-rows :to-have-been-called-times 1)))

    (it "recomputes after the text changes"
      (with-org-text opt-cache-text
        (goto-char (point-max))
        (insert "x")
        (opt-refontify)
        (expect (spy-calls-count 'org-pretty-table--compute-rows) :to-be-greater-than 1)))

    (it "keeps parity correct after inserting a data row above"
      (with-org-text opt-cache-text
        (opt-goto "| b")
        (insert "| new |\n")
        (opt-refontify)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "new") 'org-pretty-table-zebra) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-zebra) :to-be-truthy)))

    (it "keeps parity correct after deleting a data row"
      (with-org-text opt-cache-text
        (opt-goto "| a")
        (delete-region (line-beginning-position) (1+ (line-end-position)))
        (opt-refontify)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "c") 'org-pretty-table-zebra) :to-be-truthy)))

    (it "keeps parity correct after editing text above the table"
      (with-org-text (concat "intro\n\n" opt-cache-text)
        (goto-char (point-min))
        (insert "more intro ")
        (opt-refontify)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-zebra) :to-be nil)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be-truthy)))

    (it "is empty after the mode is turned off"
      (with-org-text opt-cache-text
        (expect org-pretty-table--cache :not :to-be nil)
        (org-pretty-table-mode -1)
        (expect org-pretty-table--cache :to-be nil)))

    (it "is cleared when the zebra option is set"
      (with-org-text opt-cache-text
        (unwind-protect
            (progn
              (customize-set-variable 'org-pretty-table-zebra-stripe nil)
              (expect org-pretty-table--cache :to-be nil))
          (customize-set-variable 'org-pretty-table-zebra-stripe t)))))

  (describe "disabling"

    (defconst opt-disable-text
      "| h |\n|---|\n| a |\n| b |\n| c |")

    (defun opt-any-face-p (faces)
      (let (found)
        (dotimes (i (buffer-size))
          (dolist (f faces)
            (when (opt-face-p (1+ i) f) (setq found t))))
        found))

    (it "removes this package's faces and display strings, keeping Org's"
      (with-org-text opt-disable-text
        (expect (opt-any-face-p '(org-pretty-table org-pretty-table-header
                                  org-pretty-table-border org-pretty-table-zebra))
                :to-be-truthy)
        (org-pretty-table-mode -1)
        (opt-refontify)
        (expect (opt-any-face-p '(org-pretty-table org-pretty-table-header
                                  org-pretty-table-border org-pretty-table-zebra))
                :to-be nil)
        (expect (opt-face-p (opt-goto "|") 'org-table) :to-be-truthy)
        (dotimes (i (buffer-size))
          (expect (get-text-property (1+ i) 'display) :to-be nil))))

    (it "removes the font-lock keyword"
      (with-org-text opt-disable-text
        (expect (assoc 'org-pretty-table--matcher font-lock-keywords) :to-be-truthy)
        (org-pretty-table-mode -1)
        (expect (assoc 'org-pretty-table--matcher font-lock-keywords) :to-be nil)))

    (it "brings faces and display strings back when re-enabled"
      (with-org-text opt-disable-text
        (org-pretty-table-mode -1)
        (opt-refontify)
        (org-pretty-table-mode 1)
        (opt-refontify)
        (expect (opt-face-p (opt-goto "|") 'org-pretty-table-border) :to-be-truthy)
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be-truthy))))

  (describe "alignment"

    (it "keeps faces and display strings after org-table-align"
      (with-org-text "| a | bb |\n|-\n| ccc | d |\n| e | f |"
        (goto-char (point-min))
        (org-table-align)
        (opt-refontify)
        (expect org-pretty-table-mode :to-be-truthy)
        (expect (opt-face-p (opt-goto "|") 'org-pretty-table-border) :to-be-truthy)
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-header) :to-be-truthy)
        (expect (opt-face-p (opt-goto "f") 'org-pretty-table-zebra) :to-be-truthy))))

  (describe "custom charset"

    (it "still gives border faces to the replaced characters"
      (setq org-pretty-table-charset "╒╕╘╛╤╡╧╞╪═│")
      (with-org-table
        (goto-char (point-min))
        (expect (opt-assert-display "╒") :to-be-truthy)
        (expect (opt-face-p (point) 'org-pretty-table-border) :to-be-truthy))))

  (describe "base face"

    (it "is on every table character, last, even for header, zebra and borders"
      (with-org-text "| h |\n|---|\n| a |\n| b |"
        (dotimes (i (buffer-size))
          (unless (eq (char-after (1+ i)) ?\n)
            (expect (car (last (opt-faces-at (1+ i)))) :to-be 'org-pretty-table)))))

    (it "still supplies the face when a derived face is re-parented"
      (with-org-text "| h |\n|---|\n| a |\n| b |"
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table-zebra) :to-be-truthy)
        (expect (opt-face-p (opt-goto "b") 'org-pretty-table) :to-be-truthy)
        (expect (opt-face-p (opt-goto "h") 'org-pretty-table) :to-be-truthy)
        (expect (opt-face-p (1- (opt-goto "b")) 'org-pretty-table) :to-be-truthy))))

  (describe "turn-on-org-pretty-table-mode"

    (it "enables the mode in a normal buffer"
      (let ((buffer (generate-new-buffer "opt-visible")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (turn-on-org-pretty-table-mode)
              (expect org-pretty-table-mode :to-be-truthy))
          (kill-buffer buffer))))

    (it "skips hidden buffers such as Org's source fontification buffers"
      (let ((buffer (generate-new-buffer " *org-src-fontification:org-mode*")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (turn-on-org-pretty-table-mode)
              (expect org-pretty-table-mode :to-be nil)
              (expect (assoc 'org-pretty-table--matcher font-lock-keywords) :to-be nil))
          (kill-buffer buffer))))

    (it "does not style a table inside a src org block through native fontification"
      (let ((buffer (generate-new-buffer "opt-src")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (insert "#+begin_src org\n| a | b |\n|---+---|\n| c | d |\n#+end_src\n")
              (global-org-pretty-table-mode 1)
              (unwind-protect
                  (progn
                    (org-pretty-table-mode 1)
                    (opt-refontify)
                    (expect (opt-face-p (opt-goto "| a") 'org-pretty-table-border) :to-be nil))
                (global-org-pretty-table-mode -1)))
          (kill-buffer buffer)))))

  (describe "jit-lock ordering"

    (defun opt-register-font-lock ()
      "Register `font-lock-fontify-region' like `jit-lock-mode' does."
      (font-lock-mode 1)
      (jit-lock-register 'font-lock-fontify-region))

    (it "runs after font-lock when the mode is enabled after font-lock"
      (let ((buffer (generate-new-buffer "opt-order")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (insert "| a | b |\n|---+---|\n| c | d |")
              (opt-register-font-lock)
              (org-pretty-table-mode 1)
              (let ((fns (remq t jit-lock-functions)))
                (expect (car (last fns)) :to-be 'org-pretty-table-propertize-region)
                (expect (memq 'font-lock-fontify-region fns) :to-be-truthy)
                (expect (< (seq-position fns 'font-lock-fontify-region)
                           (seq-position fns 'org-pretty-table-propertize-region))
                        :to-be-truthy)))
          (kill-buffer buffer))))

    (it "keeps display strings when display is a font-lock managed property"
      (let ((buffer (generate-new-buffer "opt-managed")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (insert "| a | b |\n|---+---|\n| c | d |")
              (opt-register-font-lock)
              (setq-local font-lock-extra-managed-props
                          (cons 'display font-lock-extra-managed-props))
              (org-pretty-table-mode 1)
              (opt-refontify)
              (opt-refontify)
              (expect (get-text-property (opt-goto "|---") 'display) :to-be-truthy)
              (goto-char (point-min))
              (expect (get-text-property (point) 'display) :to-be-truthy))
          (kill-buffer buffer)))))

  (describe "table starting on the first line of the buffer (issue 13)"

    (defconst opt-issue-13-text
      "| panel_id | gs_use | species_id |\n|----------+--------+------------|\n|        1 | false  |          1 |\n|        2 | false  |          1 |")

    (it "renders the header divider with left and right T and crosses"
      (with-org-text opt-issue-13-text
        (goto-char (point-min))
        (forward-line 1)
        (expect (opt-assert-display "├") :to-be-truthy)
        (end-of-line)
        (backward-char 1)
        (expect (opt-assert-display "┤") :to-be-truthy)
        (goto-char (point-min))
        (forward-line 1)
        (search-forward "+")
        (backward-char 1)
        (expect (opt-assert-display "┼") :to-be-truthy)))

    (it "renders the same as when a blank line precedes the table"
      (let (without with)
        (with-org-text opt-issue-13-text
          (setq without (opt-glyphs)))
        (with-org-text (concat "\n" opt-issue-13-text)
          (setq with (opt-glyphs)))
        (expect without :to-equal (cdr with))))

    (it "renders a two-row table (data row, then hline) at the top"
      (with-org-text "| a | b |\n|---+---|"
        (goto-char (point-min))
        (forward-line 1)
        (expect (opt-assert-display "└") :to-be-truthy)))

    (it "renders a header divider on line two with a table row after it"
      (with-org-text "| a | b |\n|---+---|\n| c | d |"
        (goto-char (point-min))
        (forward-line 1)
        (expect (opt-assert-display "├") :to-be-truthy))))

  (describe "org-table-align advice"

    (defun opt-align-in-buffer-without-mode ()
      "Align a table in a visible buffer where the mode is off.
Return a list of the mode state before and after, and whether the advice
is still installed."
      (let ((buffer (generate-new-buffer "opt-no-mode")) result)
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (insert "| a | bb |\n|---+----|\n| ccc | d |\n")
              (org-pretty-table-mode -1)
              (advice-add 'org-table-align :around #'org-pretty-table-align)
              (goto-char (point-min))
              (let ((before org-pretty-table-mode))
                (org-table-align)
                (setq result (list before org-pretty-table-mode
                                   (and (advice-member-p #'org-pretty-table-align
                                                         'org-table-align)
                                        t)))))
          (advice-remove 'org-table-align #'org-pretty-table-align)
          (kill-buffer buffer))
        result))

    (it "does not turn the mode on in a buffer where it is off"
      (expect (nth 1 (opt-align-in-buffer-without-mode)) :to-be nil))

    (it "leaves the advice installed for buffers that use the mode"
      (expect (nth 2 (opt-align-in-buffer-without-mode)) :to-be-truthy))

    (it "still aligns the table in a buffer where the mode is off"
      (let ((buffer (generate-new-buffer "opt-no-mode")))
        (unwind-protect
            (with-current-buffer buffer
              (org-mode)
              (insert "| a | bb |\n|---+----|\n| ccc | d |\n")
              (org-pretty-table-mode -1)
              (advice-add 'org-table-align :around #'org-pretty-table-align)
              (goto-char (point-min))
              (org-table-align)
              (expect (buffer-substring-no-properties (point-min) (line-end-position))
                      :to-equal "| a   | bb |"))
          (advice-remove 'org-table-align #'org-pretty-table-align)
          (kill-buffer buffer))))

    (it "keeps the mode on in a buffer where it is on"
      (with-org-text "| a | bb |\n|---+----|\n| ccc | d |"
        (goto-char (point-min))
        (org-table-align)
        (expect org-pretty-table-mode :to-be-truthy)))

    (it "stays installed when the mode is disabled in another buffer"
      (with-org-text "| a | bb |\n|---+----|\n| ccc | d |"
        (let ((other (generate-new-buffer "opt-other")))
          (unwind-protect
              (with-current-buffer other
                (org-mode)
                (org-pretty-table-mode 1)
                (org-pretty-table-mode -1))
            (kill-buffer other)))
        (expect (advice-member-p #'org-pretty-table-align 'org-table-align)
                :to-be-truthy)
        (goto-char (point-min))
        (org-table-align)
        (opt-refontify)
        (expect (opt-face-p (opt-goto "|") 'org-pretty-table-border) :to-be-truthy)
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)))

    (it "is installed once however often the mode is enabled"
      (advice-remove 'org-table-align #'org-pretty-table-align)
      (with-org-text "| a |"
        (org-pretty-table-mode 1)
        (org-pretty-table-mode 1))
      (let ((count 0))
        (advice-mapc (lambda (f _props) (when (eq f #'org-pretty-table-align)
                                          (setq count (1+ count))))
                     'org-table-align)
        (expect count :to-be 1)))

    (it "does not toggle the mode while aligning"
      (with-org-text "| a | bb |\n|---+----|\n| ccc | d |"
        (spy-on 'org-pretty-table-mode :and-call-through)
        (goto-char (point-min))
        (org-table-align)
        (expect 'org-pretty-table-mode :not :to-have-been-called)
        (expect (assoc 'org-pretty-table--matcher font-lock-keywords) :to-be-truthy)))

    (it "restores glyphs and faces on a table that is already aligned"
      (with-org-text "| a   | bb |\n|-----+----|\n| ccc | d  |"
        (goto-char (point-min))
        (org-table-align)
        (font-lock-ensure)
        (when jit-lock-functions (jit-lock-fontify-now))
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)
        (expect (opt-face-p (opt-goto "|") 'org-pretty-table-border) :to-be-truthy)
        (expect (opt-face-p (opt-goto "a") 'org-pretty-table-header) :to-be-truthy)))

    (it "re-applies glyphs when the aligning function leaves the text alone"
      (with-org-text "| a   | bb |\n|-----+----|\n| ccc | d  |"
        (goto-char (point-min))
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)
        (goto-char (point-min))
        (org-pretty-table-align #'ignore)
        ;; Only refontifies text marked unfontified, as redisplay does.
        (jit-lock-fontify-now)
        (expect (get-text-property (opt-goto "|") 'display) :to-be-truthy)
        (expect (get-text-property (opt-goto "-----") 'display) :to-be-truthy)))))
