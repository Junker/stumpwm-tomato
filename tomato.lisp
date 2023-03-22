;;;; tomato.lisp

(in-package #:tomato)

(defparameter *short-break-period* 5
  "Short break in minutes after almost every work period.")
(defparameter *long-break-period* 15
  "Long break in minutes after *max-tomatos* short breaks.")
(defparameter *work-period* 25
  "Amount of time in minutes of working before taking a break.")
(defparameter *postpone-period* 10
  "Amount of time in minutes to postpone the break.")
(defparameter *max-tomatos* 4
  "A long break will begin after *max-tomatos* tomatoes.")

(defvar *idle-check-interval-secs* 5)
(defvar *tomatos* 0
  "The total number of pomodoros done so far.")
(defvar *break-timer* (make-timer 'on-break-done :name 'work)
  "break timer object")
(defvar *work-timer* (make-timer 'on-work-done :name 'break)
  "work timer object")
(defvar *postpone-timer* (make-timer 'on-postpone-done :name 'postpone)
  "postpone timer object")
(defvar *idle-timer* (make-timer 'idle-check :name 'idle :thread t)
  "postpone timer object")
(defvar *last-work-done-timestamp* nil
  "time when last work-timer fired")

(defun min->sec (minutes)
  "Converts from minutes to seconds."
  (* minutes 60))

(defun sec->min (seconds)
  "Converts from seconds to minutes."
  (floor seconds 60))

(defun sec->time (seconds)
  (multiple-value-bind (minutes seconds) (floor seconds 60)
    (if (zerop minutes)
        (format nil "~As" seconds)
        (format nil "~Am" minutes))))


(defun is-break ()
  (timer-scheduled-p *break-timer*))

(defun is-work ()
  (timer-scheduled-p *work-timer*))

(defun is-postpone ()
  (timer-scheduled-p *postpone-timer*))

(defun get-state ()
  (cond ((is-work) 'work)
        ((is-break) 'break)
        ((is-postpone) 'postpone)))

(defun get-active-timer ()
  (cond ((is-work) *work-timer*)
        ((is-break) *break-timer*)
        ((is-postpone) *postpone-timer*)
        (t nil)))

(defun get-break-period ()
  (if (and (> *tomatos* *max-tomatos*) (= (mod *tomatos* *max-tomatos*) 1))
      *long-break-period*
      *short-break-period*))

(defun get-timer-time-left (timer)
  (- (SB-IMPL::%timer-expire-time timer) (get-internal-real-time)))

(defun get-time-left ()
  (when-let* ((tmr (get-active-timer))
              (time-left (get-timer-time-left tmr)))
    (if (is-postpone)
        (floor (- *last-work-done-timestamp* (get-internal-real-time)) internal-time-units-per-second)
        (floor time-left internal-time-units-per-second))))

(defun start-work (&optional force)
  (when (or (not (is-work)) force)
    (unschedule-timer *work-timer*)
    (unschedule-timer *break-timer*)
    (unschedule-timer *postpone-timer*)
    (schedule-timer *work-timer* (min->sec *work-period*))))

(defun start-break (&optional force)
  (when (or (not (is-break)) force)
    (let ((*suppress-echo-timeout* t))
      (message "TOMATO: BREAK IN PROCESS..."))
    (unschedule-timer *work-timer*)
    (unschedule-timer *postpone-timer*)
    (unschedule-timer *break-timer*)
    (schedule-timer *break-timer* (min->sec (get-break-period)))))

(defun start-postpone ()
  (when (is-break)
    (unschedule-timer *break-timer*)
    (unschedule-timer *work-timer*)
    (schedule-timer *postpone-timer* (min->sec *postpone-period*))))


(defun on-break-done ()
  (message "TOMATO: Break Finished!")
  (start-work))

(defun on-work-done ()
  (incf *tomatos*)
  (setf *last-work-done-timestamp* (get-internal-real-time))
  (start-break))

(defun on-postpone-done ()
  (start-break))

(defun idle-check ()
  (when (and (or (is-work) (is-postpone)) ; restart work-timer if idle-time longer than a break period
             (> (idle-time (current-screen)) (min->sec *short-break-period*)))
    (start-work t))
  (when (and (is-break) ; restart break-timer if break was interupted by some user activity
             (> (- (min->sec (get-break-period)) (get-time-left)) *idle-check-interval-secs*)
             (< (idle-time (current-screen)) *idle-check-interval-secs*))
    (start-break t)))

(defun modeline (&optional ml)
  (declare (ignore ml))
  (let* ((time-left (sec->time (get-time-left)))
         (ml-str (cond ((is-work) (format nil "~A" time-left))
                       ((is-postpone) (format nil "^(:fg \"#ffffff\")^(:bg \"#991111\")~A^n" time-left))
                       ((is-break) (format nil "^02~A^n" time-left)))))
    (if (fboundp 'stumpwm::format-with-on-click-id) ;check in case of old stumpwm version
        (format-with-on-click-id ml-str :ml-tomato-on-click nil)
        ml-str)))

(defun ml-on-click (code id &rest rest)
  (declare (ignore rest))
  (declare (ignore id))
  (let ((button (stumpwm::decode-button-code code)))
    (case button
      ((:left-button)
       (if (is-break)
           (start-postpone)))))
  (stumpwm::update-all-mode-lines))

(when (fboundp 'stumpwm::register-ml-on-click-id) ;check in case of old stumpwm version
  (register-ml-on-click-id :ml-tomato-on-click #'ml-on-click))


(defcommand tomato-work () ()
  (start-work))

(defcommand tomato-break () ()
  (start-break))

(defcommand tomato-postpone () ()
  (start-postpone))

(defcommand tomato-status () ()
  (message "State: ~A. Time left: ~Am" (get-state) (sec->min (get-time-left))))


;; INIT

;; formatters.
(add-screen-mode-line-formatter #\t 'modeline)

(schedule-timer *work-timer* (min->sec *work-period*))
(schedule-timer *idle-timer* *idle-check-interval-secs*
                :repeat-interval *idle-check-interval-secs*)
