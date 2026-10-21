#lang typed/racket

(require racket/string)

(provide separar-csv
         texto-a-entero)

(: separar-csv (-> String (Listof String)))

(define (separar-csv linea)

  (define largo
    (string-length linea))

  (let recorrer
    ([i : Integer 0]
     [campo : String ""]
     [campos : (Listof String) empty]
     [comillas : Boolean #f])

    (cond

      [(>= i largo)

       (map
        string-trim
        (reverse
         (cons campo campos)))]


      [else

       (define caracter
         (string-ref linea i))

       (cond

         [(char=? caracter #\")

          (if comillas

              (if (and
                   (< (+ i 1) largo)
                   (char=?
                    (string-ref linea (+ i 1))
                    #\"))

                  (recorrer
                   (+ i 2)
                   (string-append campo "\"")
                   campos
                   #t)

                  (recorrer
                   (+ i 1)
                   campo
                   campos
                   #f))

              (recorrer
               (+ i 1)
               campo
               campos
               #t))]


         [(and
           (char=? caracter #\,)
           (not comillas))

          (recorrer
           (+ i 1)
           ""
           (cons campo campos)
           #f)]

         [else

          (recorrer
           (+ i 1)
           (string-append
            campo
            (string caracter))
           campos
           comillas)])])))



(: texto-a-entero (-> String Integer))

(define (texto-a-entero texto)

  (define numero
    (string->number
     (string-trim texto)))

  (if (exact-integer? numero)

      numero

      (error
       'texto-a-entero
       "Numero entero invalido: ~a"
       texto)))