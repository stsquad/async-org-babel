;;; async-org-babel --- A set of macros for async execution of org-babel code
;;; -*- lexical-binding: t -*--
;;
;; Copyright (C) 2014 Alex Bennée
;;
;; Author: Alex Bennée <alex@bennee.com>
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;;; Commentary:
;;
;; This provides some simple wrappers around the async library so
;; babel blocks can be run in inferior emacsen without hanging the main
;; process.
;;
;;; Code:

;; Require prerequisites

(require 'async)

;; Variables

;; Code

;; It's important to realise we can't have our exact same environment
;; in the inferior emacs. Any state the needs to be passed in
;; explicitly. Currently that is all done within the async-form sexp.

(defmacro async-org-call (async-form &optional post-form)
  "Expands `ASYNC-FORM' as an asynchronus org-bable function.
If executed inside an org file will insert the results into the src
  blocks results.  Otherwise the result will be echoed to the Message
  buffer. An optional `POST-FORM' can concatenate results to the async
  forms."

  (let ((async-sexp async-form)

        ;; these are only needed for results handling
        (result-buffer (buffer-name))
        (result-org-name (nth 4 (org-babel-get-src-block-info))))

    `(async-start

      ;; The result of the async-sexp is returned to the handler
      ;; as result.
      (lambda ()
        ,(async-inject-variables "async-sexp")
        (eval async-sexp))

      ;; This code runs in the current emacs process.
      (lambda (result)
        (message "We have %s/%s" result-buffer result-org-name)

        ;; Do we have a post-form to execute?
        (when ,post-form
          (setq result (append
                        (if (listp result)
                           result
                         (list (cons 'async-form result)))
                       (list (cons 'post-form (eval ,post-form))))))

          ;; Send the results somewhere
          (if (and result-buffer result-org-name)
              (save-excursion
                (message
                 "sending result to: %s/%s (%s)"
                 result-buffer result-org-name)
                (with-current-buffer result-buffer
                  (org-babel-goto-named-result result-org-name)
                  (next-line)
                  (goto-char (org-babel-result-end))
                  (org-babel-insert-result (format "%s" result))))
            (message (pp (format "async-result: %s" result))))))))

(provide 'async-org-babel)
;;; async-org-babel.el ends here

