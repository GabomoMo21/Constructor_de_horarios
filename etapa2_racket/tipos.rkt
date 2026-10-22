#lang typed/racket

(provide
 (struct-out Horario)
 (struct-out IdGrupo)
 (struct-out Grupo)
 (struct-out Preferencias)
 (struct-out Combinacion))


(struct Horario
  ([dia : String]
   [inicio : Integer]
   [fin : Integer])
  #:transparent)


(struct IdGrupo
  ([carrera : String]
   [codigo : String]
   [grupo : Integer])
  #:transparent)


(struct Grupo
  ([carrera : String]
   [codigo : String]
   [numero : Integer]
   [creditos : Integer]
   [horarios : (Listof Horario)])
  #:transparent)

(struct Preferencias
  ([carrera : String]
   [grupos-interes : (Listof IdGrupo)]
   [creditos-min : Integer]
   [creditos-max : Integer])
  #:transparent)


(struct Combinacion
  ([grupos : (Listof Grupo)]
   [creditos-totales : Integer])
  #:transparent)