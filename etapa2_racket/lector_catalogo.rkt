#lang racket

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