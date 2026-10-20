#lang typed/racket

(require racket/file)
(require racket/string)
(require racket/list)
(require racket/match)
(require "tipos.rkt")

(provide leer-catalogo)


(: texto-a-entero (-> String Integer))

(define (texto-a-entero texto)

  (define numero
    (string->number (string-trim texto)))

  (if (exact-integer? numero)
      numero
      (error "Numero invalido:" texto)))

(: hora-a-minutos (-> String Integer))

(define (hora-a-minutos hora)

  (define partes
    (string-split hora ":"))

  (define horas
    (texto-a-entero (first partes)))

  (define minutos
    (texto-a-entero (second partes)))

  (+ (* horas 60) minutos))


(: texto-a-horario (-> String Horario))

(define (texto-a-horario texto)

  (define texto-limpio
    (string-replace
     (string-trim texto)
     "]"
     ""))

  (define partes
    (string-split texto-limpio "["))

  (if (= (length partes) 2)

      (let* ([dia
              (string-trim (first partes))]

             [rango
              (string-split
               (second partes)
               "-")])

        (if (= (length rango) 2)

            (Horario
             dia
             (hora-a-minutos (first rango))
             (hora-a-minutos (second rango)))

            (error "Rango de horario invalido:" texto)))

      (error "Horario invalido:" texto)))

(: texto-a-grupo
   (-> String String Integer String Grupo))

(define (texto-a-grupo carrera codigo creditos texto)

  (define partes
    (string-split texto "="))

  (if (= (length partes) 2)

      (let*

          ([periodo-grupo
            (string-trim (first partes))]

           [texto-horarios
            (string-trim (second partes))]


           [pg
            (string-split periodo-grupo "-")])

        (if (= (length pg) 2)

            (let*


                ([periodo
                  (texto-a-entero
                   (substring
                    (string-trim (first pg))
                    1))]


                 [grupo
                  (texto-a-entero
                   (substring
                    (string-trim (second pg))
                    1))]

                 [lista-horarios
                  (map
                   texto-a-horario
                   (string-split
                    texto-horarios
                    ";"))])

              (Grupo
               carrera
               codigo
               periodo
               grupo
               creditos
               lista-horarios))

            (error "Periodo o grupo invalido:" texto)))

      (error "Formato de grupo invalido:" texto)))


(: parsear-grupos
   (-> String String String Integer (Listof Grupo)))

(define (parsear-grupos texto carrera codigo creditos)

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

       (string-split texto-limpio "|"))))


(: separar-csv (-> String (Listof String)))

(define (separar-csv linea)

  (: recorrer
     (-> (Listof Char)
         (Listof Char)
         (Listof String)
         Boolean
         (Listof String)))

  (define (recorrer caracteres campo campos entre-comillas?)

    (cond

      [(empty? caracteres)

       (reverse
        (cons
         (list->string (reverse campo))
         campos))]


      [else

       (define caracter
         (first caracteres))

       (define resto
         (rest caracteres))

       (cond

         [(char=? caracter #\")

          (recorrer
           resto
           campo
           campos
           (not entre-comillas?))]

         [(and
           (char=? caracter #\,)
           (not entre-comillas?))

          (recorrer
           resto
           '()
           (cons
            (list->string (reverse campo))
            campos)
           entre-comillas?)]

         [else

          (recorrer
           resto
           (cons caracter campo)
           campos
           entre-comillas?)])]))



  (map
   string-trim
   (recorrer
    (string->list linea)
    '()
    '()
    #f)))

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

        (if (string=? puede-matricular "SI")

            (parsear-grupos
             horarios
             carrera
             codigo
             creditos)

            '()))

      (error "Fila del catalogo invalida:" linea)))



(: procesar-filas
   (-> (Listof String) (Listof Grupo)))

(define (procesar-filas lineas)

  (cond

    [(empty? lineas)
     '()]

    [else

     (append
      (procesar-fila (first lineas))
      (procesar-filas (rest lineas)))]))


(: leer-catalogo
   (-> Path-String (Listof Grupo)))

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