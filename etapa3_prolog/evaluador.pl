
:- module(evaluador, [
    primera_violacion/2,
    evaluar_combinacion/4
]).

:- encoding(utf8).

:- use_module('reglas.pl', [
    violacion_incompatibilidad/2,
    violacion_area/2,
    violacion_balance/2,
    cumple_todas/1
]).

primera_violacion(Cursos, Razon) :-
    violacion_incompatibilidad(Cursos, Razon),
    !.

primera_violacion(Cursos, Razon) :-
    violacion_area(Cursos, Razon),
    !.

primera_violacion(Cursos, Razon) :-
    violacion_balance(Cursos, Razon),
    !.

evaluar_combinacion(Cursos, true, ninguna, ninguna) :-
    cumple_todas(Cursos),
    !.

evaluar_combinacion(Cursos, false, Razon, ninguna) :-
    primera_violacion(Cursos, Razon).
