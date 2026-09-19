#include <stdio.h>
#include "horarios.h"
#include "lector_horarios.h"   
#include "historial.h"
#include "choques.h"


int main() {
    Curso catalogo[maxcursos];
    char historial[maxhistorial][10];

    int total_cursos = cargar_catalogo("horarios.csv", catalogo);
    if (total_cursos <= 0) {
        printf("Error: no se pudo cargar el catalogo.\n");
        return 1;
    }
    printf("Cursos cargados: %d\n", total_cursos);

    int total_historial = cargar_historial("historial.csv", historial, maxhistorial);
    if (total_historial < 0) {
        printf("Error: no se pudo cargar el historial.\n");
        return 1;
    }
    printf("Cursos aprobados en el historial: %d\n\n", total_historial);

    validar_requisitos_catalogo(catalogo, total_cursos, historial, total_historial);

    detectar_choques_catalogo(catalogo, total_cursos);

    for (int i = 0; i < total_cursos; i++) {
        printf("[%s] %s -> requisitos: %s | cumple_requisitos: %s | puede_matricular: %s\n",
               catalogo[i].codigo,
               catalogo[i].nombre,
               catalogo[i].requisitos,
               catalogo[i].cumple_requisitos ? "SI" : "NO",
               catalogo[i].puede_matricular ? "SI" : "NO");
    }
    return 0;
}
