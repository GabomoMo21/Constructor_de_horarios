#include <string.h>
#include "catalogo.h"

// Busca un curso usando la carrera y el codigo
int buscar_curso(Curso catalogo[], int total_cursos,
                 const char *carrera, const char *codigo) {
    for (int i = 0; i < total_cursos; i++) {
        if (strcmp(catalogo[i].carrera, carrera) == 0 &&
            strcmp(catalogo[i].codigo, codigo) == 0) {
            return i;
        }
    }

    return -1;
}
