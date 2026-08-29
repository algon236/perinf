;;; perinf-pkg.el --- Package definition for Personal Work and Information System -*- no-byte-compile: t; lexical-binding: t; -*-

;; Copyright (C) 2026, Niels Søndergaard, Nivaa, Denmark.
;; Author: Niels Søndergaard, mail: niels<at>algon.dk

;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is part of Personal Work and Information System.
;;
;; Personal Work and Information System is free software: you can redistribute
;; it and/or modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; Personal Work and Information System is distributed in the hope that it will
;; be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <https://www.gnu.org/licenses/>.

(define-package
  "perinf"
  "1.0.0"
  "Org-backed personal work and information management"
  '((emacs "29.1")
    (org "9.6"))
  :url "https://github.com/algon236/perinf"
  :keywords '("outlines" "calendar" "convenience"))

;;; perinf-pkg.el ends here
