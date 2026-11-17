#lang typed/racket

(require typed/rackunit
         "../tipos.rkt"
         "../lector_preferencias.rkt")


(define preferencias
  (leer-preferencias
   "../../datos/entrada/preferencias.csv"))



(displayln "Preferencias leidas:")
(displayln preferencias)

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

    (not (string=? (IdGrupo-carrera id) "")))

  (Preferencias-grupos-interes preferencias)))


(check-true

 (andmap

  (lambda ([id : IdGrupo])
    (> (IdGrupo-grupo id) 0))

  (Preferencias-grupos-interes preferencias)))

;; Las preferencias pueden incluir las dos carreras
(define preferencias-mixtas
  (leer-preferencias "../../datos/entrada/preferencias_mixtas_ejemplo.csv"))

(check-true
 (ormap (lambda ([id : IdGrupo])
          (string=? (IdGrupo-carrera id) "Ingeniería en Computadores"))
        (Preferencias-grupos-interes preferencias-mixtas)))

(check-true
 (ormap (lambda ([id : IdGrupo])
          (string=? (IdGrupo-carrera id) "Ingeniería Ambiental"))
        (Preferencias-grupos-interes preferencias-mixtas)))
