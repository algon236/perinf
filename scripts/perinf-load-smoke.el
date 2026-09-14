;;; perinf-load-smoke.el --- Fresh-process load check -*- lexical-binding: t; -*-
;; Simulate interactive loading: the original code skipped its timer in batch.
(let ((noninteractive nil))
  (require 'perinf))
(dolist (hook '(find-file-hook after-change-major-mode-hook post-command-hook))
  (dolist (function (symbol-value hook))
    (when (and (symbolp function)
               (string-prefix-p "perinf-" (symbol-name function)))
      (error "PerInf changed %s during loading" hook))))
(when (or perinf-task-activity-mode perinf-task-inactivity-check-timer)
  (error "Loading enabled background activity"))
(let ((perinf-interface-language 'da))
  (condition-case err
      (perinf-i18n-user-error "Invalid date: %s" "example")
    (user-error
     (unless (equal (error-message-string err) "Ugyldig dato: example")
       (error "Danish lazy initialization failed: %S" err)))))
(perinf-task-activity-mode 1)
(let ((timer perinf-task-inactivity-check-timer))
  (unload-feature 'perinf-task t)
  (when (memq timer timer-list)
    (error "Unloading left the timer running")))
(princ "FRESH-LOAD-LOCALE-AND-UNLOAD-OK\n")
