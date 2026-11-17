
:- encoding(utf8).
:- use_module(library(plunit)).
:- use_module('../evaluador.pl').
:- use_module('../reglas.pl', [
    cargar_politica/1,
    cumple_todas/1
]).

:- begin_tests(primera_violacion, [
    setup(cargar_politica('etapa3_prolog/tests/fixtures/politica_reglas.pl'))
]).

test(incompatibilidad_prioritaria) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'PI5516', 1, 4, gestion),
        curso('Ingeniería Ambiental', 'AE5121', 1, 3, gestion),
        curso('Ingeniería Ambiental', 'AE4208', 1, 2, gestion)
    ],
    primera_violacion(Cursos,
        incompatibilidad(
            curso('Ingeniería en Computadores', 'PI5516'),
            curso('Ingeniería Ambiental', 'AE5121'))).

test(area_prioritaria_sobre_balance) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'CE1101', 1, 3, computacion),
        curso('Ingeniería en Computadores', 'CE1103', 1, 4, computacion),
        curso('Ingeniería en Computadores', 'CE1106', 1, 4, computacion)
    ],
    primera_violacion(Cursos, limite_area(computacion, 3)).

test(balance) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'CE1101', 1, 3, computacion)
    ],
    primera_violacion(Cursos, balance('Ingeniería en Computadores', 70)).

test(combinacion_valida, [fail]) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'CE1101', 1, 3, computacion),
        curso('Ingeniería Ambiental', 'AI1100', 1, 3, ingenieria)
    ],
    primera_violacion(Cursos, _).

:- end_tests(primera_violacion).

:- begin_tests(evaluar_combinacion, [
    setup(cargar_politica('etapa3_prolog/tests/fixtures/politica_reglas.pl'))
]).

test(combinacion_aceptada) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'CE1101', 1, 3, computacion),
        curso('Ingeniería Ambiental', 'AI1100', 1, 3, ingenieria)
    ],
    evaluar_combinacion(Cursos, true, ninguna, ninguna).

test(combinacion_rechazada_sin_reparacion) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'PI5516', 1, 4, gestion),
        curso('Ingeniería Ambiental', 'AE5121', 1, 3, gestion)
    ],
    evaluar_combinacion(
        Cursos,
        false,
        incompatibilidad(
            curso('Ingeniería en Computadores', 'PI5516'),
            curso('Ingeniería Ambiental', 'AE5121')
        ),
        ninguna
    ).

test(combinacion_rechazada_con_reparacion) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'PRUEBA01', 1, 3, computacion),
        curso('Ingeniería en Computadores', 'PRUEBA02', 1, 3, computacion),
        curso('Ingeniería en Computadores', 'PRUEBA03', 1, 3, computacion),
        curso('Ingeniería Ambiental', 'PRUEBA04', 1, 3, ciencias),
        curso('Ingeniería Ambiental', 'PRUEBA05', 1, 3, ingenieria)
    ],
    evaluar_combinacion(
        Cursos,
        false,
        limite_area(computacion, 3),
        CursoAQuitar
    ),
    assertion(CursoAQuitar ==
        curso('Ingeniería en Computadores', 'PRUEBA01', 1, 3, computacion)),
    once((
        select(CursoAQuitar, Cursos, Restantes),
        cumple_todas(Restantes)
    )).

:- end_tests(evaluar_combinacion).

:- begin_tests(buscar_curso_a_quitar, [
    setup(cargar_politica('etapa3_prolog/tests/fixtures/politica_reglas.pl'))
]).

test(reparacion_posible) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'PRUEBA01', 1, 3, computacion),
        curso('Ingeniería en Computadores', 'PRUEBA02', 1, 3, computacion),
        curso('Ingeniería en Computadores', 'PRUEBA03', 1, 3, computacion),
        curso('Ingeniería Ambiental', 'PRUEBA04', 1, 3, ciencias),
        curso('Ingeniería Ambiental', 'PRUEBA05', 1, 3, ingenieria)
    ],
    once((
        buscar_curso_a_quitar(Cursos, CursoAQuitar),
        assertion(CursoAQuitar ==
            curso('Ingeniería en Computadores', 'PRUEBA01', 1, 3, computacion)),
        select(CursoAQuitar, Cursos, Restantes),
        cumple_todas(Restantes)
    )).

test(reparacion_imposible) :-
    Cursos = [
        curso('Ingeniería en Computadores', 'PI5516', 1, 4, gestion),
        curso('Ingeniería Ambiental', 'AE5121', 1, 3, gestion)
    ],
    buscar_curso_a_quitar(Cursos, ninguna).

test(lista_vacia) :-
    buscar_curso_a_quitar([], ninguna).

:- end_tests(buscar_curso_a_quitar).
