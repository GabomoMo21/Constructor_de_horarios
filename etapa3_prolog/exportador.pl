:- module(exportador, [exportar_resultados/3, resultado_json/5]).

:- encoding(utf8).
:- use_module(library(http/json)).
:- use_module(library(lists), [member/2, memberchk/2]).
:- use_module(library(error), [must_be/2]).
:- use_module('modelo.pl', [total_creditos/2]).

% Permite recibir el predicado del evaluador como argumento
:- meta_predicate exportar_resultados(+, +, 4).

exportar_resultados(Ruta, Combinaciones, Evaluador) :-
    must_be(list, Combinaciones),
    % Recorre las combinaciones y guarda sus resultados
    findall(Resultado,
            (member(Combinacion, Combinaciones),
             evaluar_resultado(Combinacion, Evaluador, Resultado)),
            Resultados),
    setup_call_cleanup(
        open(Ruta, write, Archivo, [encoding(utf8)]),
        json_write_dict(Archivo, _{resultados:Resultados}, [width(0)]),
        close(Archivo)
    ).

% Se toma un solo resultado por combinacion
evaluar_resultado(combinacion(Id, Cursos), Evaluador, Resultado) :-
    !,
    (   once(call(Evaluador, Cursos, Cumple, Razon, CursoAQuitar))
    ->  resultado_json(combinacion(Id, Cursos), Cumple, Razon,
                       CursoAQuitar, Resultado)
    ;   throw(error(evaluacion_fallida(Id), exportar_resultados/3))
    ).
evaluar_resultado(Otro, _, _) :-
    throw(error(combinacion_invalida(Otro), exportar_resultados/3)).

resultado_json(combinacion(Id, Cursos), Cumple, Razon, CursoAQuitar, JSON) :-
    must_be(integer, Id),
    (Id > 0 -> true ; throw(error(id_invalido(Id), resultado_json/5))),
    must_be(list, Cursos),
    validar_resultado(Cumple, Razon, CursoAQuitar, Cursos),
    cursos_json(Cursos, Selecciones),
    total_creditos(Cursos, Total),
    razon_json(Razon, RazonJSON),
    sugerencia_json(CursoAQuitar, SugerenciaJSON),
    JSON = _{id:Id, creditos_totales:Total, selecciones:Selecciones,
             cumple:Cumple, razon:RazonJSON,
             curso_a_quitar:SugerenciaJSON}.

% Si cumple no debe tener razon ni curso para quitar
validar_resultado(true, ninguna, ninguna, _) :- !.
validar_resultado(false, Razon, CursoAQuitar, Cursos) :-
    nonvar(Razon),
    Razon \== ninguna,
    nonvar(CursoAQuitar),
    (CursoAQuitar == ninguna ; memberchk(CursoAQuitar, Cursos)),
    !.
validar_resultado(Cumple, Razon, CursoAQuitar, _) :-
    throw(error(resultado_invalido(Cumple, Razon, CursoAQuitar),
                resultado_json/5)).

% Convierte la lista de cursos al formato JSON
cursos_json([], []).
cursos_json([Curso|Resto], [Dato|Otros]) :-
    curso_json(Curso, Dato),
    cursos_json(Resto, Otros).

curso_json(curso(Carrera, Codigo, Grupo, Creditos, Area), JSON) :-
    !,
    must_be(integer, Grupo),
    must_be(integer, Creditos),
    (Grupo > 0, Creditos >= 0 -> true
    ; throw(error(datos_curso_invalidos(Codigo), curso_json/2))),
    JSON = _{carrera:Carrera, codigo:Codigo, grupo:Grupo,
             creditos:Creditos, area:Area}.
curso_json(Otro, _) :-
    throw(error(curso_invalido(Otro), curso_json/2)).

identificador_json(curso(Carrera, Codigo, _, _, _),
                   _{carrera:Carrera, codigo:Codigo}) :- !.
identificador_json(curso(Carrera, Codigo),
                   _{carrera:Carrera, codigo:Codigo}).

% Cada razon se guarda con su tipo y su detalle
razon_json(ninguna, null) :- !.
razon_json(incompatibilidad(A, B), JSON) :-
    !,
    identificador_json(A, CursoA),
    identificador_json(B, CursoB),
    format(string(Detalle), 'Incompatibilidad entre ~w (~w) y ~w (~w)',
           [CursoA.codigo, CursoA.carrera, CursoB.codigo, CursoB.carrera]),
    JSON = _{regla:"incompatibilidad", detalle:Detalle,
             curso_a:CursoA, curso_b:CursoB}.
razon_json(limite_area(Area, Cantidad), JSON) :-
    !,
    format(string(Detalle), 'El area ~w contiene ~d cursos', [Area, Cantidad]),
    JSON = _{regla:"limite_area", detalle:Detalle,
             area:Area, cantidad:Cantidad}.
razon_json(balance(Carrera, Porcentaje), JSON) :-
    !,
    format(string(Detalle), '~w supera el maximo de ~w%% de creditos',
           [Carrera, Porcentaje]),
    JSON = _{regla:"balance", detalle:Detalle,
             carrera:Carrera, porcentaje:Porcentaje}.
razon_json(Otra, _) :-
    throw(error(razon_invalida(Otra), razon_json/2)).

sugerencia_json(ninguna, null) :- !.
sugerencia_json(curso(Carrera, Codigo, Grupo, _, _),
                _{carrera:Carrera, codigo:Codigo, grupo:Grupo}).
