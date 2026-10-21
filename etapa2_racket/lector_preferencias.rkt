#lang typed/racket

(require racket/file
         racket/string
         "tipos.rkt"
         "utilidades_csv.rkt")

(provide leer-preferencias)

(: texto-a-periodo (-> String Integer))

(define (texto-a-periodo texto)

  (define limpio
    (string-trim texto))

  (if (and
       (> (string-length limpio) 1)
       (char=?
        (string-ref limpio 0)
        #\P))

      (texto-a-entero
       (substring limpio 1))

      (error
       'texto-a-periodo
       "Periodo invalido: ~a"
       texto)))

(: texto-a-grupo (-> String Integer))

(define (texto-a-grupo texto)

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
       'texto-a-grupo
       "Grupo invalido: ~a"
       texto)))



(: fila-a-id-grupo
   (-> (Listof String) IdGrupo))

(define (fila-a-id-grupo campos)

  (if (< (length campos) 6)

      (error
       'fila-a-id-grupo
       "Fila incompleta")

      (IdGrupo
       (string-trim
        (list-ref campos 0))

       (string-trim
        (list-ref campos 1))

       (texto-a-periodo
        (list-ref campos 2))

       (texto-a-grupo
        (list-ref campos 3)))))


(: validar-rango-creditos
   (-> Integer Integer Boolean))

(define (validar-rango-creditos minimo maximo)

  (if (and
       (>= minimo 0)
       (<= minimo maximo))

      #t

      (error
       'validar-rango-creditos
       "Rango de creditos invalido: ~a - ~a"
       minimo
       maximo)))


(: procesar-filas-preferencias
   (-> (Listof String) Preferencias))

(define (procesar-filas-preferencias filas)

  (if (empty? filas)

      (error
       'procesar-filas-preferencias
       "No hay preferencias en el archivo")

      (let ([primera
             (separar-csv
              (first filas))])

        (if (< (length primera) 6)

            (error
             'procesar-filas-preferencias
             "Primera fila incompleta")

            (let*

                ([carrera
                  (string-trim
                   (list-ref primera 0))]

                 [minimo
                  (texto-a-entero
                   (list-ref primera 4))]

                 [maximo
                  (texto-a-entero
                   (list-ref primera 5))]

                 [rango-valido
                  (validar-rango-creditos
                   minimo
                   maximo)]

                 [grupos

                  (map

                   (lambda ([linea : String])

                     (define campos
                       (separar-csv linea))

                     (if (< (length campos) 6)

                         (error
                          'procesar-filas-preferencias
                          "Fila incompleta: ~a"
                          linea)

                         (let*

                             ([carrera-actual
                               (string-trim
                                (list-ref campos 0))]

                              [min-actual
                               (texto-a-entero
                                (list-ref campos 4))]

                              [max-actual
                               (texto-a-entero
                                (list-ref campos 5))]

                              [rango-actual-valido
                               (validar-rango-creditos
                                min-actual
                                max-actual)])


                           (if (and
                                (string=?
                                 carrera
                                 carrera-actual)

                                (=
                                 minimo
                                 min-actual)

                                (=
                                 maximo
                                 max-actual))

                               (fila-a-id-grupo campos)

                               (error
                                'procesar-filas-preferencias
                                "Carrera o rango inconsistente")))))

                   filas)])

              (Preferencias
               carrera
               grupos
               minimo
               maximo))))))


(: leer-preferencias
   (-> Path-String Preferencias))

(define (leer-preferencias ruta)

  (define lineas
    (file->lines ruta))

  (if (empty? lineas)

      (error
       'leer-preferencias
       "Archivo CSV vacio")

      (let

          ([filas
            (filter

             (lambda ([linea : String])

               (not
                (string=?
                 (string-trim linea)
                 "")))

             (rest lineas))])

        (procesar-filas-preferencias
         filas))))