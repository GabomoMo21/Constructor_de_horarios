:- encoding(utf8).
:- begin_tests(exportador).

:- use_module('../exportador.pl').
:- use_module(library(http/json)).

% Cursos de ejemplo para las pruebas
curso1(curso('Ingeniería en Computadores', 'CE1101', 1, 3, computacion)).
curso2(curso('Ingeniería Ambiental', 'MA1102', 2, 4, matematica)).
curso3(curso('Ingeniería en Computadores', 'FH1000', 1, 0, humanidades)).
curso4(curso('Ingeniería en Computadores', 'MA0101', 1, 2, matematica)).
curso5(curso('Ingeniería Ambiental', 'MA0101', 2, 2, matematica)).

test(combinacion_aceptada) :-
    curso1(Curso),
    resultado_json(combinacion(1, [Curso]), true, ninguna, ninguna, JSON),
    assertion(JSON.cumple == true),
    assertion(JSON.creditos_totales =:= 3),
    assertion(JSON.razon == null),
    assertion(JSON.curso_a_quitar == null).

test(incompatibilidad_con_sugerencia) :-
    curso4(A), curso5(B), curso1(C), curso2(D),
    resultado_json(combinacion(2, [A, B, C, D]), false,
                   incompatibilidad(A, B), B, JSON),
    assertion(JSON.cumple == false),
    assertion(JSON.razon.regla == "incompatibilidad"),
    assertion(JSON.curso_a_quitar.codigo == 'MA0101').

test(formato_limite_area) :-
    curso1(Curso),
    resultado_json(combinacion(1, [Curso]), false,
                   limite_area(computacion, 4), ninguna, JSON),
    assertion(JSON.razon.regla == "limite_area"),
    assertion(JSON.razon.cantidad =:= 4).

test(formato_balance_sin_sugerencia) :-
    curso1(Curso),
    resultado_json(combinacion(1, [Curso]), false,
                   balance('Ingeniería en Computadores', 70), ninguna, JSON),
    assertion(JSON.razon.regla == "balance"),
    assertion(JSON.curso_a_quitar == null).

test(curso_sin_creditos) :-
    curso3(Curso),
    resultado_json(combinacion(1, [Curso]), true, ninguna, ninguna, JSON),
    assertion(JSON.creditos_totales =:= 0).

test(sugerencia_que_no_esta_en_la_combinacion,
     [throws(error(resultado_invalido(_, _, _), _))]) :-
    curso1(A), curso2(B),
    resultado_json(combinacion(1, [A]), false,
                   balance('Ingeniería en Computadores', 70), B, _).

% Simula una respuesta sencilla del evaluador para probar el archivo
evaluacion_prueba(_, true, ninguna, ninguna).

leer_json(Ruta, Datos) :-
    setup_call_cleanup(
        open(Ruta, read, Archivo, [encoding(utf8)]),
        json_read_dict(Archivo, Datos),
        close(Archivo)
    ).

test(exportar_combinaciones) :-
    curso1(A), curso2(B),
    tmp_file_stream(text, Ruta, Archivo),
    close(Archivo),
    exportar_resultados(Ruta,
                       [combinacion(1, [A]), combinacion(2, [A, B])],
                       evaluacion_prueba),
    leer_json(Ruta, Datos),
    delete_file(Ruta),
    Datos.resultados = [Primero, Segundo],
    assertion(Primero.id =:= 1),
    assertion(Segundo.id =:= 2),
    assertion(Segundo.creditos_totales =:= 7),
    assertion(Segundo.selecciones = [_, _]).

test(exportar_lista_vacia) :-
    tmp_file_stream(text, Ruta, Archivo),
    close(Archivo),
    exportar_resultados(Ruta, [], evaluacion_prueba),
    leer_json(Ruta, Datos),
    delete_file(Ruta),
    assertion(Datos.resultados == []).

:- end_tests(exportador).
