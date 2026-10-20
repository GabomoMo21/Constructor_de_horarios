#lang typed/racket

(require racket/stream
         "tipos.rkt")

(provide filtrar-stream
         creditos-validos?
         filtrar-por-creditos)

;; Filtra un stream usando una condicion que recibe cada elemento.
(: filtrar-stream
   (All (A) (-> (-> A Boolean)
                (Streamof A)
                (Streamof A))))
(define (filtrar-stream condicion elementos)
  (stream-filter condicion elementos))

;; Revisa que los creditos esten dentro del rango, incluyendo los limites.
(: creditos-validos? (-> Combinacion Integer Integer Boolean))
(define (creditos-validos? combinacion minimo maximo)
  (and (>= (Combinacion-creditos-totales combinacion) minimo)
       (<= (Combinacion-creditos-totales combinacion) maximo)))

;; Aplica el rango de creditos a las combinaciones del stream.
(: filtrar-por-creditos
   (-> (Streamof Combinacion) Integer Integer (Streamof Combinacion)))
(define (filtrar-por-creditos combinaciones minimo maximo)
  (filtrar-stream
   (lambda ([combinacion : Combinacion])
     (creditos-validos? combinacion minimo maximo))
   combinaciones))
