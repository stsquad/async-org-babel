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

(defmacro async-org-call (async-form)
  "Expands `ASYNC-FORM' as an asynchronus org-bable function.
If executed inside an org file will insert the results into the src
  blocks results.  Otherwise the result will be echoed to the Message
  buffer."

  (let ((result-buffer (buffer-name))
        (result-org-name (nth 4 (org-babel-get-src-block-info))))

    `(async-start

      ;; The result of the async-sexp is returned to the handler
      ;; as result.
      (lambda ()
        ,(async-inject-variables "async-form")
        (eval async-form))

      ;; This code runs in the current emacs process.
      (lambda (result)
        (let ((buf ,result-buffer)
              (org ,result-org-name))
          
          ;; Send the results somewhere
          (if (and buf org)
              (save-excursion
                (with-current-buffer buf
                  (org-babel-goto-named-result org)
                  (next-line)
                  (goto-char (org-babel-result-end))
                  (org-babel-insert-result (format "%s" result))))
            (message (pp (format "async-result: %s" result)))))))))

(provide 'async-org-babel)
;;; async-org-babel.el ends here

