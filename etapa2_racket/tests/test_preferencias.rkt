#lang typed/racket

(require typed/rackunit
         "../tipos.rkt"
         "../lector_preferencias.rkt")


(: mismo-id-grupo? (-> IdGrupo IdGrupo Boolean))
(define (mismo-id-grupo? a b)
  (and
   (string=? (IdGrupo-carrera a)
             (IdGrupo-carrera b))

   (string=? (IdGrupo-codigo a)
             (IdGrupo-codigo b))

   (= (IdGrupo-grupo a)
      (IdGrupo-grupo b))))


(: contiene-duplicados? (-> (Listof IdGrupo) Boolean))
(define (contiene-duplicados? grupos)

  (cond

    [(empty? grupos)
     #f]

    [else

     (or

      (ormap
       (lambda ([otro : IdGrupo])
         (mismo-id-grupo?
          (first grupos)
          otro))
       (rest grupos))

      (contiene-duplicados?
       (rest grupos)))]))



(define preferencias
  (leer-preferencias
   "../../datos/entrada/preferencias.csv"))



(displayln "Preferencias leidas:")
(displayln preferencias)

(displayln "")


(displayln "Carrera:")
(displayln
 (Preferencias-carrera preferencias))

(displayln "")

(displayln "Creditos minimos:")
(displayln
 (Preferencias-creditos-min preferencias))

(displayln "")

(displayln "Creditos maximos:")
(displayln
 (Preferencias-creditos-max preferencias))

(displayln "")

(displayln "Grupos de interes:")

(for-each
 displayln
 (Preferencias-grupos-interes preferencias))

(displayln "")

(displayln "Cantidad de grupos de interes:")
(displayln
 (length
  (Preferencias-grupos-interes preferencias)))

(displayln "")

(check-true
 (>
  (length
   (Preferencias-grupos-interes preferencias))
  0))

(check-true
 (<=
  (Preferencias-creditos-min preferencias)
  (Preferencias-creditos-max preferencias)))

(check-true
 (>=
  (Preferencias-creditos-min preferencias)
  0))

(check-true

 (andmap

  (lambda ([id : IdGrupo])

    (string=?
     (IdGrupo-carrera id)
     (Preferencias-carrera preferencias)))

  (Preferencias-grupos-interes preferencias)))


(check-true

 (andmap

  (lambda ([id : IdGrupo])
    (> (IdGrupo-grupo id) 0))

  (Preferencias-grupos-interes preferencias)))

(define hay-duplicados
  (contiene-duplicados?
   (Preferencias-grupos-interes preferencias)))

(check-false hay-duplicados)

(if hay-duplicados

    (displayln
     "ERROR: Existen grupos repetidos en preferencias.")

    (displayln
     "Todas las pruebas de preferencias pasaron correctamente."))