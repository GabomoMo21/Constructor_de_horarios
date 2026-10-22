#lang typed/racket

;; ============================================================
;; CEmestre - Etapa 2
;; Tipos y estructuras compartidas
;;
;; Este archivo funciona como contrato entre los distintos
;; módulos de la etapa en Racket.
;;
;; IMPORTANTE:
;; - No se utilizan estructuras mutables.
;; - Si se cambia una estructura, debe avisarse al grupo porque
;;   puede afectar varios módulos.
;; ============================================================


;; Permite que los demás archivos puedan utilizar las estructuras.

(provide
 (struct-out IdGrupo)
 (struct-out Horario)
 (struct-out Grupo)
 (struct-out Curso)
 (struct-out Preferencias)
 (struct-out Seleccion)
 (struct-out Combinacion))


;; ============================================================
;; IdGrupo
;; ============================================================
;; Identifica un grupo específico.
;;
;; Se utiliza carrera + código + periodo + grupo porque un mismo
;; código puede aparecer en carreras diferentes y un mismo número
;; de grupo puede aparecer en distintos periodos.
;;
;; Ejemplo:
;;
;; (IdGrupo
;;   "Ingenieria en Computadores"
;;   "CE1101"
;;   1
;;   3)
;;
;; Representa:
;; CE1101 - P1-G3

(struct IdGrupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [grupo : Integer])
  #:transparent)


;; ============================================================
;; Horario
;; ============================================================
;; Representa un único bloque horario.
;;
;; Las horas se almacenan como minutos desde las 00:00.
;;
;; Ejemplo:
;;
;; 07:30 -> 450
;; 09:20 -> 560
;;
;; (Horario "MIE" 450 560)

(struct Horario
  ([dia : String]
   [inicio : Integer]
   [fin : Integer])
  #:transparent)


;; ============================================================
;; Grupo
;; ============================================================
;; Representa un grupo específico de un curso.
;;
;; id:
;;   Identificación del grupo.
;;
;; horarios:
;;   Todos los bloques horarios que pertenecen al grupo.
;;
;; choques-con:
;;   Lista de grupos con los que este grupo presenta choque.
;;
;; Ejemplo:
;;
;; CE1101 P1-G1
;;   MIE 07:30-09:20
;;   VIE 07:30-09:20

(struct Grupo
  ([id : IdGrupo]
   [horarios : (Listof Horario)]
   [choques-con : (Listof IdGrupo)])
  #:transparent)


;; ============================================================
;; Curso
;; ============================================================
;; Representa un curso completo.
;;
;; requisitos:
;;   Lista de códigos de requisitos.
;;
;; correquisitos:
;;   Lista de códigos de correquisitos.
;;
;; Si un curso no tiene requisitos o correquisitos se utiliza:
;;
;; '()
;;
;; en vez del texto "No hay".
;;
;; puede-matricular?:
;;   Resultado de la validación realizada previamente en C.
;;
;; grupos:
;;   Todos los grupos disponibles para ese curso.

(struct Curso
  ([carrera : String]
   [codigo : String]
   [nombre : String]
   [creditos : Integer]
   [requisitos : (Listof String)]
   [correquisitos : (Listof String)]
   [puede-matricular? : Boolean]
   [grupos : (Listof Grupo)])
  #:transparent)


;; ============================================================
;; Preferencias
;; ============================================================
;; Representa las preferencias indicadas por el estudiante.
;;
;; grupos-interes:
;;   Grupos que el estudiante está interesado en matricular.
;;
;; creditos-min:
;;   Cantidad mínima de créditos deseada.
;;
;; creditos-max:
;;   Cantidad máxima de créditos deseada.

(struct Preferencias
  ([grupos-interes : (Listof IdGrupo)]
   [creditos-min : Integer]
   [creditos-max : Integer])
  #:transparent)


;; ============================================================
;; Seleccion
;; ============================================================
;; Representa la selección de UN grupo para UN curso.
;;
;; Será utilizada principalmente durante la generación de
;; combinaciones.

(struct Seleccion
  ([curso : Curso]
   [grupo : Grupo])
  #:transparent)


;; ============================================================
;; Combinacion
;; ============================================================
;; Representa una combinación de horario.
;;
;; selecciones:
;;   Lista de los cursos/grupos seleccionados.
;;
;; creditos-totales:
;;   Suma de créditos de todos los cursos incluidos.

(struct Combinacion
  ([selecciones : (Listof Seleccion)]
   [creditos-totales : Integer])
  #:transparent)
