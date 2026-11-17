
:- module(evaluador, [primera_violacion/2]).
:- encoding(utf8).

:- use_module('reglas.pl', [
    violacion_incompatibilidad/2,
    violacion_area/2,
    violacion_balance/2
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
