:- module(lector_json, [leer_combinaciones/1]).

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
