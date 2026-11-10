
:- module(modelo, [
    carrera_curso/2,
    codigo_curso/2,
    grupo_curso/2,
    creditos_curso/2,
    area_curso/2,
    cursos_combinacion/2,
    curso_de_combinacion/2,
    total_creditos/2
]).

:- use_module(library(lists), [member/2]).


% Obtener informacion de un curso

carrera_curso(curso(Carrera, _, _, _, _), Carrera).

codigo_curso(curso(_, Codigo, _, _, _), Codigo).

grupo_curso(curso(_, _, Grupo, _, _), Grupo).

creditos_curso(curso(_, _, _, Creditos, _), Creditos).

area_curso(curso(_, _, _, _, Area), Area).


% Obtener los cursos de una combinacion

cursos_combinacion(combinacion(_, Cursos), Cursos).


% Buscar un curso dentro de una combinacion

curso_de_combinacion(combinacion(_, Cursos), Curso) :-
    member(Curso, Cursos).


% Calcular los creditos de una lista de cursos

total_creditos([], 0).

total_creditos([Curso | Resto], Total) :-
    creditos_curso(Curso, Creditos),
    total_creditos(Resto, Subtotal),
    Total is Creditos + Subtotal.
