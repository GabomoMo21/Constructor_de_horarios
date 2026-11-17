#lang racket

(require rackunit
         racket/stream
         racket/file
         json
         "../tipos.rkt"
         "../filtros.rkt"
         "../exportador.rkt")

(define grupo-a
  (Grupo "Ingeniería en Computadores" "CE1101" 1 3
         (list (Horario "LUN" 480 600)) "computacion"))
(define grupo-b
  (Grupo "Ingeniería en Computadores" "MA1102" 2 4
         (list (Horario "MAR" 540 660)) "matematica"))
(define grupo-c
  (Grupo "Ingeniería en Computadores" "CE1103" 1 8
         (list (Horario "MIE" 480 600)) "computacion"))

(define combinacion-3 (Combinacion (list grupo-a) 3))
(define combinacion-7 (Combinacion (list grupo-a grupo-b) 7))
(define combinacion-8 (Combinacion (list grupo-c) 8))

;; Se comprueba el rango de creditos
(check-true (creditos-validos? combinacion-3 3 7))
(check-true (creditos-validos? combinacion-7 3 7))
(check-false (creditos-validos? combinacion-8 3 7))
(check-false (creditos-validos? combinacion-3 4 7))
(check-equal?
 (stream->list
  (filtrar-por-creditos
   (stream combinacion-3 combinacion-7 combinacion-8) 3 7))
 (list combinacion-3 combinacion-7))

;; El filtro funciona con diferentes tipos de datos
(check-equal?
 (stream->list (filtrar-stream even? (stream 1 2 3 4)))
 '(2 4))
(check-equal?
 (stream->list
  (filtrar-stream (lambda (texto) (> (string-length texto) 3))
                 (stream "sol" "luna" "casa")))
 '("luna" "casa"))

;; Se comprueba la salida JSON
(define ruta-prueba (make-temporary-file "cemestre-p4-~a.json"))

(exportar-combinaciones ruta-prueba empty-stream)
(check-equal?
 (call-with-input-file ruta-prueba read-json)
 (hasheq 'combinaciones '()))

(exportar-combinaciones ruta-prueba (stream combinacion-7))
(check-equal?
 (call-with-input-file ruta-prueba read-json)
 (hasheq 'combinaciones
       (list
        (hasheq 'creditos_totales 7
              'selecciones
              (list
               (hasheq 'carrera "Ingeniería en Computadores"
                     'codigo "CE1101"
                     'grupo 1
                     'creditos 3
                     'area "computacion")
               (hasheq 'carrera "Ingeniería en Computadores"
                     'codigo "MA1102"
                     'grupo 2
                     'creditos 4
                     'area "matematica"))))))

(delete-file ruta-prueba)
