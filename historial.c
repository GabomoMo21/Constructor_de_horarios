#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "historial.h"

int cargar_historial(const char *nombre_archivo, char historial[][10], int max_historial) {
    FILE *archivo = fopen(nombre_archivo, "r");

    if (archivo == NULL) {
        fprintf(stderr, "Error al abrir el archivo de historial %s\n", nombre_archivo);
        return -1;
    }

    char buffer[64];
    int total = 0;
    int es_encabezado = 1;

    while (fgets(buffer, sizeof(buffer), archivo)) {
        /* quitar salto de línea, igual que en lector_horarios.c */
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

        strncpy(historial[total], buffer, 9);
        historial[total][9] = '\0';
        total++;
    }

    fclose(archivo);
    return total;
}

int esta_aprobado(char historial[][10], int total_historial, const char *codigo) {
    for (int i = 0; i < total_historial; i++) {
        if (strcmp(historial[i], codigo) == 0) {
            return 1;
        }
    }
    return 0;
}

int cumple_lista_requisitos(const char *lista_str, char historial[][10], int total_historial) {
    /* Si el curso no tiene requisitos, se cumple automáticamente */
    if (strcmp(lista_str, "No hay") == 0) {
        return 1;
    }

    /* strtok modifica la cadena, así que trabajamos sobre una copia */
    char copia[maxstr];
    strncpy(copia, lista_str, sizeof(copia) - 1);
    copia[sizeof(copia) - 1] = '\0';

    char *token = strtok(copia, ";");
    while (token != NULL) {
        if (!esta_aprobado(historial, total_historial, token)) {
            return 0; /* falta al menos un requisito */
        }
        token = strtok(NULL, ";");
    }

    return 1;
}

void validar_requisitos_catalogo(Curso catalogo[], int total_cursos,
                                  char historial[][10], int total_historial) {
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].cumple_requisitos =
            cumple_lista_requisitos(catalogo[i].requisitos, historial, total_historial);
        catalogo[i].cumple_correquisitos =
            cumple_lista_requisitos(catalogo[i].correquisitos, historial, total_historial);

        catalogo[i].puede_matricular = catalogo[i].cumple_requisitos;
    }
}
