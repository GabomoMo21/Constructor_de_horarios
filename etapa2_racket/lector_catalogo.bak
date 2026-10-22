#lang racket

(define (hora-a-minutos hora)
  (define partes (string-split hora ":"))
  (define horas (string->number (first partes)))
  (define minutos (string->number (second partes)))
  (+ (* horas 60) minutos))