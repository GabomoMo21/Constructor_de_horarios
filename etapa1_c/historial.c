#include <stdio.h>
#include <string.h>
#include "historial.h"

// Carga los codigos de cursos aprobados
int cargar_historial(const char *nombre_archivo,
                     char historial[][MAX_CODIGO], int max_historial) {
    FILE *archivo = fopen(nombre_archivo, "r");

    if (archivo == NULL) {
        fprintf(stderr, "Error al abrir el archivo de historial %s\n", nombre_archivo);
        return -1;
    }

    char buffer[64];
    int total = 0;
    int es_encabezado = 1;

    while (fgets(buffer, sizeof(buffer), archivo)) {
        // Quitar el salto de linea
        buffer[strcspn(buffer, "\r\n")] = '\0';

        if (strlen(buffer) == 0) {
            continue;
        }

        // La primera linea contiene el encabezado
        if (es_encabezado) {
            es_encabezado = 0;
            continue;
        }

        if (total >= max_historial) {
            fprintf(stderr,
                    "Advertencia: se alcanzo el maximo de cursos en el historial (%d)\n",
                    max_historial);
            break;
        }

        strncpy(historial[total], buffer, MAX_CODIGO - 1);
        historial[total][MAX_CODIGO - 1] = '\0';
        total++;
    }

    fclose(archivo);
    return total;
}

// Revisa si un codigo aparece en el historial
int esta_aprobado(char historial[][MAX_CODIGO],
                  int total_historial, const char *codigo) {
    for (int i = 0; i < total_historial; i++) {
        if (strcmp(historial[i], codigo) == 0) {
            return 1;
        }
    }

    return 0;
}
