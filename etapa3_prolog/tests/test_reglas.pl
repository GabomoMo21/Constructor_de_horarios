% Pruebas de reglas.pl (Persona 2).
% Desde la raíz del repositorio:
%   swipl -q -g run_tests -t halt etapa3_prolog/tests/test_reglas.pl
:- encoding(utf8).
:- use_module(library(plunit)).
:- use_module('../reglas.pl').

ruta_prueba(Archivo, Ruta) :-
    source_file(ruta_prueba(_, _), Este),
    file_directory_name(Este, Carpeta),
    directory_file_path(Carpeta, Archivo, Ruta).

cargar_politica_prueba :-
    ruta_prueba('fixtures/politica_reglas.pl', Ruta),
    cargar_politica(Ruta).

% Cursos de ejemplo: curso(Carrera, Codigo, Grupo, Creditos, Area).
ce(Codigo, Creditos, Area, curso('Ingeniería en Computadores', Codigo, 1, Creditos, Area)).
ia(Codigo, Creditos, Area, curso('Ingeniería Ambiental', Codigo, 1, Creditos, Area)).

% Escribe una política temporal y la intenta cargar.
cargar_texto(Texto) :-
    tmp_file_stream(text, Ruta, Flujo),
    set_stream(Flujo, encoding(utf8)),
    write(Flujo, Texto),
    close(Flujo),
    call_cleanup(cargar_politica(Ruta), delete_file(Ruta)).

:- begin_tests(incompatibilidad, [setup(cargar_politica_prueba)]).

test(simetrica_ambos_sentidos, [nondet]) :-
    son_incompatibles(curso('Ingeniería en Computadores', 'PI5516'),
                      curso('Ingeniería Ambiental', 'AE5121')),
    son_incompatibles(curso('Ingeniería Ambiental', 'AE5121'),
                      curso('Ingeniería en Computadores', 'PI5516')).

test(enumera_incompatibles, all(B == [curso('Ingeniería en Computadores', 'PI5516')])) :-
    son_incompatibles(curso('Ingeniería Ambiental', 'AE5121'), B).

test(viola_en_orden_inverso) :-
    ce('PI5516', 4, gestion, A), ia('AE5121', 3, gestion, B),
    violacion_incompatibilidad([B, A], R),
    R == incompatibilidad(curso('Ingeniería Ambiental', 'AE5121'),
                          curso('Ingeniería en Computadores', 'PI5516')).

test(mismo_codigo_otra_carrera_no_basta) :-
    ce('MA0101', 2, matematica, A), ce('PI5516', 4, gestion, B),
    cumple_incompatibilidad([A, B]).

test(reporta_primer_par, [true(R == incompatibilidad(
        curso('Ingeniería en Computadores', 'MA0101'),
        curso('Ingeniería Ambiental', 'MA0101')))]) :-
    ce('MA0101', 2, matematica, A), ia('MA0101', 2, matematica, B),
    ce('PI5516', 4, gestion, C), ia('AE5121', 3, gestion, D),
    violacion_incompatibilidad([A, B, C, D], R).

test(enumera_pares_de_combinacion, all(A-B == ['MA0101'-'MA0101', 'PI5516'-'AE5121'])) :-
    ce('MA0101', 2, matematica, X), ia('MA0101', 2, matematica, Y),
    ce('PI5516', 4, gestion, Z), ia('AE5121', 3, gestion, W),
    par_incompatible([X, Y, Z, W], curso(_, A, _, _, _), curso(_, B, _, _, _)).

:- end_tests(incompatibilidad).

:- begin_tests(area, [setup(cargar_politica_prueba)]).

test(justo_en_el_limite) :-
    ce('CE1101', 3, computacion, A), ce('CE1103', 4, computacion, B),
    cumple_area([A, B]).

test(supera_el_limite) :-
    ce('CE1101', 3, computacion, A), ce('CE1103', 4, computacion, B),
    ce('CE1106', 4, computacion, C),
    violacion_area([A, B, C], R),
    R == limite_area(computacion, 3).

test(cuenta_entre_carreras) :-
    ce('MA1102', 4, matematica, A), ia('MA1102', 4, matematica, B),
    ia('MA2104', 4, matematica, C),
    violacion_area([A, B, C], limite_area(matematica, 3)).

