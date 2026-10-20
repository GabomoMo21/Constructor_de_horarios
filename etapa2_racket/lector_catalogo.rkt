#lang typed/racket
(require "tipos.rkt")
(require racket/file)

(define (hora-a-minutos hora)
  (define partes (string-split hora ":"))
  (define horas (string->number (first partes)))
  (define minutos (string->number (second partes)))
  (+ (* horas 60) minutos))

(define (texto-a-horario texto)
  (define partes (string-split texto "["))
  (define dia (first partes))
  (define horas (string-split (second partes) "]"))
  (define rango (string-split (first horas) "-"))
  (define inicio (hora-a-minutos (first rango)))
  (define fin (hora-a-minutos (second rango)))
  (Horario dia inicio fin))

(define (texto-a-grupo carrera codigo creditos texto)
  (define partes (string-split texto "="))
  (define periodo-grupo (first partes))
  (define horarios (second partes))

  (define pg (string-split periodo-grupo "-"))
  (define periodo (string->number
                   (substring (first pg) 1)))
  (define grupo (string->number
                 (substring (second pg) 1)))

  (define lista-horarios
    (map texto-a-horario
         (string-split horarios ";")))

  (Grupo carrera codigo periodo grupo creditos lista-horarios))

(define (parsear-grupos texto carrera codigo creditos)
  (define grupos (string-split texto "|"))

  (map
   (lambda (x)
     (texto-a-grupo carrera codigo creditos (string-trim x)))
   grupos))

(define (procesar-fila linea)
  (define datos (string-split linea "," #:trim? #f))

  (define carrera (string-trim (list-ref datos 0)))
  (define codigo (string-trim (list-ref datos 1)))
  (define creditos
    (string->number (string-trim (list-ref datos 2))))
  (define puede-matricular
    (string-upcase (string-trim (list-ref datos 3))))
  (define horarios (string-trim (list-ref datos 4)))

  (if (string=? puede-matricular "SI")
      (parsear-grupos horarios carrera codigo creditos)
      empty))