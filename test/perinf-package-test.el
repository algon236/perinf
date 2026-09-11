;;; perinf-package-test.el --- Packaging and regression checks -*- lexical-binding: t; -*-
(require 'ert)
(require 'perinf)

(ert-deftest perinf-package-danish-title-and-lazy-locale ()
  (let ((perinf-interface-language 'da))
    (should (equal (perinf-i18n 'app.name)
                   "Personligt arbejds- og informationssystem"))
    (with-temp-buffer
      (perinf-mode)
      (let ((perinf-current-project nil)) (perinf-core--render))
      (should (equal mode-name (perinf-i18n 'app.name)))
      (should (string-prefix-p (perinf-i18n 'app.name) (buffer-string))))))

(ert-deftest perinf-package-org-hooks-are-not-run-internal ()
  (let* ((org-mode-hook (list (lambda () (error "External Org hook ran"))))
         (project (expand-file-name "examples/minimal-project" perinf-test-root)))
    (should (perinf-project-read-metadata project))
    (should (listp (perinf-storage-list 'task project)))))

(ert-deftest perinf-package-refuses-unsaved-file-overwrite ()
  (let ((file (make-temp-file "perinf-unsaved-")) visiting)
    (unwind-protect
        (progn
          (setq visiting (find-file-noselect file))
          (with-current-buffer visiting (insert "unsaved"))
          (with-temp-buffer
            (insert "replacement")
            (should-error (perinf-storage--atomic-write-buffer (current-buffer) file)
                          :type 'user-error))
          (should (= 0 (file-attribute-size (file-attributes file)))))
      (when (buffer-live-p visiting)
        (with-current-buffer visiting (set-buffer-modified-p nil))
        (kill-buffer visiting))
      (delete-file file))))

(ert-deftest perinf-package-local-language-overrides-project ()
  (let* ((parent (make-temp-file "perinf-language-" t))
         (project (expand-file-name "project" parent))
         (perinf-state-file (expand-file-name "state.el" parent))
         (perinf-interface-language 'en)
         (perinf-interface-language-override 'da)
         perinf-current-project perinf-last-project-directory)
    (unwind-protect
        (progn
          (perinf-project-create project "Test" 'en 'iso 'twenty-four-hour)
          (perinf-core--activate-project project)
          (should (eq perinf-interface-language 'da))
          (should (equal "en" (alist-get 'INTERFACE_LANGUAGE
                                         (perinf-project-read-metadata project)))))
      (delete-directory parent t))))

(ert-deftest perinf-package-localized-long-accepts-iso-input ()
  (should (equal "2026-09-11" (perinf-date-normalize "2026-09-11" 'localized-long)))
  (should-error (perinf-date-normalize "2026-02-30" 'localized-long)))

(ert-deftest perinf-package-activity-does-not-cross-projects ()
  (let ((perinf-current-project "/project-b/")
        (perinf-task-activity-project "/project-a/")
        (perinf-task-activity-task-id "task-example")
        (perinf-task-activity-last-write nil))
    (cl-letf (((symbol-function 'perinf-storage-touch-task-activity)
               (lambda (&rest _) (error "Wrong project written"))))
      (perinf-task-record-buffer-activity)
      (should-not perinf-task-activity-last-write))))

(ert-deftest perinf-package-public-read-and-missing-id ()
  (let* ((parent (make-temp-file "perinf-read-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create project "Read" 'da 'iso 'twenty-four-hour)
          (let ((task (perinf-storage-create 'task '((title . "Read me")) project)))
            (should (equal (perinf-object-title
                            (perinf-storage-read (perinf-object-id task) project))
                           "Read me")))
          (should-error (perinf-storage-read "missing" project)
                        :type 'perinf-object-not-found))
      (delete-directory parent t))))

(ert-deftest perinf-package-interactive-commands-collect-required-arguments ()
  (dolist (command '(perinf-assign-task perinf-set-task-context
                     perinf-create-task-from-decision perinf-approve-minutes
                     perinf-submit-minutes perinf-edit-minutes perinf-reject-minutes
                     perinf-create-decision-from-minutes perinf-set-meeting-attendance))
    (should (cadr (interactive-form command)))))

(ert-deftest perinf-package-danish-validation ()
  (let ((perinf-interface-language 'da))
    (condition-case err
        (perinf-date-normalize "31-02-2026" 'day-month-year-dash)
      (user-error (should (string-match-p "Ugyldig dato" (error-message-string err)))))))

(ert-deftest perinf-package-project-rejects-unsupported-schema ()
  (let* ((parent (make-temp-file "perinf-schema-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create project "Schema" 'en 'iso 'twenty-four-hour)
          (let ((file (expand-file-name "perinf-project.org" project)))
            (with-temp-buffer
              (insert-file-contents file)
              (goto-char (point-min))
              (re-search-forward ":SCHEMA_VERSION:     1")
              (replace-match ":SCHEMA_VERSION:     999")
              (write-region (point-min) (point-max) file)))
          (should-error (perinf-project-read-metadata project) :type 'user-error))
      (delete-directory parent t))))

(ert-deftest perinf-package-custom-org-todo-and-hooks-do-not-interfere ()
  (let* ((parent (make-temp-file "perinf-org-settings-" t))
         (project (expand-file-name "project" parent))
         (org-todo-keywords '((sequence "VENTER" "|" "FÆRDIG")))
         (org-after-todo-state-change-hook
          (list (lambda () (error "User TODO hook ran")))))
    (unwind-protect
        (progn
          (perinf-project-create project "Org" 'en 'iso 'twenty-four-hour)
          (let* ((task (perinf-storage-create 'task '((title . "Test task")) project))
                 (id (perinf-object-id task)))
            (should (equal "Test task" (perinf-object-title
                                        (perinf-storage-read id project))))
            (perinf-storage-update id '((PERINF_STATUS . completed)) project)
            (should (eq 'completed (perinf-object-status
                                    (perinf-storage-read id project))))))
      (delete-directory parent t))))

(ert-deftest perinf-package-storage-datetime-validation ()
  (should (string-prefix-p "2026-09-11T12:34:56"
                           (perinf-storage--datetime "2026-09-11" "12:34:56")))
  (should-error (perinf-storage--datetime "2026-02-30" "12:00:00"))
  (should-error (perinf-storage--datetime "2026-09-11" "25:00:00")))
