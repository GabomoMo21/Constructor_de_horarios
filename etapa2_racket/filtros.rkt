#lang typed/racket

(require typed/racket/stream
         "tipos.rkt")

(provide filtrar-stream
         creditos-validos?
         filtrar-por-creditos)

;; Permite filtrar streams con distintas condiciones.
(: filtrar-stream
   (All (A) (-> (-> A Boolean) (Sequenceof A) (Sequenceof A))))
(define (filtrar-stream condicion elementos)
  (stream-filter condicion elementos))

(: creditos-validos? (-> Combinacion Integer Integer Boolean))
(define (creditos-validos? combinacion minimo maximo)
  (and (>= (Combinacion-creditos-totales combinacion) minimo)
       (<= (Combinacion-creditos-totales combinacion) maximo)))

(: filtrar-por-creditos
   (-> (Sequenceof Combinacion) Integer Integer (Sequenceof Combinacion)))
(define (filtrar-por-creditos combinaciones minimo maximo)
  (filtrar-stream
   (lambda ([combinacion : Combinacion])
     (creditos-validos? combinacion minimo maximo))
   combinaciones))