test(enumera_areas, all(Area-N == [computacion-1, matematica-2])) :-
    ce('CE1101', 3, computacion, A), ce('MA1102', 4, matematica, B),
    ce('MA1403', 4, matematica, C),
    cursos_de_area([A, B, C], Area, N).

test(cuenta_un_area) :-
    ce('CE1101', 3, computacion, A), ce('MA1102', 4, matematica, B),
    cursos_de_area([A, B], matematica, N),
    N == 1.

:- end_tests(area).

:- begin_tests(balance, [setup(cargar_politica_prueba)]).

% 7 de 10 créditos con máximo 70 %: no lo supera.
test(porcentaje_exacto_cumple) :-
    ce('CE1103', 7, computacion, A), ia('AI1100', 3, ingenieria, B),
    cumple_balance([A, B]).

test(porcentaje_superado) :-
    ce('CE1103', 8, computacion, A), ia('AI1100', 2, ingenieria, B),
    violacion_balance([A, B], R),
    R == balance('Ingeniería en Computadores', 70).

test(una_sola_carrera_supera_su_maximo) :-
    ce('CE1101', 3, computacion, A),
    violacion_balance([A], balance('Ingeniería en Computadores', 70)).

test(cero_creditos_cumple) :-
    ce('FH1000', 0, humanidades, A), ia('FH1000', 0, humanidades, B),
    cumple_balance([A, B]).

test(carrera_sin_limite) :-
    A = curso('Otra Carrera', 'X1', 1, 5, gestion),
    cumple_balance([A]).

test(creditos_por_carrera, all(C-K == ['Ingeniería en Computadores'-7,
                                      'Ingeniería Ambiental'-3])) :-
    ce('CE1101', 3, computacion, A), ia('AI1100', 3, ingenieria, B),
    ce('MA1102', 4, matematica, D),
    creditos_de_carrera([A, B, D], C, K).

:- end_tests(balance).

:- begin_tests(cumple_todas, [setup(cargar_politica_prueba)]).

test(combinacion_valida) :-
    ce('CE1101', 3, computacion, A), ia('AI1100', 3, ingenieria, B),
    cumple_todas([A, B]).

test(falla_si_una_regla_falla, [fail]) :-
    ce('PI5516', 3, gestion, A), ia('AE5121', 3, gestion, B),
    cumple_todas([A, B]).

test(lista_vacia_cumple) :-
    cumple_todas([]).

:- end_tests(cumple_todas).

:- begin_tests(politica).

test(cambiar_politica_cambia_el_resultado, [cleanup(cargar_politica_prueba)]) :-
    ce('CE1101', 3, computacion, A), ce('CE1103', 4, computacion, B),
    ce('CE1106', 4, computacion, C),
    cargar_politica_prueba,
    \+ cumple_area([A, B, C]),
    cargar_texto("max_cursos_area(3).\n"),
    cumple_area([A, B, C]),
    cumple_balance([A, B, C]).

test(hecho_invalido, [error(politica_invalida(max_porcentaje(x, 150))),
                      cleanup(cargar_politica_prueba)]) :-
    cargar_texto("max_cursos_area(3).\nmax_porcentaje(x, 150).\n").

test(regla_no_permitida, [error(politica_invalida(_)),
                          cleanup(cargar_politica_prueba)]) :-
    cargar_texto("max_cursos_area(3).\nincompatibles(A, B) :- A = B.\n").

test(sin_limite_de_area, [error(politica_invalida(max_cursos_area([]))),
                          cleanup(cargar_politica_prueba)]) :-
    cargar_texto("max_porcentaje(x, 50).\n").

test(error_conserva_politica_anterior, [cleanup(cargar_politica_prueba)]) :-
    cargar_politica_prueba,
    catch(cargar_texto("max_cursos_area(9).\nmax_cursos_area(1).\n"), _, true),
    ce('CE1101', 3, computacion, A), ce('CE1103', 4, computacion, B),
    ce('CE1106', 4, computacion, C),
    violacion_area([A, B, C], limite_area(computacion, 3)).

test(carga_politica_del_proyecto, [cleanup(cargar_politica_prueba)]) :-
    ruta_prueba('../politica.pl', Ruta),
    cargar_politica(Ruta),
    son_incompatibles(curso('Ingeniería Ambiental', 'MA3106'),
                      curso('Ingeniería en Computadores', 'CE1111')).

:- end_tests(politica).
