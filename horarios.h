#ifndef HORARIOS_H
#define HORARIOS_H

#define maxcursos 100
#define maxstr 100

typedef struct {
    int grupo;
    char dias[10];
    char horainicio[6];
    char horafin[6];
} Horario;

typedef struct {
    char codigo[10];
    char nombre[maxstr];
    int creditos;
    char requisitos[maxstr];
    char correquisitos[maxstr];
    Horario horarios[50];
    int cant_horarios;
    int cumple_requisitos;     
    int cumple_correquisitos;  
    int puede_matricular;      
    int tiene_choque;          
} Curso;

#endif