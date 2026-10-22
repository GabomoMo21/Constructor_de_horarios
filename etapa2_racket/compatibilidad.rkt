#lang typed/racket

;; ============================================================
;; COMPATIBILIDAD DE HORARIOS
;; ============================================================

(require "tipos.rkt")

(provide horarios-chocan?
         grupos-chocan?
         compatible-con-combinacion?)

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

;; ============================================================
;; 3. COMPATIBILIDAD CON GRUPOS SELECCIONADOS
;; ============================================================

(: compatible-con-combinacion?
   (-> Grupo (Listof Grupo) Boolean))

(define (compatible-con-combinacion? grupo elegidos)
  (andmap
   (lambda ([seleccionado : Grupo])
     (and
      (not (grupos-chocan? grupo seleccionado))
      (not
       (and (string=? (Grupo-carrera grupo)
                      (Grupo-carrera seleccionado))
            (string=? (Grupo-codigo grupo)
                      (Grupo-codigo seleccionado))))))
   elegidos))