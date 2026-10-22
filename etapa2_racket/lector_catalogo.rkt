#lang typed/racket

(require racket/file
         racket/string
         racket/list
         "tipos.rkt"
         "utilidades_csv.rkt")

(provide leer-catalogo)


(: hora-a-minutos (-> String Integer))

(define (hora-a-minutos hora)

  (define partes
    (string-split hora ":"))

  (define horas
    (texto-a-entero
     (first partes)))

  (define minutos
    (texto-a-entero
     (second partes)))

  (+ (* horas 60)
     minutos))

(: texto-a-horario (-> String Horario))

(define (texto-a-horario texto)

  (define texto-limpio
    (string-replace
     (string-trim texto)
     "]"
     ""))

  (define partes
    (string-split
     texto-limpio
     "["))

  (if (= (length partes) 2)

      (let*
          ([dia
            (string-trim
             (first partes))]

           [rango
            (string-split
             (second partes)
             "-")])

        (if (= (length rango) 2)

            (Horario
             dia
             (hora-a-minutos
              (first rango))
             (hora-a-minutos
              (second rango)))

            (error
             'texto-a-horario
             "Rango de horario invalido: ~a"
             texto)))

      (error
       'texto-a-horario
       "Horario invalido: ~a"
       texto)))


(: texto-a-numero-grupo
   (-> String Integer))

(define (texto-a-numero-grupo texto)

  (define limpio
    (string-trim texto))

  (if (and
       (> (string-length limpio) 1)
       (char=?
        (string-ref limpio 0)
        #\G))

      (texto-a-entero
       (substring limpio 1))

      (error
       'texto-a-numero-grupo
       "Grupo invalido: ~a"
       texto)))

(: texto-a-grupo
   (-> String String Integer String Grupo))

(define (texto-a-grupo
         carrera
         codigo
         creditos
         texto)

  (define partes
    (string-split texto "="))

  (if (= (length partes) 2)

      (let*
          ([texto-grupo
            (string-trim
             (first partes))]

           [texto-horarios
            (string-trim
             (second partes))]

           [grupo
            (texto-a-numero-grupo
             texto-grupo)]

           [lista-horarios
            (map
             texto-a-horario
             (string-split
              texto-horarios
              ";"))])

        (Grupo
         carrera
         codigo
         grupo
         creditos
         lista-horarios))

      (error
       'texto-a-grupo
       "Formato de grupo invalido: ~a"
       texto)))

(: parsear-grupos
   (-> String String String Integer (Listof Grupo)))

(define (parsear-grupos
         texto
         carrera
         codigo
         creditos)

  (define texto-limpio
    (string-trim texto))

  (if (or
       (string=? texto-limpio "")
       (string-ci=? texto-limpio "No hay"))

      '()

      (map

       (lambda ([grupo-texto : String])

         (texto-a-grupo
          carrera
          codigo
          creditos
          (string-trim grupo-texto)))

       (string-split
        texto-limpio
        "|"))))

(: procesar-fila
   (-> String (Listof Grupo)))

(define (procesar-fila linea)

  (define datos
    (separar-csv linea))

  (if (= (length datos) 9)

      (let*
          ([carrera
            (list-ref datos 0)]

           [codigo
            (list-ref datos 1)]

           [creditos
            (texto-a-entero
             (list-ref datos 3))]

           [horarios
            (list-ref datos 4)]

           [puede-matricular
            (string-upcase
             (list-ref datos 8))])

        (if (string=?
             puede-matricular
             "SI")

            (parsear-grupos
             horarios
             carrera
             codigo
             creditos)

            '()))

      (error
       'procesar-fila
       "Fila del catalogo invalida: ~a"
       linea)))

(: procesar-filas
   (-> (Listof String)
       (Listof Grupo)))

(define (procesar-filas lineas)

  (cond

    [(empty? lineas)
     '()]

    [else

     (append
      (procesar-fila
       (first lineas))

      (procesar-filas
       (rest lineas)))]))

(: leer-catalogo
   (-> Path-String
       (Listof Grupo)))

(define (leer-catalogo nombre-archivo)

  (define lineas
    (file->lines nombre-archivo))

  (cond

    [(empty? lineas)
     '()]

    [else

     (define filas
       (filter

        (lambda ([linea : String])
          (not
           (string=?
            (string-trim linea)
            "")))

        (rest lineas)))

     (procesar-filas filas)]))