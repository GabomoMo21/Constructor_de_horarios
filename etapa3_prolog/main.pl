:- module(main, [ejecutar_etapa3/3, main/0]).

:- encoding(utf8).
:- use_module('cargador.pl', [cargar_combinaciones/2]).
:- use_module('reglas.pl', [cargar_politica/1]).
:- use_module('evaluador.pl', [evaluar_combinacion/4]).
:- use_module('exportador.pl', [exportar_resultados/3]).

% Carga los datos y genera el archivo de resultados
ejecutar_etapa3(RutaEntrada, RutaPolitica, RutaSalida) :-
    cargar_combinaciones(RutaEntrada, Combinaciones),
    cargar_politica(RutaPolitica),
    exportar_resultados(RutaSalida, Combinaciones,
                       evaluador:evaluar_combinacion).

main :-
    current_prolog_flag(argv, Argumentos),
    (   Argumentos = [Entrada, Politica, Salida]
    ->  ejecutar_con_errores(Entrada, Politica, Salida)
    ;   format(user_error,
               'Uso: swipl -q -s etapa3_prolog/main.pl -- <entrada.json> <politica.pl> <salida.json>~n',
               []),
        halt(2)
    ).

% Muestra un error si no se puede generar la salida
ejecutar_con_errores(Entrada, Politica, Salida) :-
    catch(
        (   ejecutar_etapa3(Entrada, Politica, Salida)
        ->  true
        ;   throw(error(etapa3_fallida, main/0))
        ),
        Error,
        (print_message(error, Error), halt(1))
    ).

:- initialization(main, main).
