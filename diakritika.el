;;; diakritika.el --- Apply diacritics to slovak text -*- lexical-binding: t -*-

;; Copyright (C) 2020 Matúš Goljer

;; Author: Matus Goljer <matus@thales>
;; Maintainer: Matus Goljer <matus@thales>
;; Version: 0.0.1
;; Created: 16th April 2020
;; Package-requires: ((dash "2.10.0") (request "0.3.2"))
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'request)
(require 'dash)


(defun diakritika--json-read ()
  (let ((json-key-type 'string))
    (json-read)))

(defun diakritika--fix-region (beg end data)
  (save-excursion
    (save-restriction
      (widen)
      (narrow-to-region beg end)
      (goto-char (point-min))
      (while (< (point) (point-max))
        (-let* ((word (word-at-point))
                ((&alist "words" (&alist (downcase word) fixes)) data))
          (when (> (length fixes) 0)
            (-let (([(&alist "w")] fixes)
                   ((beg . end) (bounds-of-thing-at-point 'word)))
              (goto-char beg)
              (re-search-forward (regexp-quote word) nil t)
              (replace-match w)))
          (forward-word))))))

;;;###autoload
(defun diakritika-fix-region (beg end)
  (interactive "r")
  (let ((input (buffer-substring-no-properties beg end)))
    (request
     "https://diakritika.brm.sk/site/words"
     :type "POST"
     :data (request--urlencode-alist
            `(
              ("text" . ,input)
              ("requestkey" . "2020-04-16T17:00:00.188Z-15329676")
              ))
     :headers '(("content-type" . "application/x-www-form-urlencoded"))
     :sync t
     :parser 'diakritika--json-read
     :success (cl-function
               (lambda (&key data &allow-other-keys)
                 (diakritika--fix-region beg end data))))))

(provide 'diakritika)
;;; diakritika.el ends here
