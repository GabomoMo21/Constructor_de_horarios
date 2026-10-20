#lang typed/racket

;; ============================================================
;; COMPATIBILIDAD DE HORARIOS
;; ============================================================

(require "tipos.rkt")

(provide horarios-chocan?
         grupos-chocan?)

;; ============================================================
;; 1. DETECCION DE CHOQUES ENTRE HORARIOS
;; ============================================================

(: horarios-chocan? (-> Horario Horario Boolean))
(define (horarios-chocan? horario1 horario2)
  (and (string=? (Horario-dia horario1)
                 (Horario-dia horario2))
       (< (Horario-inicio horario1)
          (Horario-fin horario2))
       (< (Horario-inicio horario2)
          (Horario-fin horario1))))

;; ============================================================
;; 2. DETECCION DE CHOQUES ENTRE GRUPOS
;; ============================================================

(: grupos-chocan? (-> Grupo Grupo Boolean))
(define (grupos-chocan? grupo1 grupo2)
  (ormap
   (lambda ([horario1 : Horario])
     (ormap
      (lambda ([horario2 : Horario])
        (horarios-chocan? horario1 horario2))
      (Grupo-horarios grupo2)))
   (Grupo-horarios grupo1)))