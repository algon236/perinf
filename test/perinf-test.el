;;; perinf-test.el --- Bootstrap tests for Personal Work and Information System -*- lexical-binding: t; -*-

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Code:

(require 'ert)
(require 'perinf)

(defconst perinf-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "Repository root used by the bootstrap tests.")

(ert-deftest perinf-test-all-locales-are-complete ()
  (perinf-i18n-load-locales)
  (dolist (locale perinf-i18n-supported-locales)
    (should (equal (perinf-i18n-validate-locale locale)
                   '(:missing nil :unknown nil)))))

(ert-deftest perinf-test-project-metadata-is-readable ()
  (let* ((project (expand-file-name "examples/minimal-project"
                                    perinf-test-root))
         (metadata (perinf-storage-read-project project)))
    (should (equal (alist-get 'PROJECT_ID metadata)
                   "project-example"))
    (should (equal (alist-get 'SCHEMA_VERSION metadata)
                   "1"))))

(ert-deftest perinf-test-start-page-renders-in-danish ()
  (let ((perinf-interface-language 'da)
        (perinf-current-project nil))
    (perinf-i18n-load-locales)
    (with-temp-buffer
      (perinf-mode)
      (perinf-core--render)
      (should (string-match-p "Intet projekt er åbent"
                              (buffer-string))))))

(ert-deftest perinf-test-dashboard-shows-real-project-content ()
  (let* ((parent (make-temp-file "perinf-dashboard-test-" t))
         (project (expand-file-name "dashboard-project" parent))
         (perinf-interface-language 'da))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Dashboard" 'da 'day-month-year-dash
           'twenty-four-hour)
          (perinf-storage-create
           'task
           '((title . "Ring til kommunen")
             (deadline . "2000-01-01"))
           project)
          (perinf-storage-create
           'person '((title . "Anne Jensen")) project)
          (perinf-storage-create
           'meeting
           '((title . "Bestyrelsesmøde")
             (date . "2026-08-12")
             (start-time . "14:00:00"))
           project)
          (let ((perinf-current-project
                 (file-name-as-directory project)))
            (perinf-i18n-load-locales)
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'home)
              (perinf-core--render)
              (should (string-match-p "Overblik" (buffer-string)))
              (should (string-match-p "Opgaver: 1" (buffer-string)))
              (should (string-match-p "Åbne opgaver: 1" (buffer-string)))
              (should
               (string-match-p "Overskredne opgaver: 1" (buffer-string)))
              (should (string-match-p "Møder: 1" (buffer-string)))
              (should (string-match-p "Personer: 1" (buffer-string)))
              (should (string-match-p "Ring til kommunen"
                                      (buffer-string)))
              (should (string-match-p "Bestyrelsesmøde"
                                      (buffer-string)))
              (should-not
               (string-match-p
                "Projektet indeholder endnu ingen registrerede objekter"
                (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'work)
              (perinf-core--render)
              (should (string-match-p "Overskredet" (buffer-string))))
            (let ((task
                   (car (perinf-storage-list 'task project))))
              (perinf-storage-update
               (perinf-object-id task)
               '((PERINF_STATUS . completed))
               project)
              (should-not
               (perinf-core--task-overdue-p
                (car (perinf-storage-list 'task project)))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-search-finds-objects-by-title ()
  (let* ((parent (make-temp-file "perinf-search-test-" t))
         (project (expand-file-name "search-project" parent))
         (perinf-interface-language 'da))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Search" 'da 'day-month-year-dash
           'twenty-four-hour)
          (perinf-storage-create
           'task '((title . "Ring til kommunen")) project)
          (perinf-storage-create
           'person '((title . "Anne Jensen")) project)
          (perinf-storage-create
           'meeting
           '((title . "Bestyrelsesmøde")
             (date . "2026-08-12")
             (start-time . "14:00:00"))
           project)
          (let* ((perinf-current-project
                  (file-name-as-directory project))
                 (results (perinf-core--search-objects "MØDE")))
            (should (= (length results) 1))
            (should (eq (perinf-object-type (car results)) 'meeting))
            (should (equal (perinf-object-title (car results))
                           "Bestyrelsesmøde"))
            (perinf-i18n-load-locales)
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'search
                    perinf-search-query "MØDE"
                    perinf-search-results results)
              (perinf-core--render)
              (should (string-match-p "Find objekt" (buffer-string)))
              (should (string-match-p "Resultater: 1" (buffer-string)))
              (should (string-match-p "Møde  Bestyrelsesmøde"
                                      (buffer-string)))
              (setq perinf-current-view 'detail
                    perinf-selected-object (car results))
              (perinf-core--render)
              (should (string-match-p "Type: Møde" (buffer-string)))
              (should (string-match-p "Status: Planlagt" (buffer-string)))
              (should (string-match-p "Dato: 12-08-2026"
                                      (buffer-string)))
              (should (string-match-p "Deltagere" (buffer-string)))
              (should (string-match-p "Dagsordenspunkter"
                                      (buffer-string))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-create-real-project ()
  (let* ((parent (make-temp-file "perinf-project-test-" t))
         (project (expand-file-name "real-project" parent)))
    (unwind-protect
        (let* ((created
                (perinf-project-create
                 project "Real project" 'da 'day-month-year-dash
                 'twenty-four-hour))
               (metadata (perinf-project-read-metadata created)))
          (should (perinf-project-p created))
          (should (equal (alist-get 'PROJECT_TITLE metadata) "Real project"))
          (should (equal (alist-get 'INTERFACE_LANGUAGE metadata) "da"))
          (dolist (file '("data/tasks.org" "data/people.org"
                          "data/contexts.org" "data/decisions.org"))
            (should (file-regular-p (expand-file-name file created))))
          (dolist (directory '("data/meetings" "data/transcripts"
                               "data/minutes" "media/audio" "archive"
                               "config"))
            (should (file-directory-p
                     (expand-file-name directory created)))))
      (delete-directory parent t))))

(ert-deftest perinf-test-create-project-refuses-existing-directory ()
  (let ((directory (make-temp-file "perinf-existing-test-" t)))
    (unwind-protect
        (should-error
         (perinf-project-create
          directory "Existing" 'en 'iso 'twenty-four-hour)
         :type 'user-error)
      (delete-directory directory t))))

(ert-deftest perinf-test-last-project-state-round-trip ()
  (let* ((parent (make-temp-file "perinf-state-test-" t))
         (perinf-state-file (expand-file-name "state/state.el" parent))
         (perinf-last-project-directory "/tmp/perinf-example/"))
    (unwind-protect
        (progn
          (perinf-core--save-state)
          (setq perinf-last-project-directory nil)
          (perinf-core--load-state)
          (should (equal perinf-last-project-directory
                         "/tmp/perinf-example/")))
      (delete-directory parent t))))

(ert-deftest perinf-test-danish-main-menu-and-regional-settings ()
  (let ((perinf-interface-language 'da)
        (perinf-current-project
         (file-name-as-directory
          (expand-file-name "examples/minimal-project" perinf-test-root))))
    (perinf-i18n-load-locales)
    (with-temp-buffer
      (perinf-mode)
      (setq perinf-current-view 'administration)
      (perinf-core--render)
      (dolist (text '("Start" "Arbejde" "Møder" "Arkiv"
                      "Administration" "ÅÅÅÅ-MM-DD" "24-timers ur"))
        (should (string-match-p text (buffer-string)))))))

(ert-deftest perinf-test-danish-date-normalization ()
  (should
   (equal (perinf-date-normalize "31-08-2026" 'day-month-year-dash)
          "2026-08-31"))
  (should-error
   (perinf-date-normalize "08/31/2026" 'day-month-year-dash)
   :type 'user-error))

(ert-deftest perinf-test-task-round-trip-through-storage-api ()
  (let* ((parent (make-temp-file "perinf-task-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Task test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'task
                   '((title . "Ring til kommunen")
                     (deadline . "2026-08-31")
                     (description . "Spørg om mødet."))
                   project))
                 (tasks (perinf-storage-list 'task project))
                 (task (car tasks)))
            (should (string-prefix-p "task-" (perinf-object-id created)))
            (should (= (length tasks) 1))
            (should (equal (perinf-object-title task)
                           "Ring til kommunen"))
            (should (equal
                     (alist-get 'DEADLINE
                                (perinf-object-properties task))
                     "2026-08-31"))))
      (delete-directory parent t))))

(ert-deftest perinf-test-task-status-workflow-through-storage-api ()
  (let* ((parent (make-temp-file "perinf-complete-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Completion test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'task '((title . "Afslut mig")) project))
                 (active
                  (perinf-storage-update
                   (perinf-object-id created)
                   '((PERINF_STATUS . active))
                   project))
                 (waiting
                  (perinf-storage-update
                   (perinf-object-id created)
                   '((PERINF_STATUS . waiting))
                   project))
                 (completed
                  (perinf-storage-update
                   (perinf-object-id created)
                   '((PERINF_STATUS . completed))
                   project))
                 (reopened
                  (perinf-storage-update
                   (perinf-object-id created)
                   '((PERINF_STATUS . open))
                   project))
                 (cancelled
                  (perinf-storage-update
                   (perinf-object-id created)
                   '((PERINF_STATUS . cancelled))
                   project))
                 (source
                  (with-temp-buffer
                    (insert-file-contents
                     (expand-file-name "data/tasks.org" project))
                    (buffer-string))))
            (should (eq (perinf-object-status active) 'active))
            (should (eq (perinf-object-status waiting) 'waiting))
            (should (eq (perinf-object-status completed) 'completed))
            (should (eq (perinf-object-status reopened) 'open))
            (should (eq (perinf-object-status cancelled) 'cancelled))
            (should (string-match-p "\\* TODO Afslut mig" source))
            (should-not (string-match-p "CLOSED: \\[" source))
            (should (string-match-p
                     ":PERINF_STATUS:[[:space:]]+cancelled"
                     source))
            (should-error
             (perinf-storage-update
              (perinf-object-id created)
              '((PERINF_STATUS . waiting))
              project)
             :type 'user-error)))
      (delete-directory parent t))))

(ert-deftest perinf-test-time-normalization ()
  (should (equal (perinf-time-normalize "14:30" 'twenty-four-hour)
                 "14:30:00"))
  (should (equal (perinf-time-normalize "2:30 PM" 'twelve-hour)
                 "14:30:00"))
  (should-error
   (perinf-time-normalize "25:00" 'twenty-four-hour)
   :type 'user-error))

(ert-deftest perinf-test-work-task-order ()
  (let* ((completed
          (make-perinf-object
           :id "task-completed" :type 'task :title "Completed"
           :status 'completed :properties '((DEADLINE . "1999-01-01"))))
         (cancelled
          (make-perinf-object
           :id "task-cancelled" :type 'task :title "Cancelled"
           :status 'cancelled :properties '((DEADLINE . "1999-01-01"))))
         (without-deadline
          (make-perinf-object
           :id "task-none" :type 'task :title "No deadline"
           :status 'open :properties '((DEADLINE))))
         (future
          (make-perinf-object
           :id "task-future" :type 'task :title "Future"
           :status 'open :properties '((DEADLINE . "2999-01-01"))))
         (overdue
          (make-perinf-object
           :id "task-overdue" :type 'task :title "Overdue"
           :status 'open :properties '((DEADLINE . "2000-01-01"))))
         (ordered
          (perinf-core--sort-tasks
           (list completed cancelled without-deadline future overdue))))
    (should
     (equal
      (mapcar #'perinf-object-title ordered)
      '("Overdue" "Future" "No deadline" "Cancelled" "Completed")))))

(ert-deftest perinf-test-meeting-round-trip-through-storage-api ()
  (let* ((parent (make-temp-file "perinf-meeting-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Meeting test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'meeting
                   '((title . "Bestyrelsesmøde")
                     (date . "2026-08-12")
                     (start-time . "14:00:00")
                     (finish-time . "16:00:00")
                     (location . "Lokale 2"))
                   project))
                 (meetings (perinf-storage-list 'meeting project))
                 (meeting (car meetings)))
            (should (file-regular-p (perinf-object-file created)))
            (should (= (length meetings) 1))
            (should (equal (perinf-object-title meeting)
                           "Bestyrelsesmøde"))
            (should (string-prefix-p
                     "2026-08-12T14:00:00"
                     (alist-get 'START_AT
                                (perinf-object-properties meeting))))
            (should (equal
                     (alist-get 'LOCATION
                                (perinf-object-properties meeting))
                     "Lokale 2"))))
      (delete-directory parent t))))

(ert-deftest perinf-test-meeting-status-workflow ()
  (let* ((parent (make-temp-file "perinf-meeting-status-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Meeting status" 'en 'iso 'twenty-four-hour)
          (let* ((meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Status meeting")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (meeting-id (perinf-object-id meeting))
                 (postponed
                  (perinf-storage-set-meeting-status
                   meeting-id 'postponed project))
                 (planned-again
                  (perinf-storage-set-meeting-status
                   meeting-id 'planned project))
                 (started
                  (perinf-storage-set-meeting-status
                   meeting-id 'in-progress project))
                 (held
                  (perinf-storage-set-meeting-status
                   meeting-id 'held project)))
            (should (eq (perinf-object-status postponed) 'postponed))
            (should (eq (perinf-object-status planned-again) 'planned))
            (should (eq (perinf-object-status started) 'in-progress))
            (should
             (alist-get
              'ACTUAL_START_AT (perinf-object-properties started)))
            (should (eq (perinf-object-status held) 'held))
            (should
             (alist-get
              'ACTUAL_FINISH_AT (perinf-object-properties held)))
            (should-error
             (perinf-storage-set-meeting-status
              meeting-id 'in-progress project)
             :type 'user-error)
            (let* ((cancel-meeting
                    (perinf-storage-create
                     'meeting
                     '((title . "Cancelled meeting")
                       (date . "2026-08-13")
                       (start-time . "10:00:00"))
                     project))
                   (cancelled
                    (perinf-storage-set-meeting-status
                     (perinf-object-id cancel-meeting)
                     'cancelled project)))
              (should (eq (perinf-object-status cancelled) 'cancelled))
              (should-error
               (perinf-storage-set-meeting-status
                (perinf-object-id cancel-meeting) 'planned project)
               :type 'user-error))))
      (delete-directory parent t))))

(ert-deftest perinf-test-audio-is-managed-and-linked-to-meeting ()
  (let* ((parent (make-temp-file "perinf-audio-test-" t))
         (project (expand-file-name "audio-project" parent))
         (source (expand-file-name "recording.m4a" parent))
         (transcript-source
          (expand-file-name "recording-transcript.txt" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Audio" 'da 'day-month-year-dash
           'twenty-four-hour)
          (with-temp-file source
            (set-buffer-multibyte nil)
            (insert "test-audio-data"))
          (with-temp-file transcript-source
            (insert "Velkommen til mødet.\nDagsordenen blev godkendt.\n"))
          (let* ((meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Bestyrelsesmøde")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (audio
                  (perinf-storage-attach-audio
                   (perinf-object-id meeting) source project))
                 (stored-audio
                  (car (perinf-storage-list 'audio-recording project)))
                 (updated-meeting
                  (car (perinf-storage-list 'meeting project)))
                 (managed-file
                  (expand-file-name
                   (alist-get
                    'FILE_REFERENCE
                    (perinf-object-properties stored-audio))
                   project)))
            (should (eq (perinf-object-type audio) 'audio-recording))
            (should (equal (perinf-object-id stored-audio)
                           (perinf-object-id audio)))
            (should (file-regular-p managed-file))
            (should
             (equal
              (perinf-storage--file-sha256 source)
              (alist-get
               'CHECKSUM_SHA256
               (perinf-object-properties stored-audio))))
            (should
             (equal
              (alist-get
               'AUDIO_ID
               (perinf-object-properties updated-meeting))
              (perinf-object-id audio)))
            (should
             (equal
              (alist-get
               'AUDIO_STATUS
               (perinf-object-properties updated-meeting))
              "available"))
            (let* ((transcript
                    (perinf-storage-import-transcript
                     (perinf-object-id meeting)
                     transcript-source
                     project))
                   (stored-transcript
                    (car (perinf-storage-list 'transcript project)))
                   (meeting-with-transcript
                    (car (perinf-storage-list 'meeting project))))
              (should (eq (perinf-object-type transcript) 'transcript))
              (should (equal (perinf-object-id stored-transcript)
                             (perinf-object-id transcript)))
              (should
               (equal
                (alist-get
                 'TRANSCRIPT_ID
                 (perinf-object-properties meeting-with-transcript))
                (perinf-object-id transcript)))
              (should
               (with-temp-buffer
                 (insert-file-contents (perinf-object-file transcript))
                 (search-forward "Dagsordenen blev godkendt." nil t)))
              (should
               (equal
                (perinf-storage-transcript-content stored-transcript)
                (concat "Velkommen til mødet.\n"
                        "Dagsordenen blev godkendt."))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-generated-minutes-require-human-approval ()
  (let* ((parent (make-temp-file "perinf-minutes-test-" t))
         (project (expand-file-name "minutes-project" parent))
         (audio-source (expand-file-name "recording.m4a" parent))
         (transcript-source (expand-file-name "transcript.txt" parent))
         (minutes-source (expand-file-name "minutes.txt" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Minutes" 'en 'iso 'twenty-four-hour)
          (with-temp-file audio-source (insert "audio"))
          (with-temp-file transcript-source (insert "Raw statement."))
          (with-temp-file minutes-source
            (insert "Automatically generated summary."))
          (let* ((meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Approval meeting")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (meeting-id (perinf-object-id meeting)))
            (perinf-storage-attach-audio meeting-id audio-source project)
            (perinf-storage-import-transcript
             meeting-id transcript-source project)
            (let* ((draft
                    (perinf-storage-import-generated-minutes
                     meeting-id minutes-source project)))
              (should-error
               (perinf-storage-approve-minutes
                (perinf-object-id draft) "Niels" project)
               :type 'user-error)
              (let* ((submitted
                      (perinf-storage-submit-minutes
                       (perinf-object-id draft) "Referenten" project))
                     (work-view
                      (let ((perinf-current-project
                             (file-name-as-directory project))
                            (perinf-interface-language 'en))
                        (perinf-i18n-load-locales)
                        (with-temp-buffer
                          (perinf-mode)
                          (setq perinf-current-view 'work)
                          (perinf-core--render)
                          (buffer-string))))
                     (home-view
                      (let ((perinf-current-project
                             (file-name-as-directory project))
                            (perinf-interface-language 'en))
                        (perinf-i18n-load-locales)
                        (with-temp-buffer
                          (perinf-mode)
                          (setq perinf-current-view 'home)
                          (perinf-core--render)
                          (buffer-string))))
                     (rejected
                      (perinf-storage-reject-minutes
                       (perinf-object-id draft)
                       "Formanden"
                       "Beslutningen mangler."
                       project))
                     (resubmitted
                      (perinf-storage-submit-minutes
                       (perinf-object-id draft) "Referenten" project))
                     (_tampered
                      (with-temp-buffer
                        (insert-file-contents (perinf-object-file draft))
                        (goto-char (point-min))
                        (search-forward "Automatically generated summary.")
                        (replace-match "Reviewed and corrected summary." t t)
                        (write-region
                         (point-min) (point-max)
                         (perinf-object-file draft) nil 'silent)))
                     (_changed-approval
                      (should-error
                       (perinf-storage-approve-minutes
                        (perinf-object-id draft) "Niels" project)
                       :type 'user-error))
                     (_rejected-after-change
                      (perinf-storage-reject-minutes
                       (perinf-object-id draft)
                       "Formanden"
                       "Den ændrede tekst skal genindsendes."
                       project))
                     (_submitted-after-change
                      (perinf-storage-submit-minutes
                       (perinf-object-id draft) "Referenten" project))
                   (approved
                    (perinf-storage-approve-minutes
                     (perinf-object-id draft) "Niels" project))
                   (sourced-decision
                    (perinf-storage-create
                     'decision
                     `((title . "Approve the annual plan")
                       (date . "2026-08-12")
                       (rationale . "Recorded in the approved minutes.")
                       (meeting-id . ,meeting-id)
                       (minutes-id . ,(perinf-object-id approved)))
                     project))
                   (sourced-task
                    (perinf-storage-create
                     'task
                     `((title . "Implement the approved plan")
                       (decision-id
                        . ,(perinf-object-id sourced-decision))
                       (meeting-id . ,meeting-id)
                       (minutes-id . ,(perinf-object-id approved)))
                     project))
                   (decision-detail-view
                    (let ((perinf-current-project
                           (file-name-as-directory project))
                          (perinf-interface-language 'en))
                      (perinf-i18n-load-locales)
                      (with-temp-buffer
                        (perinf-mode)
                        (setq perinf-current-view 'detail
                              perinf-selected-object sourced-decision)
                        (perinf-core--render)
                        (buffer-string))))
                   (updated-meeting
                    (car (perinf-storage-list 'meeting project)))
                   (records-view
                    (let ((perinf-current-project
                           (file-name-as-directory project))
                          (perinf-interface-language 'en))
                      (perinf-i18n-load-locales)
                      (with-temp-buffer
                        (perinf-mode)
                        (setq perinf-current-view 'records)
                        (perinf-core--render)
                        (buffer-string))))
                   (minutes-detail-view
                    (let ((perinf-current-project
                           (file-name-as-directory project))
                          (perinf-interface-language 'en))
                      (perinf-i18n-load-locales)
                      (with-temp-buffer
                        (perinf-mode)
                        (setq perinf-current-view 'detail
                              perinf-selected-object approved)
                        (perinf-core--render)
                        (buffer-string))))
                   (meeting-detail-view
                    (let ((perinf-current-project
                           (file-name-as-directory project))
                          (perinf-interface-language 'en))
                      (perinf-i18n-load-locales)
                      (with-temp-buffer
                        (perinf-mode)
                        (setq perinf-current-view 'detail
                              perinf-selected-object updated-meeting)
                        (perinf-core--render)
                        (buffer-string)))))
              (should (eq (perinf-object-status draft) 'ai-draft))
              (should (eq (perinf-object-status submitted)
                          'awaiting-final-approval))
              (should (string-match-p
                       "Minutes awaiting final approval" work-view))
              (should (string-match-p
                       "Draft minutes — Approval meeting" work-view))
              (should (string-match-p "Approve minutes" work-view))
              (should (string-match-p "Raw transcripts: 1" home-view))
              (should (string-match-p "Minutes: 1" home-view))
              (should (string-match-p
                       "Minutes awaiting final approval: 1" home-view))
              (should (eq (perinf-object-status rejected) 'rejected))
              (should (equal
                       (alist-get
                        'REJECTION_REASON
                        (perinf-object-properties rejected))
                       "Beslutningen mangler."))
              (should (eq (perinf-object-status resubmitted)
                          'awaiting-final-approval))
              (should (equal
                       (alist-get
                        'SUBMITTED_BY
                        (perinf-object-properties submitted))
                       "Referenten"))
              (should (equal
                       (perinf-storage-minutes-content draft)
                       "Reviewed and corrected summary."))
              (should (eq (perinf-object-status approved)
                          'final-approved))
              (should (equal
                       (alist-get
                        'APPROVED_BY (perinf-object-properties approved))
                       "Niels"))
              (should (equal
                       (alist-get
                        'APPROVED_CONTENT_CHECKSUM_SHA256
                        (perinf-object-properties approved))
                       (alist-get
                        'CONTENT_CHECKSUM_SHA256
                       (perinf-object-properties approved))))
              (should (equal
                       (alist-get
                        'MEETING_ID
                        (perinf-object-properties sourced-decision))
                       meeting-id))
              (should (equal
                       (alist-get
                        'MINUTES_ID
                        (perinf-object-properties sourced-decision))
                       (perinf-object-id approved)))
              (should (equal
                       (alist-get
                        'MEETING_ID
                        (perinf-object-properties sourced-task))
                       meeting-id))
              (should (string-match-p
                       "Tasks from this decision"
                       decision-detail-view))
              (should (string-match-p
                       "Implement the approved plan"
                       decision-detail-view))
              (should (string-match-p
                       "Decisions from this meeting"
                       meeting-detail-view))
              (should (string-match-p
                       "Approve the annual plan"
                       meeting-detail-view))
              (should (string-match-p
                       "Tasks from this meeting"
                       meeting-detail-view))
              (should (string-match-p
                       "Implement the approved plan"
                       meeting-detail-view))
              (should (string-match-p
                       "Register decision from these minutes"
                       minutes-detail-view))
              (should (string-match-p
                       "Decisions from these minutes"
                       minutes-detail-view))
              (should (string-match-p
                       "Approve the annual plan"
                       minutes-detail-view))
              (should (string-match-p
                       "Tasks from these minutes"
                       minutes-detail-view))
              (should (string-match-p
                       "Implement the approved plan"
                       minutes-detail-view))
              (should (equal
                       (alist-get
                        'MINUTES_STATUS
                        (perinf-object-properties updated-meeting))
                       "final-approved"))
              (should (string-match-p "Raw transcripts" records-view))
              (should (string-match-p "Raw transcript" records-view))
              (should (string-match-p
                       "Draft minutes — Approval meeting" records-view))
              (should (string-match-p
                       "Human-approved final version" records-view))
              (let* ((perinf-current-project
                      (file-name-as-directory project))
                     (results
                      (perinf-core--search-objects "Approval meeting"))
                     (types (mapcar #'perinf-object-type results)))
                (should (= (length results) 3))
                (should (memq 'meeting types))
                (should (memq 'transcript types))
                (should (memq 'minutes types)))
              (should
               (with-temp-buffer
                 (insert-file-contents (perinf-object-file approved))
                 (and (search-forward ":REVIEW_EVENT:   rejected" nil t)
                      (search-forward ":REVIEW_EVENT:   submitted" nil t)
                      (search-forward
                       ":REVIEW_EVENT:   approved" nil t))))
              (let ((events
                     (perinf-storage-list-review-events approved)))
                (should
                 (equal
                  (mapcar
                   (lambda (event) (alist-get 'event event))
                   events)
                  '("submitted" "rejected" "submitted"
                    "rejected" "submitted" "approved")))
                (should
                 (equal
                  (alist-get 'reason (nth 1 events))
                  "Beslutningen mangler.")))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-person-round-trip-through-storage-api ()
  (let* ((parent (make-temp-file "perinf-person-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Person test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'person
                   '((title . "Anne Jensen")
                     (email . "anne@example.dk")
                     (phone . "+45 12 34 56 78"))
                   project))
                 (people (perinf-storage-list 'person project))
                 (person (car people)))
            (should (string-prefix-p "person-" (perinf-object-id created)))
            (should (= (length people) 1))
            (should (equal (perinf-object-title person) "Anne Jensen"))
            (should (equal
                     (alist-get 'EMAIL
                                (perinf-object-properties person))
                     "anne@example.dk"))
            (should (equal
                     (alist-get 'PHONE
                                (perinf-object-properties person))
                     "+45 12 34 56 78"))))
      (delete-directory parent t))))

(ert-deftest perinf-test-decision-round-trip-records-and-search ()
  (let* ((parent (make-temp-file "perinf-decision-test-" t))
         (project (expand-file-name "project" parent))
         (perinf-interface-language 'en))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Decisions" 'en 'iso 'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'decision
                   '((title . "Adopt the annual plan")
                     (date . "2026-08-12")
                     (rationale . "The budget was approved."))
                   project))
                 (decisions (perinf-storage-list 'decision project))
                 (decision (car decisions))
                 (task
                  (perinf-storage-create
                   'task
                   `((title . "Implement the annual plan")
                     (decision-id . ,(perinf-object-id decision)))
                   project))
                 (person
                  (perinf-storage-create
                   'person '((title . "Anne Jensen")) project))
                 (assigned-task
                  (perinf-storage-assign-task
                   (perinf-object-id task)
                   (perinf-object-id person)
                   project))
                 (meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Planning meeting")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (_participant
                  (perinf-storage-add-child
                   (perinf-object-id meeting)
                   'participants
                   'participant
                   `((PERSON_ID . ,(perinf-object-id person))
                     (PARTICIPANT_ROLE . chair)
                     (ATTENDANCE_STATUS . invited))
                   project))
                 (perinf-current-project
                  (file-name-as-directory project)))
            (should (equal (perinf-object-id created)
                           (perinf-object-id decision)))
            (should (equal
                     (alist-get
                      'DECIDED_ON (perinf-object-properties decision))
                     "2026-08-12"))
            (should (equal
                     (alist-get
                      'RATIONALE (perinf-object-properties decision))
                     "The budget was approved."))
            (should
             (eq
              (perinf-object-type
               (car (perinf-core--search-objects "annual plan")))
              'decision))
            (should (equal
                     (alist-get
                      'DECISION_ID (perinf-object-properties task))
                     (perinf-object-id decision)))
            (should (equal
                     (alist-get
                      'ASSIGNEE_ID
                      (perinf-object-properties assigned-task))
                     (perinf-object-id person)))
            (perinf-i18n-load-locales)
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'records)
              (perinf-core--render)
              (should (string-match-p "Decisions" (buffer-string)))
              (should
               (string-match-p "Adopt the annual plan" (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'detail
                    perinf-selected-object decision)
              (perinf-core--render)
              (should
               (string-match-p
                "Create task from this decision" (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'detail
                    perinf-selected-object assigned-task)
              (perinf-core--render)
              (should (string-match-p
                       "Source decision: Adopt the annual plan"
                       (buffer-string)))
              (should
               (string-match-p "Responsible: Anne Jensen"
                               (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'work)
              (perinf-core--render)
              (should
               (string-match-p "Responsible: Anne Jensen"
                               (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'detail
                    perinf-selected-object person)
              (perinf-core--render)
              (should (string-match-p "Assigned tasks" (buffer-string)))
              (should
               (string-match-p
                "Implement the annual plan" (buffer-string)))
              (should (string-match-p "Meetings" (buffer-string)))
              (should (string-match-p "Planning meeting" (buffer-string)))
              (should (string-match-p "Chair" (buffer-string))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-context-round-trip-records-and-search ()
  (let* ((parent (make-temp-file "perinf-context-test-" t))
         (project (expand-file-name "project" parent))
         (perinf-interface-language 'en))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Contexts" 'en 'iso 'twenty-four-hour)
          (let* ((created
                  (perinf-storage-create
                   'context
                   '((title . "Municipal work")
                     (description . "Work involving the municipality."))
                   project))
                 (context
                  (car (perinf-storage-list 'context project)))
                 (task
                  (perinf-storage-create
                   'task '((title . "Call the municipality")) project))
                 (context-task
                  (perinf-storage-set-task-context
                   (perinf-object-id task)
                   (perinf-object-id context)
                   project))
                 (perinf-current-project
                  (file-name-as-directory project)))
            (should (equal (perinf-object-id created)
                           (perinf-object-id context)))
            (should (equal
                     (alist-get
                      'DESCRIPTION (perinf-object-properties context))
                     "Work involving the municipality."))
            (should (equal
                     (alist-get
                      'CONTEXT_ID
                      (perinf-object-properties context-task))
                     (perinf-object-id context)))
            (should
             (seq-find
              (lambda (object)
                (eq (perinf-object-type object) 'context))
              (perinf-core--search-objects "Municipal")))
            (perinf-i18n-load-locales)
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'records)
              (perinf-core--render)
              (should (string-match-p "Contexts" (buffer-string)))
              (should (string-match-p "Municipal work" (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'work)
              (perinf-core--render)
              (should
               (string-match-p "Context: Municipal work"
                               (buffer-string))))
            (with-temp-buffer
              (perinf-mode)
              (setq perinf-current-view 'detail
                    perinf-selected-object context)
              (perinf-core--render)
              (should
               (string-match-p "Tasks in this context" (buffer-string)))
              (should
               (string-match-p "Call the municipality"
                               (buffer-string))))))
      (delete-directory parent t))))

(ert-deftest perinf-test-add-person-to-meeting-by-stable-id ()
  (let* ((parent (make-temp-file "perinf-participant-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Participant test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((person
                  (perinf-storage-create
                   'person '((title . "Anne Jensen")) project))
                 (meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Bestyrelsesmøde")
                     (date . "2026-08-12")
                     (start-time . "14:00:00")
                     (finish-time . "16:00:00"))
                   project))
                 (participant-id
                  (perinf-storage-add-child
                   (perinf-object-id meeting)
                   'participants
                   'participant
                   `((PERSON_ID . ,(perinf-object-id person))
                     (PARTICIPANT_ROLE . secretary)
                     (ATTENDANCE_STATUS . invited))
                   project))
                 (participants
                  (perinf-storage-list-children
                   (perinf-object-id meeting) 'participants project))
                 (participant (car participants))
                 (attended
                  (perinf-storage-set-attendance
                   (perinf-object-id meeting)
                   participant-id
                   'attended
                   project)))
            (should (string-prefix-p "participant-" participant-id))
            (should (= (length participants) 1))
            (should (equal
                     (alist-get 'PERSON_ID
                                (perinf-object-properties participant))
                     (perinf-object-id person)))
            (should (eq
                     (alist-get 'PARTICIPANT_ROLE
                                (perinf-object-properties participant))
                     'secretary))
            (should (eq
                     (alist-get
                      'ATTENDANCE_STATUS
                      (perinf-object-properties attended))
                     'attended))
            (should-error
             (perinf-storage-set-attendance
              (perinf-object-id meeting)
              participant-id
              'unknown
              project)
             :type 'user-error)
            (let ((perinf-current-project
                   (file-name-as-directory project))
                  (perinf-interface-language 'da))
              (perinf-i18n-load-locales)
              (with-temp-buffer
                (perinf-mode)
                (setq perinf-current-view 'detail
                      perinf-selected-object
                      (car (perinf-storage-list 'meeting project)))
                (perinf-core--render)
                (should (string-match-p "Referent" (buffer-string)))
                (should (string-match-p "Deltog" (buffer-string))))
              (with-temp-buffer
                (perinf-mode)
                (setq perinf-current-view 'detail
                      perinf-selected-object
                      (car (perinf-storage-list 'person project)))
                (perinf-core--render)
                (should
                 (string-match-p "Bestyrelsesmøde" (buffer-string)))
                (should (string-match-p "Referent" (buffer-string)))
                (should (string-match-p "Deltog" (buffer-string)))))
            (should-error
             (perinf-storage-add-child
              (perinf-object-id meeting)
              'participants
              'participant
              `((PERSON_ID . ,(perinf-object-id person)))
              project)
             :type 'user-error)))
      (delete-directory parent t))))

(ert-deftest perinf-test-add-agenda-item-to-meeting ()
  (let* ((parent (make-temp-file "perinf-agenda-test-" t))
         (project (expand-file-name "project" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Agenda test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (let* ((meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Bestyrelsesmøde")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (item-id
                  (perinf-storage-add-child
                   (perinf-object-id meeting)
                   'agenda
                   'agenda-item
                   '((title . "Budget 2027")
                     (AGENDA_NUMBER . "3")
                     (AGENDA_KIND . decision))
                   project))
                 (items
                  (perinf-storage-list-children
                   (perinf-object-id meeting) 'agenda project))
                 (item (car items)))
            (should (string-prefix-p "agenda-item-" item-id))
            (should (= (length items) 1))
            (should (equal (perinf-object-title item) "Budget 2027"))
            (should (equal
                     (alist-get 'AGENDA_NUMBER
                                (perinf-object-properties item))
                     "3"))
            (should (eq
                     (alist-get 'AGENDA_KIND
                                (perinf-object-properties item))
                     'decision))
            (should-error
             (perinf-storage-add-child
              (perinf-object-id meeting)
              'agenda
              'agenda-item
              '((title . "Et andet punkt")
                (AGENDA_NUMBER . "3")
                (AGENDA_KIND . discussion))
              project)
             :type 'user-error)))
      (delete-directory parent t))))

(ert-deftest perinf-test-cancel-agenda-item-without-writing ()
  (let* ((parent (make-temp-file "perinf-agenda-cancel-test-" t))
         (project (expand-file-name "project" parent))
         (previously-bound (boundp 'perinf-current-project))
         (previous-project (and previously-bound perinf-current-project))
         (write-called nil))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Agenda cancel test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (setq perinf-current-project project)
          (cl-letf (((symbol-function 'read-string)
                     (lambda (&rest _arguments) ""))
                    ((symbol-function 'perinf-storage-add-child)
                     (lambda (&rest _arguments)
                       (setq write-called t))))
            (perinf-meeting-add-agenda-item "meeting-not-needed"))
          (should-not write-called))
      (if previously-bound
          (setq perinf-current-project previous-project)
        (makunbound 'perinf-current-project))
      (delete-directory parent t))))

(ert-deftest perinf-test-documents-are-managed-for-meeting-and-agenda-item ()
  (let* ((parent (make-temp-file "perinf-document-test-" t))
         (project (expand-file-name "project" parent))
         (source (expand-file-name "meeting-material.txt" parent)))
    (unwind-protect
        (progn
          (perinf-project-create
           project "Document test" 'da 'day-month-year-dash
           'twenty-four-hour)
          (with-temp-file source
            (insert "Controlled meeting material\n"))
          (let* ((meeting
                  (perinf-storage-create
                   'meeting
                   '((title . "Document meeting")
                     (date . "2026-08-12")
                     (start-time . "14:00:00"))
                   project))
                 (meeting-id (perinf-object-id meeting))
                 (item-id
                  (perinf-storage-add-child
                   meeting-id 'agenda 'agenda-item
                   '((title . "Documented item")
                     (AGENDA_NUMBER . "1")
                     (AGENDA_KIND . discussion))
                   project))
                 (meeting-document
                  (perinf-storage-attach-document
                   meeting-id nil source project))
                 (item-document
                  (perinf-storage-attach-document
                   meeting-id item-id source project))
                 (documents (perinf-storage-list 'document project)))
            (should (= (length documents) 2))
            (should (equal
                     (alist-get 'PARENT_TYPE
                                (perinf-object-properties meeting-document))
                     "meeting"))
            (should (equal
                     (alist-get 'AGENDA_ITEM_ID
                                (perinf-object-properties item-document))
                     item-id))
            (should (file-exists-p source))
            (dolist (document documents)
              (let ((properties (perinf-object-properties document)))
                (should (= (length (alist-get 'CHECKSUM_SHA256 properties)) 64))
                (should
                 (file-exists-p
                  (expand-file-name
                   (alist-get 'FILE_REFERENCE properties) project)))))))
      (delete-directory parent t))))

;;; perinf-test.el ends here
