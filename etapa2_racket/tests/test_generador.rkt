#lang typed/racket

(require typed/rackunit
         typed/racket/stream
         "../generador.rkt"
         "../tipos.rkt")

(define a-g1 (Grupo "Computadores" "CE1101" 1 4
                    (list (Horario "LUN" 480 540))))
(define a-g2 (Grupo "Computadores" "CE1101" 2 0
                    (list (Horario "MAR" 480 540))))
(define otra-carrera (Grupo "Software" "CE1101" 1 4 '()))
(define b (Grupo "Computadores" "CE1102" 1 3 '()))
(define preferencias
  (Preferencias "Computadores"
                (list (IdGrupo "Computadores" "CE1101" 1)
                      (IdGrupo "Computadores" "CE1101" 2))
                0 18))

;; Cada grupo del curso es una alternativa, incluso si aporta cero créditos;
;; el mismo código en otra carrera no se confunde y los repetidos se ignoran.
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 a-g1 otra-carrera a-g2 b) preferencias))
              (list (Combinacion (list a-g1) 4)
                    (Combinacion (list a-g2) 0)))

;; Se puede consumir una alternativa sin convertir todo el stream en lista.
(check-equal? (stream-first (generar-combinaciones (list a-g1 a-g2) preferencias))
              (Combinacion (list a-g1) 4))

;; Sin grupos de interés habilitados no se emite la combinación vacía.
(check-true (stream-empty? (generar-combinaciones (list b) preferencias)))

;; c-choque se traslapa con a-g1; c-contiguo empieza justo cuando termina.
(define c-choque (Grupo "Computadores" "CE1102" 1 3
                        (list (Horario "LUN" 510 600))))
(define c-contiguo (Grupo "Computadores" "CE1102" 2 3
                          (list (Horario "LUN" 540 600))))

;; Varios cursos: el choque elimina solo la pareja afectada y los bloques
;; contiguos son compatibles.
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 a-g2 c-choque c-contiguo)
                (Preferencias "Computadores"
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1101" 2)
                                    (IdGrupo "Computadores" "CE1102" 1)
                                    (IdGrupo "Computadores" "CE1102" 2))
                              0 18)))
              (list (Combinacion (list c-choque) 3)
                    (Combinacion (list c-contiguo) 3)
                    (Combinacion (list a-g1) 4)
                    (Combinacion (list a-g1 c-contiguo) 7)
                    (Combinacion (list a-g2) 0)
                    (Combinacion (list a-g2 c-choque) 3)
                    (Combinacion (list a-g2 c-contiguo) 3)))

;; Un grupo con varios bloques choca aunque solo uno de ellos se traslape.
(define d-varios (Grupo "Computadores" "CE1103" 1 2
                        (list (Horario "MIE" 600 700)
                              (Horario "LUN" 530 560))))
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 d-varios)
                (Preferencias "Computadores"
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1103" 1))
                              0 18)))
              (list (Combinacion (list d-varios) 2)
                    (Combinacion (list a-g1) 4)))
