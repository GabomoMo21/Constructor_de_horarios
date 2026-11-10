:- module(lector_json, [leer_combinaciones/1]).
:- module(lector_json, [leer_combinaciones/1, cargar_combinaciones/1]).

:- use_module(library(http/json)).
:- use_module('modelo.pl', []).


leer_combinaciones(Combinaciones) :-
    % ubicar combinaciones desde la carpeta de salidas.
    source_file(leer_combinaciones(_), ArchivoLector),
    file_directory_name(ArchivoLector, CarpetaEtapa3),
    file_directory_name(CarpetaEtapa3, CarpetaProyecto),
    directory_file_path(CarpetaProyecto, 'datos/salida/combinaciones.json', Ruta),

    % lee el json y obtiene combinaciones
    setup_call_cleanup(
        open(Ruta, read, Archivo, [encoding(utf8)]),
        json_read_dict(Archivo, Datos),
        close(Archivo)
    ),
    get_dict(combinaciones, Datos, Combinaciones).


cargar_combinaciones(Combinaciones) :-
    leer_combinaciones(Datos),
    convertir_combinaciones(Datos, 1, Combinaciones).

% Asigna los ID en el orden del JSON.
convertir_combinaciones([], _, []).
convertir_combinaciones([Dato | Resto], ID, [combinacion(ID, Cursos) | Otras]) :-
    get_dict(selecciones, Dato, Selecciones),
    convertir_cursos(Selecciones, Cursos),
    SiguienteID is ID + 1,
    convertir_combinaciones(Resto, SiguienteID, Otras).

convertir_cursos([], []).
convertir_cursos([Seleccion | Resto], [Curso | Otros]) :-
    get_dict(carrera, Seleccion, CarreraTexto),
    get_dict(codigo, Seleccion, CodigoTexto),
    get_dict(grupo, Seleccion, Grupo),
    atom_string(Carrera, CarreraTexto),
    atom_string(Codigo, CodigoTexto),
    Curso = curso(Carrera, Codigo, Grupo, pendiente, pendiente),
    convertir_cursos(Resto, Otros).
