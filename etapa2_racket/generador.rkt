#lang typed/racket

(require typed/racket/stream
         "tipos.rkt"
         "compatibilidad.rkt")

(provide generar-combinaciones)

;; Cada grupo se compara con los ya elegidos antes de descender por su rama,
;; de modo que una combinación con choque nunca llega a construirse.

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

;; Mantener el orden de los cursos y de sus alternativas según el catálogo.
(: agregar-opcion (-> Grupo (Listof (Listof Grupo)) (Listof (Listof Grupo))))
(define (agregar-opcion grupo cursos)
  (cond
    [(empty? cursos) (list (list grupo))]
    [(and (string=? (Grupo-carrera grupo)
                    (Grupo-carrera (first (first cursos))))
          (string=? (Grupo-codigo grupo)
                    (Grupo-codigo (first (first cursos)))))
     (cons (append (first cursos) (list grupo)) (rest cursos))]
    [else (cons (first cursos) (agregar-opcion grupo (rest cursos)))]))

(: agrupar-opciones (-> (Listof Grupo) (Listof (Listof Grupo))))
(define (agrupar-opciones opciones)
  (let: recorrer : (Listof (Listof Grupo))
    ([pendientes : (Listof Grupo) opciones]
     [cursos : (Listof (Listof Grupo)) '()])
    (if (empty? pendientes)
        cursos
        (recorrer (rest pendientes)
                 (agregar-opcion (first pendientes) cursos)))))

;; La función recibida decide si un grupo puede sumarse a lo ya elegido.
;; La búsqueda nunca materializa una lista de combinaciones completas.
(: concatenar
   (-> (Sequenceof Combinacion) (-> (Sequenceof Combinacion))
       (Sequenceof Combinacion)))
(define (concatenar primero siguiente)
  (if (stream-empty? primero)
      (siguiente)
      (stream-cons (stream-first primero)
                   (concatenar (stream-rest primero) siguiente))))

(: explorar-cursos
   (-> (Listof (Listof Grupo)) (Listof Grupo) Integer
       (-> Grupo (Listof Grupo) Boolean) (Sequenceof Combinacion)))
(define (explorar-cursos cursos elegidos creditos compatible?)
  (cond
    [(empty? cursos)
     (if (empty? elegidos)
         empty-stream
         (stream (Combinacion (reverse elegidos) creditos)))]
    [else
     (concatenar
      (explorar-cursos (rest cursos) elegidos creditos compatible?)
      (lambda ()
        (explorar-opciones (first cursos) (rest cursos)
                          elegidos creditos compatible?)))]))

(: explorar-opciones
   (-> (Listof Grupo) (Listof (Listof Grupo)) (Listof Grupo) Integer
       (-> Grupo (Listof Grupo) Boolean) (Sequenceof Combinacion)))
(define (explorar-opciones opciones pendientes elegidos creditos compatible?)
  (cond
    [(empty? opciones) empty-stream]
    [else
     (define grupo (first opciones))
     (concatenar
      (if (compatible? grupo elegidos)
          (explorar-cursos pendientes (cons grupo elegidos)
                          (+ creditos (Grupo-creditos grupo)) compatible?)
          empty-stream)
      (lambda ()
        (explorar-opciones (rest opciones) pendientes
                          elegidos creditos compatible?)))]))

(: generar-combinaciones (-> (Listof Grupo) Preferencias (Sequenceof Combinacion)))
(define (generar-combinaciones grupos preferencias)
  (explorar-cursos (agrupar-opciones (seleccionar-opciones grupos preferencias))
                   '() 0 compatible-con-combinacion?))

;; Pruebas de la búsqueda privada; las simulaciones de compatibilidad permiten
;; observar qué ramas se exploran.
(module+ test
  (require typed/rackunit)

  (define a1 (Grupo "Computadores" "A" 1 1 4 '()))
  (define a2 (Grupo "Computadores" "A" 2 1 0 '()))
  (define b1 (Grupo "Computadores" "B" 1 1 3 '()))
  (define b2 (Grupo "Computadores" "B" 1 2 3 '()))
  (define cursos (agrupar-opciones (list a1 b1 a2 b2)))

  (check-equal? cursos (list (list a1 a2) (list b1 b2)))
  (check-equal?
   (agrupar-opciones (list a1 (Grupo "Ambiental" "A" 1 1 4 '())))
   (list (list a1) (list (Grupo "Ambiental" "A" 1 1 4 '()))))
  ;; Omitir cada curso y elegir una alternativa, sin repetir curso ni vacío.
  (check-equal?
   (stream->list (explorar-cursos cursos '() 0
                                  (lambda ([_grupo : Grupo]
                                           [_elegidos : (Listof Grupo)]) #t)))
   (list (Combinacion (list b1) 3)
         (Combinacion (list b2) 3)
         (Combinacion (list a1) 4)
         (Combinacion (list a1 b1) 7)
         (Combinacion (list a1 b2) 7)
         (Combinacion (list a2) 0)
         (Combinacion (list a2 b1) 3)
         (Combinacion (list a2 b2) 3)))

  ;; Una alternativa incompatible no impide explorar las demás.
  (check-equal?
   (stream->list
    (explorar-cursos cursos '() 0
                    (lambda ([grupo : Grupo] [elegidos : (Listof Grupo)])
                      (not (and (equal? grupo b1) (member a1 elegidos))))))
   (list (Combinacion (list b1) 3)
         (Combinacion (list b2) 3)
         (Combinacion (list a1) 4)
         (Combinacion (list a1 b2) 7)
         (Combinacion (list a2) 0)
         (Combinacion (list a2 b1) 3)
         (Combinacion (list a2 b2) 3)))

  (check-true
   (stream-empty? (explorar-cursos '() '() 0
                                 (lambda ([_grupo : Grupo]
                                          [_elegidos : (Listof Grupo)]) #t))))
  (check-true
   (stream-empty? (explorar-cursos cursos '() 0
                                 (lambda ([_grupo : Grupo]
                                          [_elegidos : (Listof Grupo)]) #f))))

  ;; Pedir el primer resultado no debe comprobar alternativas posteriores.
  (check-equal?
   (stream-first
    (explorar-cursos cursos '() 0
                    (lambda ([grupo : Grupo] [_elegidos : (Listof Grupo)])
                      (if (equal? grupo b2)
                          (error 'prueba "se exploró una alternativa futura")
                          #t))))
   (Combinacion (list b1) 3))

  ;; Poda temprana: tras detectar el choque de x1 con y1 no se consulta el
  ;; curso siguiente con esa pareja ya elegida.
  (define x1 (Grupo "Computadores" "X" 1 1 3 (list (Horario "LUN" 480 600))))
  (define y1 (Grupo "Computadores" "Y" 1 1 3 (list (Horario "LUN" 540 660))))
  (define z1 (Grupo "Computadores" "Z" 1 1 2 (list (Horario "MAR" 480 600))))
  (check-equal?
   (stream->list
    (explorar-cursos (list (list x1) (list y1) (list z1)) '() 0
                    (lambda ([grupo : Grupo] [elegidos : (Listof Grupo)])
                      (if (and (member x1 elegidos) (member y1 elegidos))
                          (error 'prueba "se exploró una rama con choque")
                          (compatible-con-combinacion? grupo elegidos)))))
   (list (Combinacion (list z1) 2)
         (Combinacion (list y1) 3)
         (Combinacion (list y1 z1) 5)
         (Combinacion (list x1) 3)
         (Combinacion (list x1 z1) 5))))
