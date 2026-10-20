#lang typed/racket

(require typed/racket/stream
         "tipos.rkt")

(provide generar-combinaciones)

;; Iteración 1: solo se generan alternativas para un curso.
;; La búsqueda entre varios cursos y la poda de choques quedan pendientes.

(: id-de-grupo (-> Grupo IdGrupo))
(define (id-de-grupo grupo)
  (IdGrupo (Grupo-carrera grupo)
           (Grupo-codigo grupo)
           (Grupo-periodo grupo)
           (Grupo-numero grupo)))

(: grupo-de-interes? (-> Grupo Preferencias Boolean))
(define (grupo-de-interes? grupo preferencias)
  (and (string=? (Grupo-carrera grupo) (Preferencias-carrera preferencias))
       (ormap (lambda ([id : IdGrupo])
                (equal? id (id-de-grupo grupo)))
              (Preferencias-grupos-interes preferencias))))

(: seleccionar-opciones (-> (Listof Grupo) Preferencias (Listof Grupo)))
(define (seleccionar-opciones grupos preferencias)
  (let: recorrer : (Listof Grupo)
    ([pendientes : (Listof Grupo) grupos]
     [vistos : (Listof IdGrupo) '()])
    (cond
      [(empty? pendientes) '()]
      [else
       (define grupo (first pendientes))
       (define id (id-de-grupo grupo))
       (if (and (grupo-de-interes? grupo preferencias)
                (not (member id vistos)))
           (cons grupo (recorrer (rest pendientes) (cons id vistos)))
           (recorrer (rest pendientes) vistos))])))

(: combinaciones-un-curso (-> (Listof Grupo) (Sequenceof Combinacion)))
(define (combinaciones-un-curso opciones)
  (if (empty? opciones)
      empty-stream
      (stream-cons (Combinacion (list (first opciones))
                                (Grupo-creditos (first opciones)))
                   (combinaciones-un-curso (rest opciones)))))

(: generar-combinaciones (-> (Listof Grupo) Preferencias (Sequenceof Combinacion)))
(define (generar-combinaciones grupos preferencias)
  (define opciones (seleccionar-opciones grupos preferencias))
  (cond
    [(empty? opciones) empty-stream]
    [(ormap (lambda ([grupo : Grupo])
              (not (string=? (Grupo-codigo grupo)
                             (Grupo-codigo (first opciones)))))
            (rest opciones))
     (error 'generar-combinaciones
            "la generación de varios cursos queda pendiente para la iteración 2")]
    [else (combinaciones-un-curso opciones)]))
