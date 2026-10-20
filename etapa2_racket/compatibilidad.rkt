#lang typed/racket

(require "tipos.rkt")

(provide horarios-chocan?
         grupos-chocan?)

(: horarios-chocan? (-> Horario Horario Boolean))
(define (horarios-chocan? horario1 horario2)
  (and (string=? (Horario-dia horario1)
                 (Horario-dia horario2))
       (< (Horario-inicio horario1)
          (Horario-fin horario2))
       (< (Horario-inicio horario2)
          (Horario-fin horario1))))

(: grupos-chocan? (-> Grupo Grupo Boolean))
(define (grupos-chocan? grupo1 grupo2)
  (ormap
   (lambda ([horario1 : Horario])
     (ormap
      (lambda ([horario2 : Horario])
        (horarios-chocan? horario1 horario2))
      (Grupo-horarios grupo2)))
   (Grupo-horarios grupo1)))