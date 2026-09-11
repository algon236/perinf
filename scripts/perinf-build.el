;;; perinf-build.el --- Local build and installation tools -*- lexical-binding: t; -*-

(require 'package)
(require 'loaddefs-gen)
(require 'bytecomp)

(defconst perinf-build-root
  (file-name-directory (directory-file-name (file-name-directory load-file-name))))

(defun perinf-build-files ()
  "Return runtime source files, excluding generated package metadata."
  (delete (expand-file-name "perinf-pkg.el" perinf-build-root)
          (directory-files perinf-build-root t "\\`perinf.*\\.el\\'")))

(defun perinf-build-copy (destination)
  "Copy runtime sources to DESTINATION and generate autoloads."
  (make-directory destination t)
  (dolist (file (perinf-build-files))
    (copy-file file (expand-file-name (file-name-nondirectory file) destination) t))
  (copy-file (expand-file-name "LICENSE" perinf-build-root)
             (expand-file-name "LICENSE" destination) t)
  (loaddefs-generate destination (expand-file-name "perinf-autoloads.el" destination)))

(defun perinf-build-compile ()
  "Check and compile a temporary copy without writing into the source tree."
  (let* ((temporary (make-temp-file "perinf-compile-" t))
         (load-path (cons temporary load-path))
         (byte-compile-error-on-warn t))
    (unwind-protect
        (progn
          (perinf-build-copy temporary)
          (dolist (source (directory-files temporary t "\\.el\\'"))
            (with-temp-buffer
              (insert-file-contents source)
              (emacs-lisp-mode)
              (check-parens))
            (unless (byte-compile-file source)
              (error "Compilation failed: %s" source))))
      (delete-directory temporary t))))

(defun perinf-build-install ()
  "Install under user-emacs-directory/lisp/perinf, creating directories."
  (let ((destination
         (expand-file-name "lisp/perinf/"
                           (or (getenv "PERINF_EMACS_DIRECTORY")
                               user-emacs-directory))))
    (perinf-build-copy destination)
    ;; Old bytecode must not shadow an updated source installation.
    (dolist (source (perinf-build-files))
      (let ((compiled (expand-file-name
                       (concat (file-name-nondirectory source) "c") destination)))
        (when (file-exists-p compiled) (delete-file compiled))))
    (message "Installed PerInf in %s" destination)))

(defun perinf-build-package ()
  "Build a source archive in a clean temporary staging directory."
  (let* ((version (with-temp-buffer
                    (insert-file-contents
                     (expand-file-name "perinf.el" perinf-build-root))
                    (package-version-join
                     (package-desc-version (package-buffer-info)))))
         (name (concat "perinf-" version))
         (staging (make-temp-file "perinf-package-" t))
         (target (expand-file-name name staging))
         (dist (expand-file-name "dist" perinf-build-root))
         (process-environment (cons "COPYFILE_DISABLE=1" process-environment)))
    (unwind-protect
        (progn
          (make-directory target t)
          (make-directory dist t)
          (dolist (file (append (perinf-build-files)
                               (list (expand-file-name "perinf-pkg.el" perinf-build-root)
                                     (expand-file-name "LICENSE" perinf-build-root))))
            (copy-file file (expand-file-name (file-name-nondirectory file) target)))
          (unless (zerop (call-process
                         "tar" nil "*perinf-package-build*" nil "-C" staging "-cf"
                         (expand-file-name (concat name ".tar") dist) name))
            (error "Archive creation failed; inspect *perinf-package-build*")))
      (delete-directory staging t))))
