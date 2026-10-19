#lang typed/racket

;; ============================================================
;; CEmestre - Etapa 2
;; Tipos y estructuras compartidas
;;
;; Este archivo funciona como contrato entre los modulos
;; de la etapa 2.
;;
;; IMPORTANTE:
;; - No se utilizan estructuras mutables.
;; - Si se modifica alguna estructura, debe coordinarse
;;   con el resto del grupo porque puede afectar otros modulos.
;; ============================================================


;; Permite que los demas archivos puedan utilizar
;; estas estructuras.

(provide
 (struct-out Horario)
 (struct-out IdGrupo)
 (struct-out Grupo)
 (struct-out Preferencias)
 (struct-out Combinacion))


;; ============================================================
;; Horario
;; ============================================================
;; Representa un unico bloque horario de un grupo.
;;
;; dia:
;;   Dia en el que se imparte el bloque.
;;
;; inicio:
;;   Hora de inicio convertida a minutos desde las 00:00.
;;
;; fin:
;;   Hora final convertida a minutos desde las 00:00.
;;
;; Ejemplo:
;;
;; MIE 07:30 - 09:20
;;
;; 07:30 -> 450
;; 09:20 -> 560
;;
;; (Horario "MIE" 450 560)
;;
;; Guardar las horas como enteros facilita la comparacion
;; de horarios en compatibilidad.rkt.

(struct Horario
  ([dia : String]
   [inicio : Integer]
   [fin : Integer])
  #:transparent)


;; ============================================================
;; IdGrupo
;; ============================================================
;; Identifica de forma unica un grupo.
;;
;; Un grupo se identifica utilizando:
;;
;; carrera + codigo + periodo + grupo
;;
;; Esto evita confundir:
;; - cursos con el mismo codigo en carreras diferentes
;; - grupos con el mismo numero en periodos diferentes
;;
;; Ejemplo:
;;
;; (IdGrupo
;;   "Ingenieria en Computadores"
;;   "CE1101"
;;   1
;;   3)
;;
;; representa:
;;
;; CE1101 - P1-G3

(struct IdGrupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [grupo : Integer])
  #:transparent)


;; ============================================================
;; Grupo
;; ============================================================
;; Representa una opcion concreta que puede seleccionarse
;; al construir un horario.
;;
;; carrera:
;;   Carrera a la que pertenece el curso.
;;
;; codigo:
;;   Codigo del curso.
;;
;; periodo:
;;   Periodo del grupo (P1, P2, etc.).
;;
;; numero:
;;   Numero del grupo (G1, G2, etc.).
;;
;; creditos:
;;   Creditos correspondientes al curso.
;;
;; horarios:
;;   Lista de todos los bloques horarios del grupo.
;;
;; Ejemplo conceptual:
;;
;; CE1101 - P1-G3 - 4 creditos
;;
;; MIE 07:30-09:20
;; VIE 07:30-09:20
;;
;; se representa como un Grupo que contiene dos Horario.
;;
;; Solo deberian llegar al resto del programa grupos de
;; cursos habilitados para matricular.

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
;; Representa las condiciones indicadas por el estudiante
;; para una ejecucion del programa.
;;
;; carrera:
;;   Carrera sobre la cual se generaran las combinaciones.
;;
;; grupos-interes:
;;   Lista de grupos que el estudiante esta dispuesto
;;   a considerar.
;;
;; Puede haber varios grupos del mismo curso.
;;
;; creditos-min:
;;   Cantidad minima de creditos deseada.
;;
;; creditos-max:
;;   Cantidad maxima de creditos deseada.

(struct Preferencias
  ([carrera : String]
   [grupos-interes : (Listof IdGrupo)]
   [creditos-min : Integer]
   [creditos-max : Integer])
  #:transparent)


;; ============================================================
;; Combinacion
;; ============================================================
;; Representa una combinacion de horario generada.
;;
;; grupos:
;;   Grupos seleccionados para la combinacion.
;;
;; Debe existir como maximo un grupo de cada curso.
;;
;; creditos-totales:
;;   Suma de los creditos de todos los cursos incluidos.
;;
;; Esta estructura sera utilizada principalmente por:
;;
;; generador.rkt
;; filtros.rkt
;; exportador.rkt

(struct Combinacion
  ([grupos : (Listof Grupo)]
   [creditos-totales : Integer])
  #:transparent)
