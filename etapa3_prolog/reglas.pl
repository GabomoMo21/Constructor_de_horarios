:- module(reglas, [
    cargar_politica/1,
    son_incompatibles/2,
    par_incompatible/3,
    cursos_de_area/3,
    creditos_de_carrera/3,
    porcentaje_maximo/2,
    violacion_incompatibilidad/2,
    violacion_area/2,
    violacion_balance/2,
    cumple_incompatibilidad/1,
    cumple_area/1,
    cumple_balance/1,
    cumple_todas/1
]).

:- encoding(utf8).
:- use_module(library(lists), [append/3, member/2, list_to_set/2]).
:- use_module(library(apply), [maplist/2, maplist/3]).
:- use_module('modelo.pl', [carrera_curso/2, codigo_curso/2, area_curso/2,
                            total_creditos/2]).

/** <module> Reglas de política académica (Persona 2)

Un curso de una combinación es `curso(Carrera, Codigo, Grupo, Creditos, Area)`.
Las reglas solo consultan los hechos de política; ningún límite está escrito
aquí. Los hechos se cargan desde un archivo con cargar_politica/1:

  * `max_porcentaje(Carrera, Porcentaje)`: máximo de créditos de la carrera
    respecto del total de la combinación.
  * `max_cursos_area(N)`: máximo de cursos de una misma área.
  * `incompatibles(curso(CarreraA, CodigoA), curso(CarreraB, CodigoB))`.

Cada predicado violacion_ devuelve la primera infracción de su regla y falla
si no hay ninguna; cada predicado cumple_ es su negación por falla.
*/

% Los hechos de política viven en este módulo. Se declaran dinámicos solo
% porque se cargan desde un archivo de entrada (lo único permitido).
:- dynamic max_porcentaje/2, max_cursos_area/1, incompatibles/2.


% ---------------------------------------------------------------------------
% Carga de la política
% ---------------------------------------------------------------------------

% cargar_politica(+Ruta)
% Lee los hechos del archivo, los valida y reemplaza la política anterior.
% Se leen como términos (no se consulta el archivo), así el archivo no puede
% ejecutar directivas ni definir otras reglas. Si algo es inválido, lanza un
% error y conserva la política que ya estaba cargada.
cargar_politica(Ruta) :-
    setup_call_cleanup(
        open(Ruta, read, Flujo, [encoding(utf8)]),
        leer_hechos(Flujo, Hechos),
        close(Flujo)
    ),
    maplist(validar_hecho, Hechos),
    validar_max_area(Hechos),
    retractall(max_porcentaje(_, _)),
    retractall(max_cursos_area(_)),
    retractall(incompatibles(_, _)),
    maplist(assertz, Hechos).

% leer_hechos(+Flujo, -Hechos): términos del archivo hasta el final.
% Se ignora la directiva de codificación por si el archivo la incluye.
leer_hechos(Flujo, Hechos) :-
    read_term(Flujo, Termino, []),
    leer_hechos(Termino, Flujo, Hechos).

leer_hechos(end_of_file, _, []) :- !.
leer_hechos((:- encoding(_)), Flujo, Hechos) :- !,
    leer_hechos(Flujo, Hechos).
leer_hechos(Hecho, Flujo, [Hecho | Hechos]) :-
    leer_hechos(Flujo, Hechos).

validar_hecho(max_porcentaje(Carrera, Porcentaje)) :-
    atom(Carrera), number(Porcentaje),
    Porcentaje >= 0, Porcentaje =< 100, !.
validar_hecho(max_cursos_area(N)) :-
    integer(N), N >= 0, !.
validar_hecho(incompatibles(curso(CarreraA, CodigoA), curso(CarreraB, CodigoB))) :-
    atom(CarreraA), atom(CodigoA), atom(CarreraB), atom(CodigoB), !.
validar_hecho(Otro) :-
    throw(error(politica_invalida(Otro), cargar_politica/1)).

% Debe existir exactamente un límite por área.
validar_max_area(Hechos) :-
    findall(N, member(max_cursos_area(N), Hechos), Limites),
    (   Limites = [_]
    ->  true
    ;   throw(error(politica_invalida(max_cursos_area(Limites)),
                    cargar_politica/1))
    ).


% ---------------------------------------------------------------------------
% Consultas sobre la política y las combinaciones
% ---------------------------------------------------------------------------

% son_incompatibles(?CursoA, ?CursoB)
% Relación simétrica sobre identificadores curso(Carrera, Codigo).
% Modos: (+,+) verifica un par; (+,-) enumera los incompatibles de un curso;
% (-,-) enumera todos los pares en ambos sentidos.
son_incompatibles(CursoA, CursoB) :-
    incompatibles(CursoA, CursoB).
son_incompatibles(CursoA, CursoB) :-
    incompatibles(CursoB, CursoA).

