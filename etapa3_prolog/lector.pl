
:- module(lector_json, [
    leer_combinaciones/1,
    cargar_combinaciones/1,
    cargar_combinaciones/2
]).

:- use_module(library(http/json)).
:- use_module('modelo.pl', []).


% Lee el archivo JSON predeterminado del proyecto
leer_combinaciones(Combinaciones) :-
    source_file(lector_json:leer_combinaciones(_), ArchivoLector),
    file_directory_name(ArchivoLector, CarpetaEtapa3),
    file_directory_name(CarpetaEtapa3, CarpetaProyecto),
    directory_file_path(
        CarpetaProyecto,
        'datos/salida/combinaciones.json',
        Ruta
    ),
    leer_json(Ruta, Combinaciones).


% Lee las combinaciones desde una ruta especifica
leer_json(Ruta, Combinaciones) :-
    setup_call_cleanup(
        open(Ruta, read, Archivo, [encoding(utf8)]),
        json_read_dict(Archivo, Datos),
        close(Archivo)
    ),
    get_dict(combinaciones, Datos, Combinaciones),
    is_list(Combinaciones).


% Carga el archivo predeterminado y convierte los datos
cargar_combinaciones(Combinaciones) :-
    leer_combinaciones(Datos),
    convertir_combinaciones(Datos, 1, Combinaciones).


% Permite cargar un JSON desde una ruta especifica
cargar_combinaciones(Ruta, Combinaciones) :-
    leer_json(Ruta, Datos),
    convertir_combinaciones(Datos, 1, Combinaciones).


% Asigna los ID en el orden del JSON
convertir_combinaciones([], _, []).

convertir_combinaciones(
    [Dato | Resto],
    ID,
    [Combinacion | Otras]
) :-
    convertir_combinacion(Dato, ID, Combinacion),
    SiguienteID is ID + 1,
    convertir_combinaciones(Resto, SiguienteID, Otras).


% Convierte una combinacion individual
convertir_combinacion(Dato, ID, combinacion(ID, Cursos)) :-
    get_dict(selecciones, Dato, Selecciones),
    is_list(Selecciones),
    convertir_cursos(Selecciones, Cursos).


% Convierte la lista de cursos
convertir_cursos([], []).

convertir_cursos([Seleccion | Resto], [Curso | Otros]) :-
    convertir_curso(Seleccion, Curso),
    convertir_cursos(Resto, Otros).


% Convierte una seleccion JSON en un termino curso/5
convertir_curso(
    Seleccion,
    curso(Carrera, Codigo, Grupo, Creditos, Area)
) :-
    get_dict(carrera, Seleccion, CarreraTexto),
    get_dict(codigo, Seleccion, CodigoTexto),
    get_dict(grupo, Seleccion, Grupo),
    get_dict(creditos, Seleccion, Creditos),
    get_dict(area, Seleccion, AreaTexto),

    atom_string(Carrera, CarreraTexto),
    atom_string(Codigo, CodigoTexto),
    atom_string(Area, AreaTexto),

    integer(Grupo),
    Grupo > 0,
    integer(Creditos),
    Creditos >= 0.
