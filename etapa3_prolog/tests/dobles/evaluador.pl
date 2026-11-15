:- module(evaluador, [evaluar_combinacion/4]).
:- encoding(utf8).

% Doble exclusivo de tests. Los casos no implican la politica definitiva.
evaluar_combinacion(Cursos, false, incompatibilidad(A, B), Sugerencia) :-
    member(A, Cursos), A = curso(CarreraA, 'MA0101', _, _, _),
    member(B, Cursos), B = curso(CarreraB, 'MA0101', _, _, _),
    CarreraA \== CarreraB,
    (length(Cursos, 2) -> Sugerencia = ninguna ; Sugerencia = B), !.

evaluar_combinacion(_, true, ninguna, ninguna).
