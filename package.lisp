;;;; package.lisp

(defpackage #:tomato
	(:use #:cl #:stumpwm #:alexandria)
  (:import-from #:sb-ext
                #:schedule-timer
                #:unschedule-timer
                #:make-timer
                #:timer-scheduled-p)
  (:export #:modeline
           #:start-work
           #:start-break
           #:start-postpone
           #:get-state
           #:*short-break-period*
           #:*long-break-period*
           #:*work-period*
           #:*postpone-period*
           #:*max-tomatos*))
