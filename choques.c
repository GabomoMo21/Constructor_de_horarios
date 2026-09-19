#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "choques.h"

/* Convierte una hora "HH:MM" a minutos totales */
static int hora_a_minutos(const char *hora_str) {
    int horas = 0, minutos = 0;
    sscanf(hora_str, "%d:%d", &horas, &minutos);
    return horas * 60 + minutos;
}

/* Compara dos bloques de horario */
int horarios_chocan(Horario h1, Horario h2) {
    if (strcmp(h1.dias, h2.dias) != 0) {
        return 0; // Distinto día, no chocan
    }

    int inicio1 = hora_a_minutos(h1.horainicio);
    int fin1 = hora_a_minutos(h1.horafin);
    int inicio2 = hora_a_minutos(h2.horainicio);
    int fin2 = hora_a_minutos(h2.horafin);

    // Dos rangos se traslapan si: A < D && C < B
    if (inicio1 < fin2 && inicio2 < fin1) {
        return 1;
    }
    return 0;
}

/* Recorre el catálogo y detecta choques */
void detectar_choques_catalogo(Curso catalogo[], int total_cursos) {
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].tiene_choque = 0;

        if (catalogo[i].cant_horarios == 0) continue;

        for (int j = 0; j < total_cursos; j++) {
            if (i == j) continue;
            if (catalogo[j].cant_horarios == 0) continue;

            int encontro_cruce = 0;
            for (int h1 = 0; h1 < catalogo[i].cant_horarios; h1++) {
                for (int h2 = 0; h2 < catalogo[j].cant_horarios; h2++) {
                    if (horarios_chocan(catalogo[i].horarios[h1], catalogo[j].horarios[h2])) {
                        encontro_cruce = 1;
                        break;
                    }
                }
                if (encontro_cruce) break;
            }

            if (encontro_cruce) {
                catalogo[i].tiene_choque = 1;
                break;
            }
        }
    }
}