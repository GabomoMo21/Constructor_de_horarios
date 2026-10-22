#lang typed/racket

(require typed/racket/stream
         "tipos.rkt"
         "lector_catalogo.rkt"
         "lector_preferencias.rkt"
         "generador.rkt"
         "filtros.rkt"
         "exportador.rkt")

(provide ejecutar-etapa2)

;; Conecta la lectura, la generacion, el filtro y la salida.
(: ejecutar-etapa2 (-> Path-String Path-String Path-String Void))
(define (ejecutar-etapa2 ruta-catalogo ruta-preferencias ruta-salida)
  (define grupos (leer-catalogo ruta-catalogo))
  (define preferencias (leer-preferencias ruta-preferencias))
  (define combinaciones
    (sequence->stream (generar-combinaciones grupos preferencias)))
  (define validas
    (filtrar-por-creditos
     combinaciones
     (Preferencias-creditos-min preferencias)
     (Preferencias-creditos-max preferencias)))
  (exportar-combinaciones ruta-salida validas))

(module+ main
  (define argumentos (current-command-line-arguments))
  (if (= (vector-length argumentos) 3)
      (ejecutar-etapa2 (vector-ref argumentos 0)
                      (vector-ref argumentos 1)
                      (vector-ref argumentos 2))
      (error 'main
             "Uso: racket etapa2_racket/main.rkt catalogo.csv preferencias.csv salida.json")))
