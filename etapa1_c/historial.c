#include <stdio.h>
#include <string.h>
#include "historial.h"

int cargar_historial(const char *nombre_archivo, char historial[][MAX_CODIGO], int max_historial) {
    FILE *archivo = fopen(nombre_archivo, "r");

    if (archivo == NULL) {
        fprintf(stderr, "Error al abrir el archivo de historial %s\n", nombre_archivo);
        return -1;
    }

    char buffer[64];
    int total = 0;
    int es_encabezado = 1;

    while (fgets(buffer, sizeof(buffer), archivo)) {
        // Quitar salto de linea
        buffer[strcspn(buffer, "\r\n")] = '\0';

        if (strlen(buffer) == 0)
            continue;

        if (es_encabezado) {
            es_encabezado = 0;
            continue;
        }

        if (total >= max_historial) {
            fprintf(stderr, "Advertencia: se alcanzo el maximo de cursos en el historial (%d)\n", max_historial);
            break;
        }

        strncpy(historial[total], buffer, MAX_CODIGO - 1);
        historial[total][MAX_CODIGO - 1] = '\0';
        total++;
    }

    fclose(archivo);
    return total;
}

int esta_aprobado(char historial[][MAX_CODIGO], int total_historial, const char *codigo) {
    for (int i = 0; i < total_historial; i++) {
        if (strcmp(historial[i], codigo) == 0) {
            return 1;
        }
    }
    return 0;
}

int cumple_lista_requisitos(const char *lista_str, char historial[][MAX_CODIGO], int total_historial) {
    // Un curso sin requisitos se puede validar directamente
    if (strcmp(lista_str, "No hay") == 0) {
        return 1;
    }

    // strtok modifica la cadena, por eso se usa una copia
    char copia[MAX_STR];
    strncpy(copia, lista_str, sizeof(copia) - 1);
    copia[sizeof(copia) - 1] = '\0';

    char *token = strtok(copia, ";");
    while (token != NULL) {
        if (!esta_aprobado(historial, total_historial, token)) {
            return 0;
        }
        token = strtok(NULL, ";");
    }

    return 1;
}

void validar_requisitos_catalogo(Curso catalogo[], int total_cursos,
                                  char historial[][MAX_CODIGO], int total_historial) {
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].cumple_requisitos =
            cumple_lista_requisitos(catalogo[i].requisitos, historial, total_historial);
        catalogo[i].cumple_correquisitos =
            cumple_lista_requisitos(catalogo[i].correquisitos, historial, total_historial);

        catalogo[i].puede_matricular = catalogo[i].cumple_requisitos;
    }
}
