;;;; tomato.asd

(asdf:defsystem #:tomato
  :description "Advanced Pomodoro timer module for StumpWM"
  :author "Dmitrii Kosenkov"
  :license  "GPLv3"
  :version "0.2.0"
  :serial t
  :depends-on (#:stumpwm)
  :components ((:file "package")
               (:file "tomato")))
