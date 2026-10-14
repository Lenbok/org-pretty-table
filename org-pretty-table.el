;;; org-pretty-table.el --- Replace org-table characters with box-drawing unicode glyphs -*- lexical-binding: t -*-

;; Copyright (C) 2013, 2023 Matus Goljer

;; Author: Matus Goljer <matus.goljer@gmail.com>
;; Maintainer: Matus Goljer <matus.goljer@gmail.com>
;; Keywords: faces
;; URL: https://github.com/Fuco1/org-pretty-table
;; Package-Requires: ((org "9") (emacs "29.1"))
;; Version: 1.0.0
;; Created: 29th November 2013

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This replaces the characters - | and + in `org-mode' tables with
;; appropriate unicode box-drawing glyphs, see
;; http://en.wikipedia.org/wiki/Box-drawing_character
;;
;; It also styles tables with four faces: `org-pretty-table' (base),
;; `org-pretty-table-header', `org-pretty-table-border' and
;; `org-pretty-table-zebra', the last controlled by
;; `org-pretty-table-zebra-stripe'.  The faces are applied by a
;; buffer-local font-lock keyword.

;;; Code:

(require 'org)

(defconst org-pretty-table-regexp (regexp-opt '("-" "+" "|")))

(defgroup org-pretty-table ()
  "Replace org-table characters with box-drawing unicode glyphs."
  :group 'org)

(defface org-pretty-table '((t :inherit org-table))
  "Base face for every character of a pretty table.
Header, border and zebra faces inherit it.  It is applied last, so its
attributes fill in anything the other table faces leave unspecified."
  :group 'org-pretty-table)

(defface org-pretty-table-header '((t :inherit org-pretty-table :weight bold))
  "Face for cell contents in table header rows."
  :group 'org-pretty-table)

(defface org-pretty-table-border '((t :inherit (shadow org-pretty-table)))
  "Face for table borders (pipes and horizontal lines)."
  :group 'org-pretty-table)

(defface org-pretty-table-zebra '((t :inherit (hl-line org-pretty-table)))
  "Face for alternating table cells, excluding their borders."
  :group 'org-pretty-table)

(defcustom org-pretty-table-charset "┌┐└┘┬┤┴├┼─│"
  "Charset to draw the table.

The value is a string of length 11 with the characters used to
draw the table borders.

The order of the blocks is:

- upper left corner
- upper right corner
- lower left corner
- lower right corner
- down-facing T
- left-facing T
- up-facing T
- right-facing T
- cross
- horizontal bar
- vertical bar"
  :group 'org-pretty-table
  :type '(choice (const :tag "Single horizontal lines" "┌┐└┘┬┤┴├┼─│")
                 (const :tag "Double horizontal lines" "╒╕╘╛╤╡╧╞╪═│")
                 (string :tag "Custom")))

(defsubst org-pretty-table-ul-corner ()
  "Return upper left corner character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 0)))

(defsubst org-pretty-table-ur-corner ()
  "Return upper right corner character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 1)))

(defsubst org-pretty-table-ll-corner ()
  "Return lower left corner character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 2)))

(defsubst org-pretty-table-lr-corner ()
  "Return lower right corner character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 3)))

(defsubst org-pretty-table-df-t ()
  "Return down facing T character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 4)))

(defsubst org-pretty-table-lf-t ()
  "Return left facing T character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 5)))

(defsubst org-pretty-table-uf-t ()
  "Return up facing T character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 6)))

(defsubst org-pretty-table-rf-t ()
  "Return right facing T character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 7)))

(defsubst org-pretty-table-cross ()
  "Return cross character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 8)))

(defsubst org-pretty-table-hb ()
  "Return horizontal bar character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 9)))

(defsubst org-pretty-table-vb ()
  "Return vertical bar character as a string."
  (declare (pure t))
  (make-string 1 (aref org-pretty-table-charset 10)))

(defun org-pretty-table-at-table-p ()
  "Check if point is at table."
  (save-excursion
    (skip-syntax-forward " " (line-end-position))
    (eq (following-char) ?|)))

(defun org-pretty-table--table-line-at-p (offset)
  "Return non-nil if the line OFFSET lines from point is a table line.
Return nil when no such line exists."
  (save-excursion
    (and (zerop (forward-line offset))
         (org-pretty-table-at-table-p))))

(defun org-pretty-table-propertize-region (start end)
  "Replace org-table characters with box-drawing glyphs between START and END.

Used by jit-lock for dynamic highlighting."
  (save-excursion
    (goto-char start)
    (let (table-end)
      (while (re-search-forward org-pretty-table-regexp end t)
        ;; reached the end of the current table
        (if (and table-end
                 (> (point) table-end))
            (setq table-end nil))

        ;; check if the current match is a table if we are not in a
        ;; table right now
        (unless (and (not table-end)
                     (not (save-match-data
                            (org-at-table-p))))

          ;; get the end of the table if we found a new table, so we
          ;; don't have to check (org-at-table-p) again until then
          (unless table-end
            (save-match-data
              (setq table-end (org-table-end))))

          ;; determine the context of the character
          (let ((match (match-string 0)))
            (cond
             ((equal "-" match)
              (backward-char 1)
              (re-search-forward "-+")
              (when (looking-at-p "[+|]")
                (put-text-property
                 (match-beginning 0) (match-end 0)
                 'display
                 (make-string (- (match-end 0) (match-beginning 0))
                              (aref (org-pretty-table-hb) 0))))
              t)
             ((equal "|" match)
              (cond
               ((and (eq (following-char) ?-)
                     (org-pretty-table--table-line-at-p 1)
                     (save-excursion
                       (backward-char 1)
                       (not (bobp)))
                     (org-pretty-table--table-line-at-p -1))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-rf-t))
                t)
               ((and (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (org-pretty-table--table-line-at-p 1)
                     (org-pretty-table--table-line-at-p -1))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-lf-t))
                t)
               ((and (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (not (org-pretty-table--table-line-at-p -1)))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-ur-corner))
                t)
               ((and (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (not (org-pretty-table--table-line-at-p 1)))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-lr-corner))
                t)
               ((and (eq (following-char) ?-)
                     (not (org-pretty-table--table-line-at-p -1)))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-ul-corner))
                t)
               ((and (eq (following-char) ?-)
                     (not (org-pretty-table--table-line-at-p 1)))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-ll-corner))
                t)
               (t
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-vb))
                t)))
             ((equal "+" match)
              (cond
               ((and (eq (following-char) ?-)
                     (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (org-pretty-table--table-line-at-p -1)
                     (org-pretty-table--table-line-at-p 1))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-cross))
                t)
               ((and (eq (following-char) ?-)
                     (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (not (org-pretty-table--table-line-at-p -1))
                     (org-pretty-table--table-line-at-p 1))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-df-t))
                t)
               ((and (eq (following-char) ?-)
                     (save-excursion
                       (backward-char 1)
                       (eq (preceding-char) ?-))
                     (save-excursion
                       (let ((char-pos (- (point) (line-beginning-position) 1)))
                         (forward-line -1)
                         (beginning-of-line)
                         (forward-char char-pos))
                       (eq (following-char) ?|))
                     (save-excursion
                       (backward-char 1)
                       (forward-line)
                       (not (eq (following-char) ?|))))
                (put-text-property (match-beginning 0) (match-end 0) 'display (org-pretty-table-uf-t))
                t))))))))))

(defun org-pretty-table--line-kind ()
  "Return `hline', `data' or nil for the line at point."
  (save-excursion
    (beginning-of-line)
    (cond ((looking-at "[ \t]*|-") 'hline)
          ((looking-at "[ \t]*|") 'data))))

(defvar-local org-pretty-table--cache nil
  "Cons (TICK . HASH) of row-kind hashes keyed by table start.
Valid only while `buffer-chars-modified-tick' equals TICK.")

(defun org-pretty-table--set-zebra (symbol value)
  "Set SYMBOL to VALUE and refontify buffers using `org-pretty-table-mode'."
  (set-default symbol value)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (bound-and-true-p org-pretty-table-mode)
        (setq org-pretty-table--cache nil)
        (font-lock-flush)))))

(defcustom org-pretty-table-zebra-stripe t
  "Whether to shade every second data row of a table.
Header rows and horizontal lines are never shaded."
  :type 'boolean
  :initialize #'custom-initialize-default
  :set #'org-pretty-table--set-zebra
  :group 'org-pretty-table)

(defun org-pretty-table--compute-rows (beg end)
  "Return a hash table mapping line start to `hline', `header', `data' or `zebra'.
BEG and END delimit one Org table.  Header rows are the data rows before
the first hline that follows a data row; a table with no such hline has
no header.  When `org-pretty-table-zebra-stripe' is non-nil, every second
data row after the header is `zebra'."
  (let ((rows (make-hash-table)) lines header-end seen-data)
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (let ((kind (org-pretty-table--line-kind)))
          (push (cons (point) kind) lines)
          (cond ((eq kind 'data) (setq seen-data t))
                ((and (eq kind 'hline) seen-data (not header-end))
                 (setq header-end (point)))))
        (forward-line 1)))
    (let ((index 0))
      (dolist (l (nreverse lines))
        (puthash (car l)
                 (cond ((null (cdr l)) nil)
                       ((eq (cdr l) 'hline) 'hline)
                       ((and header-end (< (car l) header-end)) 'header)
                       (t (prog1 (if (and org-pretty-table-zebra-stripe
                                          (= (% index 2) 1))
                                     'zebra
                                   'data)
                            (setq index (1+ index)))))
                 rows)))
    rows))

(defun org-pretty-table--table-rows (beg end)
  "Return the row-kind hash for the table between BEG and END, cached."
  (let ((tick (buffer-chars-modified-tick)))
    (unless (and org-pretty-table--cache (eq (car org-pretty-table--cache) tick))
      (setq org-pretty-table--cache (cons tick (make-hash-table))))
    (with-memoization (gethash beg (cdr org-pretty-table--cache))
      (org-pretty-table--compute-rows beg end))))

(defun org-pretty-table--strip-org-faces (beg end)
  "Remove `org-table' and `org-table-row' from the `face' property in BEG..END.
Other faces in the property are kept."
  (let ((pos beg))
    (while (< pos end)
      (let ((next (min end (next-single-property-change pos 'face nil end)))
            (face (get-text-property pos 'face)))
        (cond ((memq face '(org-table org-table-row))
               (remove-text-properties pos next '(face nil)))
              ((consp face)
               (let ((kept (seq-remove (lambda (f) (memq f '(org-table org-table-row)))
                                       face)))
                 (if kept
                     (put-text-property pos next 'face kept)
                   (remove-text-properties pos next '(face nil))))))
        (setq pos next)))))

(defun org-pretty-table--style-line (kind)
  "Add faces to the table line at point of KIND.
KIND is one of `hline', `header', `data' or `zebra'.  Cell and padding
spans get the row face appended after their existing faces.  Borders
get the border face prepended and never the row face.  The base face is
appended to every character last."
  (save-excursion
    (let* ((beg (progn (beginning-of-line) (skip-chars-forward " \t") (point)))
           (end (progn (end-of-line) (skip-chars-backward " \t") (point)))
           (cell-face (pcase kind
                        ('header 'org-pretty-table-header)
                        ('zebra 'org-pretty-table-zebra)
                        (_ 'org-pretty-table))))
      (org-pretty-table--strip-org-faces beg end)
      (if (eq kind 'hline)
          (add-face-text-property beg end 'org-pretty-table-border)
        (let ((pos beg))
          (goto-char beg)
          (while (search-forward "|" end t)
            (let ((bar (1- (point))))
              (when (> bar pos)
                (add-face-text-property pos bar cell-face t))
              (add-face-text-property bar (point) 'org-pretty-table-border)
              (setq pos (point))))
          (when (> end pos)
            (add-face-text-property pos end cell-face t))))
      (add-face-text-property beg end 'org-pretty-table t))))

(defun org-pretty-table--matcher (limit)
  "Font-lock matcher styling table lines up to LIMIT.  Always returns nil."
  (save-match-data
    (let (table-end rows)
      (beginning-of-line)
      (while (< (point) limit)
        (when (org-pretty-table--line-kind)
          (unless (and table-end (< (point) table-end))
            (setq table-end nil rows nil)
            (when (org-at-table-p)
              (setq table-end (org-table-end)
                    rows (org-pretty-table--table-rows
                          (org-table-begin) table-end))))
          (when table-end
            (let ((kind (gethash (line-beginning-position) rows)))
              (when kind
                (org-pretty-table--style-line kind)))))
        (forward-line 1))))
  nil)

(defconst org-pretty-table--keywords '((org-pretty-table--matcher))
  "Font-lock keywords added by `org-pretty-table-mode'.")

(defun org-pretty-table-unpropertize-region (start end)
  "Remove box-drawing `display' strings between START and END.
Only `display' is cleared; faces are not changed."
  (remove-text-properties start end '(display)))

(defun org-pretty-table-unpropertize-table ()
  "Remove box-drawing compositions from table at point."
  (org-pretty-table-unpropertize-region (org-table-begin) (org-table-end)))

(defvar org-pretty-table-mode)

(defun org-pretty-table-align (oldfun &rest args)
  "Call OLDFUN with ARGS with the table's glyphs removed, then restore them.
Only buffers with `org-pretty-table-mode' enabled are affected."
  (if (not org-pretty-table-mode)
      (apply oldfun args)
    (unwind-protect
        (progn
          (org-pretty-table-mode -1)
          (org-pretty-table-unpropertize-table)
          (apply oldfun args))
      (org-pretty-table-mode 1))))

;;; Minor mode:

;;;###autoload
(define-minor-mode org-pretty-table-mode
  "Replace org-table characters with box-drawing unicode glyphs and style tables.
Enabling adds a font-lock keyword that applies the `org-pretty-table'
faces.  Disabling removes it and refontifies, so only Org's own faces
remain."
  :lighter " OPT"
  (if org-pretty-table-mode
      (progn
        (jit-lock-register 'org-pretty-table-propertize-region t)
        ;; `jit-lock-register' puts the newest function first.  Run ours
        ;; after `font-lock-fontify-region', otherwise font-lock clears
        ;; our `display' strings (e.g. when `org-modern' makes `display'
        ;; a managed property, or when the mode is enabled after font-lock).
        (remove-hook 'jit-lock-functions 'org-pretty-table-propertize-region t)
        (add-hook 'jit-lock-functions 'org-pretty-table-propertize-region t t)
        (advice-add 'org-table-align :around #'org-pretty-table-align)
        (font-lock-add-keywords nil org-pretty-table--keywords 'append)
        (font-lock-flush))
    (jit-lock-unregister 'org-pretty-table-propertize-region)
    (advice-remove 'org-table-align #'org-pretty-table-align)
    (font-lock-remove-keywords nil org-pretty-table--keywords)
    (setq org-pretty-table--cache nil)
    (org-pretty-table-unpropertize-region (point-min) (point-max))
    (font-lock-flush)))

;;;###autoload
(defun turn-on-org-pretty-table-mode ()
  "Turn on `org-pretty-table-mode' unless the buffer is hidden.
A hidden buffer is one whose name starts with a space."
  (unless (string-prefix-p " " (buffer-name))
    (org-pretty-table-mode 1)))

;;;###autoload
(defun turn-off-org-pretty-table-mode ()
  "Turn off `org-pretty-table-mode'."
  (org-pretty-table-mode 0))

;;;###autoload
(define-globalized-minor-mode global-org-pretty-table-mode
  org-pretty-table-mode turn-on-org-pretty-table-mode)

(provide 'org-pretty-table)
;;; org-pretty-table.el ends here
