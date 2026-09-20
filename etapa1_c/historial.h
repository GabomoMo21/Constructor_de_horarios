#ifndef HISTORIAL_H
#define HISTORIAL_H

#include "constantes.h"

int cargar_historial(const char *nombre_archivo,
                     char historial[][MAX_CODIGO], int max_historial);
int esta_aprobado(char historial[][MAX_CODIGO],
                  int total_historial, const char *codigo);

#endif
