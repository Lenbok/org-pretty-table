# org-pretty-table

Draw pretty unicode tables in `org-mode` and `orgtbl-mode`.

Very experimental.

![example](https://pbs.twimg.com/media/FqexCG-WYAA9x_X?format=png&name=large)

# Usage

Enable the `org-pretty-table-mode` in an org buffer and it will
replace the ASCII table borders with beautiful unicode ones.  The
replacement is *only visual* (using [display text properties][props]),
nothing in your file is actually changed.  The buffer and the file
saved to disc still contains the original ASCII characters (which it
must since that's what org uses for table detection).

You can customize `org-pretty-table-charset` to change the border
characters.  This mode comes with two built-in "themes", single
horizontal lines and double horizontal lines.  See `M-x
customize-variable RET org-pretty-table-charset RET`.

# Faces and options

The mode also styles tables with these faces, so they can match other
table renderers such as markdown and agent-shell tables:

| Face                      | Used for                                              |
|---------------------------|-------------------------------------------------------|
| `org-pretty-table`        | Base face for every table char (inherits `org-table`) |
| `org-pretty-table-header` | Cells of header rows (rows above the first hline)     |
| `org-pretty-table-border` | Pipes and horizontal lines                            |
| `org-pretty-table-zebra`  | Cells of every second data row, never borders         |

A table without an hline has no header.  `org-pretty-table-zebra-stripe`
(default `t`) turns the stripes on or off.

Set a font on the base face to pin every column to one font, for
example in variable-pitch buffers:

```elisp
(set-face-attribute 'org-pretty-table nil :family "DejaVu Sans Mono")
```

The faces are applied by a buffer-local font-lock keyword, so enable
the mode after `org-mode` starts (the global mode does this).  Turning
the mode off removes them and leaves only Org's own faces.

# Installation

This package is not yet distributed through package archives.  Install it from the Git repository, or manually.

## With `use-package`

Using the built-in `:vc` keyword (Emacs 30 and later):

``` emacs-lisp
(use-package org-pretty-table
  :vc (:url "https://github.com/Lenbok/org-pretty-table")
  :hook (org-mode . org-pretty-table-mode))
```

Or with [elpaca](https://github.com/progfolio/elpaca):

``` emacs-lisp
(use-package org-pretty-table
  :ensure (:host github :repo "Lenbok/org-pretty-table")
  :hook (org-mode . org-pretty-table-mode))
```

Enable the mode from `org-mode-hook` (or use `global-org-pretty-table-mode`)
so that it starts after Org sets up font-lock.  To customize the faces,
add the `set-face-attribute` calls from "Faces and options" to the `:config` block.

## Manually

1. Download the `org-pretty-table.el` file into some folder in your hard drive (for example `~/.emacs.d/site-lisp`).

2. Put the following code into your `~/.emacs.d/init.el` or `~/.emacs` file:

``` emacs-lisp
(progn
  (add-to-list 'load-path "~/.emacs.d/site-lisp")
  (require 'org-pretty-table)
  (add-hook 'org-mode-hook (lambda () (org-pretty-table-mode))))
```

3. Evaluate the `progn` block by putting the point on the `progn` and calling `C-M-x` (`M-x eval-defun`).  If unsure, you can also simply restart Emacs.

4. Open an org-mode file.  Calling `M-: org-pretty-table-mode RET` should print `1` in the minibuffer.  You're done!

# Development

Use Eask to install dependencies:

``` shell
eask install-deps --dev
```

Run tests with

``` shell
eask test buttercup
```

[props]: https://www.gnu.org/software/emacs/manual/html_node/elisp/Special-Properties.html
