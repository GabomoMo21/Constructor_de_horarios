#include <string.h>
#include "requisitos.h"
#include "historial.h"
#include "catalogo.h"

// Revisa que todos los requisitos esten aprobados
static int cumple_lista_requisitos(const char *lista,
                                   char historial[][MAX_CODIGO], int total_historial) {
    if (lista[0] == '\0' || strcmp(lista, "No hay") == 0) {
        return 1;
    }

    // strtok modifica la cadena, por eso se usa una copia
    char copia[MAX_STR];
    strncpy(copia, lista, sizeof(copia) - 1);
    copia[sizeof(copia) - 1] = '\0';

    char *codigo = strtok(copia, ";");

    while (codigo != NULL) {
        if (!esta_aprobado(historial, total_historial, codigo)) {
            return 0;
        }
        codigo = strtok(NULL, ";");
    }

    return 1;
}

// Revisa si un correquisito ya fue aprobado o se puede llevar junto al curso
static int correquisito_disponible(const char *codigo, const char *carrera,
                                    Curso catalogo[], int total_cursos,
                                    char historial[][MAX_CODIGO], int total_historial) {
    if (esta_aprobado(historial, total_historial, codigo)) {
        return 1;
    }

    int pos = buscar_curso(catalogo, total_cursos, carrera, codigo);

    if (pos == -1) {
        return 0;
    }

    return catalogo[pos].cumple_requisitos;
}

// Revisa todos los correquisitos indicados para un curso
static int cumple_lista_correquisitos(const char *lista, const char *carrera,
                                      Curso catalogo[], int total_cursos,
                                      char historial[][MAX_CODIGO], int total_historial) {
    if (lista[0] == '\0' || strcmp(lista, "No hay") == 0) {
        return 1;
    }

    char copia[MAX_STR];
    strncpy(copia, lista, sizeof(copia) - 1);
    copia[sizeof(copia) - 1] = '\0';

    char *codigo = strtok(copia, ";");

    while (codigo != NULL) {
        if (!correquisito_disponible(codigo, carrera, catalogo, total_cursos,
                                     historial, total_historial)) {
            return 0;
        }
        codigo = strtok(NULL, ";");
    }

    return 1;
}

// Actualiza la validacion de requisitos, correquisitos y matricula
void validar_requisitos_catalogo(Curso catalogo[], int total_cursos,
                                  char historial[][MAX_CODIGO], int total_historial) {
    // Primero se revisan los requisitos de todos los cursos
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].cumple_requisitos =
            cumple_lista_requisitos(catalogo[i].requisitos,
                                    historial, total_historial);
    }

    // Despues se revisan los correquisitos usando el resultado anterior
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].cumple_correquisitos =
            cumple_lista_correquisitos(catalogo[i].correquisitos,
                                       catalogo[i].carrera,
                                       catalogo, total_cursos,
                                       historial, total_historial);

        catalogo[i].puede_matricular =
            catalogo[i].cumple_requisitos && catalogo[i].cumple_correquisitos;
    }
}
