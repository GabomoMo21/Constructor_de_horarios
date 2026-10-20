#lang typed/racket

(require typed/rackunit
         typed/racket/stream
         "../generador.rkt"
         "../tipos.rkt")

(define a-p1 (Grupo "Computadores" "CE1101" 1 1 4
                    (list (Horario "LUN" 480 540))))
(define a-p2 (Grupo "Computadores" "CE1101" 2 1 0
                    (list (Horario "MAR" 480 540))))
(define otra-carrera (Grupo "Software" "CE1101" 1 1 4 '()))
(define b (Grupo "Computadores" "CE1102" 1 1 3 '()))
(define preferencias
  (Preferencias "Computadores"
                (list (IdGrupo "Computadores" "CE1101" 1 1)
                      (IdGrupo "Computadores" "CE1101" 2 1))
                0 18))

;; Cada grupo del curso es una alternativa, incluso si comparte número
;; de grupo con otro período o aporta cero créditos.
(check-equal? (stream->list
               (generar-combinaciones
                (list a-p1 a-p1 otra-carrera a-p2 b) preferencias))
              (list (Combinacion (list a-p1) 4)
                    (Combinacion (list a-p2) 0)))

;; Sin grupos de interés habilitados no se emite la combinación vacía.
(check-true (stream-empty? (generar-combinaciones (list b) preferencias)))

;; No devolver una búsqueda parcial cuando haya varios cursos de interés.
(check-exn exn:fail?
           (lambda ()
             (generar-combinaciones
              (list a-p1 b)
              (Preferencias "Computadores"
                            (list (IdGrupo "Computadores" "CE1101" 1 1)
                                  (IdGrupo "Computadores" "CE1102" 1 1))
                            0 18))))
