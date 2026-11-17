#lang typed/racket

(require typed/rackunit
         typed/racket/stream
         "../generador.rkt"
         "../tipos.rkt")

(define a-g1 (Grupo "Computadores" "CE1101" 1 4
                    (list (Horario "LUN" 480 540)) "computacion"))
(define a-g2 (Grupo "Computadores" "CE1101" 2 0
                    (list (Horario "MAR" 480 540)) "computacion"))
(define otra-carrera (Grupo "Software" "CE1101" 1 4 '() "computacion"))
(define b (Grupo "Computadores" "CE1102" 1 3 '() "computacion"))
(define preferencias
  (Preferencias
                (list (IdGrupo "Computadores" "CE1101" 1)
                      (IdGrupo "Computadores" "CE1101" 2))
                0 18))

;; Los grupos repetidos se ignoran y cada grupo es una alternativa
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 a-g1 otra-carrera a-g2 b) preferencias))
              (list (Combinacion (list a-g1) 4)
                    (Combinacion (list a-g2) 0)))

;; Se puede obtener la primera combinacion sin recorrer las demas
(check-equal? (stream-first (generar-combinaciones (list a-g1 a-g2) preferencias))
              (Combinacion (list a-g1) 4))

;; No se genera una combinacion vacia
(check-true (stream-empty? (generar-combinaciones (list b) preferencias)))

;; Un horario contiguo no cuenta como choque
(define c-choque (Grupo "Computadores" "CE1102" 1 3
                        (list (Horario "LUN" 510 600)) "computacion"))
(define c-contiguo (Grupo "Computadores" "CE1102" 2 3
                          (list (Horario "LUN" 540 600)) "computacion"))

;; Las combinaciones con choque se descartan
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 a-g2 c-choque c-contiguo)
                (Preferencias
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

;; Se comprueban todos los bloques de horario
(define d-varios (Grupo "Computadores" "CE1103" 1 2
                        (list (Horario "MIE" 600 700)
                              (Horario "LUN" 530 560)) "computacion"))
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 d-varios)
                (Preferencias
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1103" 1))
                              0 18)))
              (list (Combinacion (list d-varios) 2)
                    (Combinacion (list a-g1) 4)))

;; Repetir preferencias no duplica combinaciones
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 b)
                (Preferencias
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1102" 1))
                              0 18)))
              (list (Combinacion (list b) 3)
                    (Combinacion (list a-g1) 4)
                    (Combinacion (list a-g1 b) 7)))

;; Los grupos que no existen se ignoran
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1)
                (Preferencias
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Computadores" "CE1101" 3)
                                    (IdGrupo "Computadores" "CE1104" 1))
                              0 18)))
              (list (Combinacion (list a-g1) 4)))

;; Un mismo codigo de carreras distintas se puede combinar
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 otra-carrera)
                (Preferencias
                              (list (IdGrupo "Computadores" "CE1101" 1)
                                    (IdGrupo "Software" "CE1101" 1))
                              0 18)))
              (list (Combinacion (list otra-carrera) 4)
                    (Combinacion (list a-g1) 4)
                    (Combinacion (list a-g1 otra-carrera) 8)))
(check-equal? (stream->list
               (generar-combinaciones
                (list a-g1 otra-carrera)
                (Preferencias
                              (list (IdGrupo "Software" "CE1101" 1))
                              0 18)))
              (list (Combinacion (list otra-carrera) 4)))

;; Cada combinacion debe tener cursos distintos y creditos correctos
(: curso-de (-> Grupo (Pairof String String)))
(define (curso-de grupo)
  (cons (Grupo-carrera grupo) (Grupo-codigo grupo)))

(define todas
  (stream->list
   (generar-combinaciones
    (list a-g1 a-g2 b c-choque c-contiguo d-varios)
    (Preferencias
                  (list (IdGrupo "Computadores" "CE1101" 1)
                        (IdGrupo "Computadores" "CE1101" 2)
                        (IdGrupo "Computadores" "CE1102" 1)
                        (IdGrupo "Computadores" "CE1102" 2)
                        (IdGrupo "Computadores" "CE1103" 1))
                  0 18))))

(check-equal? (length todas) (length (remove-duplicates todas)))
(check-true
 (andmap (lambda ([combinacion : Combinacion])
           (define grupos (Combinacion-grupos combinacion))
           (and (not (empty? grupos))
                (= (length grupos)
                   (length (remove-duplicates (map curso-de grupos))))
                (= (Combinacion-creditos-totales combinacion)
                   (apply + (map Grupo-creditos grupos)))))
         todas))
