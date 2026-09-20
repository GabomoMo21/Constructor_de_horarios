#ifndef ESTRUCTURAS_H
#define ESTRUCTURAS_H

#include "constantes.h"

typedef struct {
    int periodo;
    int grupo;
    char dias[10];
    char horainicio[6];
    char horafin[6];
} Horario;

typedef struct {
    char carrera[MAX_STR];
    char codigo[MAX_CODIGO];
    char nombre[MAX_STR];
    int creditos;
    char requisitos[MAX_STR];
    char correquisitos[MAX_STR];
    Horario horarios[MAX_HORARIOS];
    int cant_horarios;
    int cumple_requisitos;
    int cumple_correquisitos;
    int puede_matricular;
    int tiene_choque;
} Curso;

#endif
