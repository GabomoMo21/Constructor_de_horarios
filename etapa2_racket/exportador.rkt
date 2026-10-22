#lang typed/racket

(require typed/racket/stream
         typed/json
         "tipos.rkt")

(provide exportar-combinaciones)

(: escribir-grupo (-> Grupo Void))
(define (escribir-grupo grupo)
  (display "{\"carrera\":")
  (write-json (Grupo-carrera grupo))
  (display ",\"codigo\":")
  (write-json (Grupo-codigo grupo))
  (display ",\"grupo\":")
  (write-json (Grupo-numero grupo))
  (display "}")
  (void))

(: escribir-grupos (-> (Listof Grupo) Boolean Void))
(define (escribir-grupos grupos primero?)
  (cond
    [(empty? grupos) (void)]
    [else
     (if primero? (void) (display ","))
     (escribir-grupo (first grupos))
     (escribir-grupos (rest grupos) #f)]))

(: escribir-combinacion (-> Combinacion Void))
(define (escribir-combinacion combinacion)
  (display "{\"creditos_totales\":")
  (write-json (Combinacion-creditos-totales combinacion))
  (display ",\"selecciones\":[")
  (escribir-grupos (Combinacion-grupos combinacion) #t)
  (display "]}")
  (void))

;; Escribe cada combinacion cuando llega del stream.
(: escribir-combinaciones (-> (Streamof Combinacion) Boolean Void))
(define (escribir-combinaciones combinaciones primero?)
  (cond
    [(stream-empty? combinaciones) (void)]
    [else
     (if primero? (void) (display ","))
     (escribir-combinacion (stream-first combinaciones))
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
