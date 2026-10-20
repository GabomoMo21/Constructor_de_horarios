#lang typed/racket

(require "tipos.rkt")
(require "lector_catalogo.rkt")

(define grupos
  (leer-catalogo
   "../datos/salida/catalogo_procesado.csv"))

(displayln "Cantidad de grupos encontrados:")
(displayln (length grupos))

(displayln "")
(displayln "Primer grupo:")
(displayln (first grupos))

(displayln "Primeros 10 grupos:")

(for-each
 displayln
 (take grupos 10))

(define primer-grupo
  (first grupos))

(displayln "Codigo:")
(displayln (Grupo-codigo primer-grupo))

(displayln "Periodo:")
(displayln (Grupo-periodo primer-grupo))

(displayln "Numero de grupo:")
(displayln (Grupo-numero primer-grupo))

(displayln "Creditos:")
(displayln (Grupo-creditos primer-grupo))

(displayln "Horarios:")
(displayln (Grupo-horarios primer-grupo))

(define grupos-ce1101
  (filter
   (lambda ([g : Grupo])
     (string=? (Grupo-codigo g) "CE1101"))
   grupos))

(for-each displayln grupos-ce1101)