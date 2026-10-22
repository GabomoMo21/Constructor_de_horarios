#lang typed/racket

(require racket/stream
         "tipos.rkt"
         "filtros.rkt"
         "exportador.rkt")

(provide ejecutar-etapa2)

;; Esta parte recibira las combinaciones que entregue el generador.
(: guardar-resultados
   (-> (Streamof Combinacion) Preferencias Path-String Void))
(define (guardar-resultados combinaciones preferencias ruta-salida)
  (define minimo (Preferencias-creditos-min preferencias))
  (define maximo (Preferencias-creditos-max preferencias))
  (define validas (filtrar-por-creditos combinaciones minimo maximo))
  (exportar-combinaciones ruta-salida validas))

;; Falta conectar los lectores y el generador cuando esten listos.
(: ejecutar-etapa2 (-> Path-String Path-String Path-String Void))
(define (ejecutar-etapa2 ruta-catalogo ruta-preferencias ruta-salida)
  (error 'ejecutar-etapa2 "Pendiente de integrar los modulos"))
