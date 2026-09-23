#include <stdio.h>
#include "estructuras.h"
#include "lector_horarios.h"
#include "historial.h"
#include "requisitos.h"
#include "choques.h"
#include "ciclos.h"
#include "exportador.h"

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

    detectar_ciclos_catalogo(catalogo, total_cursos);
    printf("\n");

    if (exportar_catalogo("datos/salida/catalogo_procesado.csv", catalogo, total_cursos) != 0) {
        return 1;
    }
    printf("Archivo de salida generado: datos/salida/catalogo_procesado.csv\n\n");
    return 0;
}
