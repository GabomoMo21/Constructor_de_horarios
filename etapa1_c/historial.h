#ifndef HISTORIAL_H
#define HISTORIAL_H

#include "estructuras.h"

int cargar_historial(const char *nombre_archivo,
                     char historial[][MAX_CODIGO], int max_historial);
int esta_aprobado(char historial[][MAX_CODIGO],
                  int total_historial, const char *codigo);
int cumple_lista_requisitos(const char *lista_str,
                            char historial[][MAX_CODIGO], int total_historial);
void validar_requisitos_catalogo(Curso catalogo[], int total_cursos,
                                  char historial[][MAX_CODIGO], int total_historial);

#endif
