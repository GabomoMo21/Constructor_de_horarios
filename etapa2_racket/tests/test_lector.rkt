#lang typed/racket

(require typed/rackunit
         "../tipos.rkt"
         "../lector_catalogo.rkt")


(define grupos
  (leer-catalogo
   "../../datos/salida/catalogo_procesado.csv"))


(displayln "Cantidad de grupos encontrados:")
(displayln (length grupos))

(displayln "")


(check-true
 (> (length grupos) 0))

(define primer-grupo
  (first grupos))

(displayln "Primer grupo:")
(displayln primer-grupo)

(displayln "")


(displayln "Carrera:")
(displayln
 (Grupo-carrera primer-grupo))

(displayln "")

(displayln "Codigo:")
(displayln
 (Grupo-codigo primer-grupo))

(displayln "")

(displayln "Numero de grupo:")
(displayln
 (Grupo-numero primer-grupo))

(displayln "")

(displayln "Creditos:")
(displayln
 (Grupo-creditos primer-grupo))

(displayln "")

(displayln "Horarios:")
(displayln
 (Grupo-horarios primer-grupo))

(displayln "")

(displayln "Primeros grupos:")

(for-each
 displayln
 (take grupos
       (min 10 (length grupos))))

(displayln "")

(check-true
 (> (length grupos) 0))


(check-true

 (andmap

  (lambda ([grupo : Grupo])
    (> (Grupo-numero grupo) 0))

  grupos))


(check-true

 (andmap

  (lambda ([grupo : Grupo])
    (>= (Grupo-creditos grupo) 0))

  grupos))


(check-true

 (andmap

  (lambda ([grupo : Grupo])
    (not
     (string=?
      (Grupo-codigo grupo)
      "")))

  grupos))


(displayln "Todas las pruebas del catalogo pasaron correctamente.")