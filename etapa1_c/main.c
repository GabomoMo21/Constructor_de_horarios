#include <stdio.h>
#include "estructuras.h"
#include "lector_horarios.h"   
#include "historial.h"
#include "choques.h"


int main() {
    Curso catalogo[MAX_CURSOS];
    char historial[MAX_HISTORIAL][MAX_CODIGO];

    int total_cursos = cargar_catalogo("datos/entrada/horarios.csv", catalogo);
    if (total_cursos <= 0) {
        printf("Error: no se pudo cargar el catalogo.\n");
        return 1;
    }
    printf("Cursos cargados: %d\n", total_cursos);

    int total_historial = cargar_historial("datos/entrada/historial.csv", historial, MAX_HISTORIAL);
    if (total_historial < 0) {
        printf("Error: no se pudo cargar el historial.\n");
        return 1;
    }
    printf("Cursos aprobados en el historial: %d\n\n", total_historial);

    validar_requisitos_catalogo(catalogo, total_cursos, historial, total_historial);

    detectar_choques_catalogo(catalogo, total_cursos);

    for (int i = 0; i < total_cursos; i++) {
        printf("[%s | %s] %s -> requisitos: %s | cumple_requisitos: %s | puede_matricular: %s | choque: %s\n",
               catalogo[i].carrera,
               catalogo[i].codigo,
               catalogo[i].nombre,
               catalogo[i].requisitos,
               catalogo[i].cumple_requisitos ? "SI" : "NO",
               catalogo[i].puede_matricular ? "SI" : "NO",
               catalogo[i].tiene_choque ? "SI" : "NO");
    }
    return 0;
}
