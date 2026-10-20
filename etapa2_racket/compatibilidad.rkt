#lang typed/racket

(require "tipos.rkt")

(provide horarios-chocan?)

(: horarios-chocan? (-> Horario Horario Boolean))
(define (horarios-chocan? horario1 horario2)
  (and (string=? (Horario-dia horario1)
                 (Horario-dia horario2))
       (< (Horario-inicio horario1)
          (Horario-fin horario2))
       (< (Horario-inicio horario2)
          (Horario-fin horario1))))
