#lang typed/racket

(require racket/stream
         typed/json
         "tipos.rkt")

(provide exportar-combinaciones)

(: grupo->json (-> Grupo JSExpr))
(define (grupo->json grupo)
  (hash 'carrera (Grupo-carrera grupo)
        'codigo (Grupo-codigo grupo)
        'periodo (Grupo-periodo grupo)
        'grupo (Grupo-numero grupo)))

(: combinacion->json (-> Combinacion JSExpr))
(define (combinacion->json combinacion)
  (hash 'creditos_totales (Combinacion-creditos-totales combinacion)
        'selecciones (map grupo->json (Combinacion-grupos combinacion))))

;; Escribe las combinaciones sin convertir el stream en una lista.
(: escribir-combinaciones (-> (Streamof Combinacion) Boolean Void))
(define (escribir-combinaciones combinaciones primero?)
  (cond
    [(stream-empty? combinaciones) (void)]
    [else
     (if primero? (void) (display ","))
     (write-json (combinacion->json (stream-first combinaciones)))
     (escribir-combinaciones (stream-rest combinaciones) #f)]))

(: exportar-combinaciones (-> Path-String (Streamof Combinacion) Void))
(define (exportar-combinaciones ruta combinaciones)
  (with-output-to-file ruta
    (lambda ()
      (display "{\"combinaciones\":[")
      (escribir-combinaciones combinaciones #t)
      (display "]}")
      (void))
    #:exists 'replace))
