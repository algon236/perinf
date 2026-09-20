;;; perinf-statistics-test.el --- Statistical report regression tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'perinf-statistics)
(require 'perinf-core)

(defmacro perinf-statistics-test--project (&rest body)
  `(let ((project (make-temp-file "perinf-stats-test-" t)))
     (unwind-protect
         (progn
           (delete-directory project)
           (perinf-project-create project "Test" 'da 'day-month-year-dash 'twenty-four-hour)
           (with-temp-file (expand-file-name "data/tasks.org" project)
             (insert "* DONE Alpha\nCLOSED: [2026-08-04 Tue 12:00]\n:PROPERTIES:\n:ID: t1\n:PERINF_TYPE: task\n:PERINF_STATUS: completed\n:CREATED_AT: 2026-07-01T09:00:00+02:00\n:TASK_WORK_SECONDS: 120\n:END:\n* TODO Beta\n:PROPERTIES:\n:ID: t2\n:PERINF_TYPE: task\n:PERINF_STATUS: active\n:CREATED_AT: 2026-09-01T09:00:00+02:00\n:END:\n"))
           (cl-letf (((symbol-function 'current-time)
                      (lambda () perinf-statistics-test--now)))
             ,@body))
       (dolist (b (buffer-list))
         (when (and (buffer-file-name b) (string-prefix-p project (buffer-file-name b)))
           (with-current-buffer b (set-buffer-modified-p nil)) (kill-buffer b)))
       (delete-directory project t))))

(defconst perinf-statistics-test--now (encode-time 0 0 12 20 9 2026))

(ert-deftest perinf-statistics-months-are-independent ()
  (perinf-statistics-test--project
   (let* ((s (perinf-statistics--collect project 2026 perinf-statistics-test--now))
          (m (alist-get 'months s)))
     (should (= (perinf-statistics--sum s 'created) 2))
     (should (= (alist-get 'created (aref m 6)) 1))
     (should (= (alist-get 'closed (aref m 7)) 1))
     (should (= (alist-get 'created (aref m 8)) 1))
     (should (= (alist-get 'created (aref m 0)) 0))
     (should (= (alist-get 'seconds s) 120))
     (should (= (alist-get 'unfinished (alist-get 'stock s)) 1)))))

(ert-deftest perinf-statistics-historical-year-is-not-current-stock ()
  (perinf-statistics-test--project
   (let ((s (perinf-statistics--collect project 2025 perinf-statistics-test--now)))
     (should-not (alist-get 'stock s))
     (should (= (perinf-statistics--sum s 'created) 0))
     (should (string-match-p "Historisk år" (perinf-statistics--render s nil))))))

(ert-deftest perinf-statistics-reports-immutable-and-comparable ()
  (perinf-statistics-test--project
   (let* ((first (perinf-statistics--save project 2026))
          (hash (with-temp-buffer (insert-file-contents first) (secure-hash 'sha256 (current-buffer)))))
     (with-temp-buffer
       (insert-file-contents (expand-file-name "data/tasks.org" project))
       (goto-char (point-max))
       (insert "* TODO Gamma\n:PROPERTIES:\n:ID: t3\n:PERINF_TYPE: task\n:PERINF_STATUS: active\n:CREATED_AT: 2026-09-20\n:END:\n")
       (write-region (point-min) (point-max) (expand-file-name "data/tasks.org" project)))
     (let ((second (perinf-statistics--save project 2026)))
       (should-not (equal first second))
       (should (= (length (perinf-statistics--history project)) 2))
       (should (equal hash (with-temp-buffer (insert-file-contents first) (secure-hash 'sha256 (current-buffer)))))
       (with-temp-buffer
         (insert-file-contents second)
         (should (search-forward "| Opgaver i alt | 3 | +1 | — |" nil t)))))))

(ert-deftest perinf-statistics-year-baseline-crosses-year-boundary ()
  (let* ((old '((year . 2025) (captured . "2025-12-31T18:00:00+0100") (stock . ((tasks . 4)))))
         (last '((year . 2026) (captured . "2026-06-01T18:00:00+0200") (stock . ((tasks . 6)))))
         (current '((year . 2026) (captured . "2026-09-01T18:00:00+0200")))
         (baselines (perinf-statistics--baselines current (list old last))))
    (should (equal (car baselines) last))
    (should (equal (cadr baselines) old))
    (should (equal (perinf-statistics--delta 8 old 'tasks) "+4"))
    (should (equal (perinf-statistics--delta 8 nil 'tasks) "—"))))

(ert-deftest perinf-statistics-unsaved-source-is-refused ()
  (perinf-statistics-test--project
   (let ((b (find-file-noselect (expand-file-name "data/tasks.org" project))))
     (with-current-buffer b (goto-char (point-max)) (insert "unsaved"))
     (should-error (perinf-statistics--collect project 2026) :type 'user-error)
     (should-not (file-exists-p (expand-file-name "statistics" project))))))

(ert-deftest perinf-statistics-corrupt-history-is-refused ()
  (perinf-statistics-test--project
   (let ((file (perinf-statistics--save project 2026)))
     (with-temp-file (expand-file-name "snapshot.json" (file-name-directory file)) (insert "broken"))
     (should-error (perinf-statistics--save project 2026)))))

(ert-deftest perinf-statistics-ui-has-working-year-controls ()
  (perinf-statistics-test--project
   (let ((file (perinf-statistics--save project 2026)))
     (save-window-excursion
       (perinf-statistics--show project 2026 file)
       (should buffer-read-only)
       (should (= perinf-statistics--year 2026))
       (should (button-at (point-min)))
       (should (search-forward "Skift år" nil t))
       (let ((button (button-at (1- (point)))))
         (cl-letf (((symbol-function 'read-number) (lambda (&rest _) 2025)))
           (button-activate button)))
       (should (= perinf-statistics--year 2025))
       (should (search-forward "Historisk år" nil t))
       (kill-buffer (current-buffer))))))

(ert-deftest perinf-statistics-invalid-year-is-refused ()
  (perinf-statistics-test--project
   (should-error (perinf-statistics--collect project 2027 perinf-statistics-test--now) :type 'user-error)))

(ert-deftest perinf-statistics-first-report-after-new-year ()
  (let* ((old '((year . 2025) (captured . "2025-12-31T18:00:00+0100")
                (stock . ((tasks . 4)))))
         (current '((year . 2026) (captured . "2026-01-01T18:00:00+0100"))))
    (should (equal (perinf-statistics--baselines current (list old)) (list old old)))))

(ert-deftest perinf-statistics-reading-history-does-not-save ()
  (perinf-statistics-test--project
   (perinf-statistics--save project 2026)
   (save-window-excursion
     (perinf-statistics--open-year project 2026)
     (should (= (length (perinf-statistics--history project)) 1))
     (kill-buffer (current-buffer)))))

(ert-deftest perinf-statistics-missing-source-refused ()
  (perinf-statistics-test--project
   (delete-file (expand-file-name "data/tasks.org" project))
   (should-error (perinf-statistics--save project 2026) :type 'user-error)
   (should-not (file-exists-p (expand-file-name "statistics" project)))))

(ert-deftest perinf-statistics-memo-subheadings-not-counted ()
  (perinf-statistics-test--project
   (with-temp-file (expand-file-name "data/memos.org" project)
     (insert "* DONE Memo\n:PROPERTIES:\n:ID: m1\n:CATEGORY: Husk\n:CREATED: [2026-09-14 Mon]\n:END:\n** Detail\nSome text\n"))
   (let ((s (perinf-statistics--collect project 2026 perinf-statistics-test--now)))
     (should (= (alist-get 'memos (alist-get 'stock s)) 1))
     (should (= (perinf-statistics--sum s 'memos) 1)))))
