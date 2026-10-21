#lang typed/racket

(provide
 (struct-out Horario)
 (struct-out IdGrupo)
 (struct-out Grupo)
 (struct-out Preferencias)
 (struct-out Combinacion))


;; ============================================================
;; Horario
;; ============================================================

(struct Horario
  ([dia : String]
   [inicio : Integer]
   [fin : Integer])
  #:transparent)


;; ============================================================
;; IdGrupo
;; ============================================================

(struct IdGrupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [grupo : Integer])
  #:transparent)


;; ============================================================
;; Grupo
;; ============================================================

(struct Grupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [numero : Integer]
   [creditos : Integer]
   [horarios : (Listof Horario)])
  #:transparent)


;; ============================================================
;; Preferencias
;; ============================================================

(struct Preferencias
  ([carrera : String]
   [grupos-interes : (Listof IdGrupo)]
   [creditos-min : Integer]
   [creditos-max : Integer])
  #:transparent)


;; ============================================================
;; Combinacion
;; ============================================================

(struct Combinacion
  ([grupos : (Listof Grupo)]
   [creditos-totales : Integer])
  #:transparent)