% par_incompatible(+Cursos, ?CursoA, ?CursoB)
% Por backtracking da cada par incompatible presente en la combinación,
% con CursoA antes que CursoB en la lista. Los cursos son curso/5.
par_incompatible(Cursos, CursoA, CursoB) :-
    append(_, [CursoA | Siguientes], Cursos),
    member(CursoB, Siguientes),
    identificador(CursoA, IdA),
    identificador(CursoB, IdB),
    son_incompatibles(IdA, IdB).

% identificador(+Curso, -Id): curso/5 → curso(Carrera, Codigo).
identificador(Curso, curso(Carrera, Codigo)) :-
    carrera_curso(Curso, Carrera),
    codigo_curso(Curso, Codigo).

% cursos_de_area(+Cursos, ?Area, -Cantidad)
% Con Area libre enumera cada área presente (en orden de aparición) con su
% cantidad de cursos; con Area dada solo cuenta esa área (falla si no está).
cursos_de_area(Cursos, Area, Cantidad) :-
    valores_distintos(area_curso, Cursos, Areas),
    member(Area, Areas),
    cursos_con(area_curso, Area, Cursos, DelArea),
    length(DelArea, Cantidad).

% creditos_de_carrera(+Cursos, ?Carrera, -Creditos)
% Igual que cursos_de_area/3, pero suma créditos por carrera.
creditos_de_carrera(Cursos, Carrera, Creditos) :-
    valores_distintos(carrera_curso, Cursos, Carreras),
    member(Carrera, Carreras),
    cursos_con(carrera_curso, Carrera, Cursos, DeCarrera),
    total_creditos(DeCarrera, Creditos).

% porcentaje_maximo(+Carrera, -Porcentaje)
% Una carrera sin hecho max_porcentaje/2 no tiene límite (100 %).
porcentaje_maximo(Carrera, Porcentaje) :-
    max_porcentaje(Carrera, Porcentaje), !.
porcentaje_maximo(_, 100).

% valores_distintos(+Selector, +Cursos, -Valores): sin repetir, en orden.
valores_distintos(Selector, Cursos, Valores) :-
    maplist(Selector, Cursos, Todos),
    list_to_set(Todos, Valores).

% cursos_con(+Selector, +Valor, +Cursos, -Filtrados)
cursos_con(_, _, [], []).
cursos_con(Selector, Valor, [Curso | Resto], Filtrados) :-
    (   call(Selector, Curso, Valor)
    ->  Filtrados = [Curso | Otros]
    ;   Filtrados = Otros
    ),
    cursos_con(Selector, Valor, Resto, Otros).


% ---------------------------------------------------------------------------
% Reglas: primera violación de cada una
% ---------------------------------------------------------------------------
% El corte deja solo la primera infracción (en el orden de la combinación):
% la razón es determinista y no se reintentan otras al hacer backtracking.

% violacion_incompatibilidad(+Cursos, -incompatibilidad(IdA, IdB))
violacion_incompatibilidad(Cursos, incompatibilidad(IdA, IdB)) :-
    par_incompatible(Cursos, CursoA, CursoB),
    !,
    identificador(CursoA, IdA),
    identificador(CursoB, IdB).

% violacion_area(+Cursos, -limite_area(Area, Cantidad))
% Se viola si alguna área tiene más de N cursos (N cursos exactos cumple).
violacion_area(Cursos, limite_area(Area, Cantidad)) :-
    max_cursos_area(Maximo),
    cursos_de_area(Cursos, Area, Cantidad),
    Cantidad > Maximo,
    !.

% violacion_balance(+Cursos, -balance(Carrera, PorcentajeMaximo))
% Se compara Creditos*100 > Maximo*Total para no dividir ni redondear.
% Con total 0 nunca se supera el máximo.
violacion_balance(Cursos, balance(Carrera, Maximo)) :-
    total_creditos(Cursos, Total),
    creditos_de_carrera(Cursos, Carrera, Creditos),
    porcentaje_maximo(Carrera, Maximo),
    Creditos * 100 > Maximo * Total,
    !.


% ---------------------------------------------------------------------------
% Cumplimiento (negación por falla)
% ---------------------------------------------------------------------------

cumple_incompatibilidad(Cursos) :- \+ violacion_incompatibilidad(Cursos, _).
cumple_area(Cursos)             :- \+ violacion_area(Cursos, _).
cumple_balance(Cursos)          :- \+ violacion_balance(Cursos, _).

% cumple_todas(+Cursos): la usa el evaluador, también para el extra de
% quitar un curso, así la lógica de las reglas no se duplica.
cumple_todas(Cursos) :-
    cumple_incompatibilidad(Cursos),
    cumple_area(Cursos),
    cumple_balance(Cursos).
