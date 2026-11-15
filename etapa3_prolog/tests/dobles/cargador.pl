:- module(cargador, [cargar_combinaciones/2]).
:- encoding(utf8).
:- use_module(library(http/json)).

% Doble exclusivo de tests: NO sustituye al modulo que implementara Persona 1.
cargar_combinaciones(Ruta, Combinaciones) :-
    setup_call_cleanup(open(Ruta, read, Flujo, [encoding(utf8)]),
                       json_read_dict(Flujo, Datos),
                       close(Flujo)),
    encontrar_combinaciones(Datos.combinaciones, 1, Combinaciones).

encontrar_combinaciones([], _, []).
encontrar_combinaciones([Dict|Resto], Id, [combinacion(Id, Cursos)|Otros]) :-
    maplist(crear_curso, Dict.selecciones, Cursos),
    Sig is Id + 1,
    encontrar_combinaciones(Resto, Sig, Otros).

crear_curso(D, curso(Carrera, Codigo, Grupo, Creditos, Area)) :-
    atom_string(Carrera, D.carrera),
    atom_string(Codigo, D.codigo),
    Grupo = D.grupo,
    Creditos = D.creditos,
    atom_string(Area, D.area).
