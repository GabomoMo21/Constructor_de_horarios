
#lang typed/racket

;; ============================================================
;; PRUEBAS DEL MODULO DE COMPATIBILIDAD
;; ============================================================

(require typed/rackunit
         "../tipos.rkt"
         "../compatibilidad.rkt")

;; ============================================================
;; 1. PRUEBAS DE CHOQUES ENTRE HORARIOS
;; ============================================================

(check-true
 (horarios-chocan?
  (Horario "LUN" 480 600)
  (Horario "LUN" 540 660)))

(check-false
 (horarios-chocan?
  (Horario "LUN" 480 600)
  (Horario "LUN" 600 720)))

(check-false
 (horarios-chocan?
  (Horario "LUN" 480 600)
  (Horario "MAR" 480 600)))

;; ============================================================
;; 2. PRUEBAS DE CHOQUES ENTRE GRUPOS
;; ============================================================

(define grupoA
  (Grupo "Computadores" "CE1101" 1 4
         (list (Horario "LUN" 480 600)
               (Horario "MIE" 540 660))))

(define grupoB
  (Grupo "Computadores" "MA1102" 1 4
         (list (Horario "MAR" 480 600)
               (Horario "MIE" 600 720))))

(define grupoC
  (Grupo "Computadores" "FI1101" 1 3
         (list (Horario "JUE" 480 600))))

(check-true
 (grupos-chocan? grupoA grupoB))

(check-false
 (grupos-chocan? grupoA grupoC))

(define grupoVacio
  (Grupo "Computadores" "QU1101" 1 3 '()))

(check-false
 (grupos-chocan? grupoA grupoVacio))


;; ============================================================
;; 3. PRUEBAS DE COMPATIBILIDAD CON GRUPOS SELECCIONADOS
;; ============================================================

(check-true
 (compatible-con-combinacion? grupoC (list grupoA)))

(check-false
 (compatible-con-combinacion? grupoB (list grupoA)))

(define grupoA2
  (Grupo "Computadores" "CE1101" 2 4
         (list (Horario "VIE" 480 600))))

(check-false
 (compatible-con-combinacion? grupoA2 (list grupoA)))

(check-true
 (compatible-con-combinacion? grupoA '()))

(check-true
 (compatible-con-combinacion? grupoC (list grupoA grupoVacio)))

(check-false
 (compatible-con-combinacion? grupoB (list grupoA grupoC)))