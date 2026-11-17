% Prueba que los modulos funcionen juntos con los datos de ejemplo
:- encoding(utf8).
:- use_module(library(plunit)).
:- use_module(library(http/json)).
:- use_module(library(lists), [select/3]).
:- use_module('../lector.pl', [cargar_combinaciones/2]).
:- use_module('../reglas.pl', [cargar_politica/1, cumple_todas/1]).
:- use_module('../exportador.pl', [exportar_resultados/3]).
:- use_module('../evaluador.pl', [evaluar_combinacion/4]).

leer_resultados(Ruta, Datos) :-
    setup_call_cleanup(
        open(Ruta, read, Archivo, [encoding(utf8)]),
        json_read_dict(Archivo, Datos),
        close(Archivo)
    ).

:- begin_tests(integracion).

test(combinaciones_de_ejemplo) :-
    cargar_combinaciones('etapa3_prolog/tests/fixtures/combinaciones_ejemplo.json', Combinaciones),
    cargar_politica('etapa3_prolog/tests/fixtures/politica_ejemplo.pl'),
    tmp_file_stream(text, Ruta, Archivo),
    close(Archivo),
    call_cleanup(
        (   exportar_resultados(Ruta, Combinaciones, evaluador:evaluar_combinacion),
            leer_resultados(Ruta, Datos),
            Datos.resultados = [Primera, Segunda, Tercera, Cuarta],
            assertion(Primera.cumple == true),
            assertion(Primera.creditos_totales =:= 7),
            assertion(Segunda.cumple == false),
            assertion(Segunda.razon.regla == "incompatibilidad"),
            assertion(Segunda.curso_a_quitar.codigo == "MA0101"),
            assertion(Tercera.cumple == true),
            assertion(Tercera.creditos_totales =:= 0),
            assertion(Cuarta.cumple == false),
            assertion(Cuarta.curso_a_quitar == null)
        ),
        delete_file(Ruta)
    ).

test(lista_vacia) :-
    cargar_combinaciones('etapa3_prolog/tests/fixtures/combinaciones_vacias.json', Combinaciones),
    cargar_politica('etapa3_prolog/tests/fixtures/politica_ejemplo.pl'),
    tmp_file_stream(text, Ruta, Archivo),
    close(Archivo),
    call_cleanup(
        (   exportar_resultados(Ruta, Combinaciones, evaluador:evaluar_combinacion),
            leer_resultados(Ruta, Datos),
            assertion(Datos.resultados == [])
        ),
        delete_file(Ruta)
    ).

% Comprueba los tres rechazos y si una baja realmente los corrige
verificar_baja(combinacion(_, Cursos), Sugerencia) :-
    get_dict(carrera, Sugerencia, CarreraTexto),
    get_dict(codigo, Sugerencia, CodigoTexto),
    get_dict(grupo, Sugerencia, Grupo),
    atom_string(Carrera, CarreraTexto),
    atom_string(Codigo, CodigoTexto),
    select(curso(Carrera, Codigo, Grupo, _, _), Cursos, Restantes),
    cumple_todas(Restantes),
    !.

test(tres_reglas_y_curso_a_quitar) :-
    cargar_combinaciones('etapa3_prolog/tests/fixtures/combinaciones_politicas.json', Combinaciones),
    cargar_politica('etapa3_prolog/tests/fixtures/politica_ejemplo.pl'),
    tmp_file_stream(text, Ruta, Archivo),
    close(Archivo),
    call_cleanup(
        (   exportar_resultados(Ruta, Combinaciones, evaluador:evaluar_combinacion),
            leer_resultados(Ruta, Datos),
            Datos.resultados = [Valida, Incompatible, Area, Balance, SinBaja, Unico],
            assertion(Valida.cumple == true),
            assertion(Valida.razon == null),
            assertion(Incompatible.razon.regla == "incompatibilidad"),
            assertion(Area.razon.regla == "limite_area"),
            assertion(Area.razon.area == "matematica"),
            assertion(Area.razon.cantidad =:= 4),
            assertion(Balance.razon.regla == "balance"),
            assertion(Balance.razon.carrera == "Ingeniería en Computadores"),
            assertion(SinBaja.razon.regla == "incompatibilidad"),
            assertion(SinBaja.curso_a_quitar == null),
            assertion(Unico.razon.regla == "balance"),
            nth1(2, Combinaciones, Combinacion2),
            nth1(3, Combinaciones, Combinacion3),
            nth1(4, Combinaciones, Combinacion4),
            nth1(6, Combinaciones, Combinacion6),
            assertion(verificar_baja(Combinacion2, Incompatible.curso_a_quitar)),
            assertion(verificar_baja(Combinacion3, Area.curso_a_quitar)),
            assertion(verificar_baja(Combinacion4, Balance.curso_a_quitar)),
            assertion(verificar_baja(Combinacion6, Unico.curso_a_quitar)),
            assertion(Incompatible.curso_a_quitar.codigo == "MA0101"),
            assertion(Incompatible.curso_a_quitar.carrera == "Ingeniería en Computadores"),
            assertion(Area.curso_a_quitar.codigo == "MA1102"),
            assertion(Area.curso_a_quitar.carrera == "Ingeniería Ambiental"),
            assertion(Balance.curso_a_quitar.codigo == "CE1101"),
            assertion(Unico.curso_a_quitar.codigo == "CE1101")
        ),
        delete_file(Ruta)
    ).

:- end_tests(integracion).
