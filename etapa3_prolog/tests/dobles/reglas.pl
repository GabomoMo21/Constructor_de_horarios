:- module(reglas, [cargar_politica/1]).
:- encoding(utf8).
:- use_module(library(readutil), [read_stream_to_codes/2]).

% Doble exclusivo de tests: solo exige que el archivo de politica exista.
cargar_politica(Ruta) :-
    setup_call_cleanup(open(Ruta, read, Flujo, [encoding(utf8)]),
                       read_stream_to_codes(Flujo, _),
                       close(Flujo)).
