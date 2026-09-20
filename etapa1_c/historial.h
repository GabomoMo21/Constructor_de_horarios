#ifndef HISTORIAL_H
#define HISTORIAL_H

#include "horarios.h"
#define maxhistorial 100

int cargar_historial(const char *nombre_archivo, char historial[][10], int max_historial);
int esta_aprobado(char historial[][10], int total_historial, const char *codigo);
int cumple_lista_requisitos(const char *lista_str, char historial[][10], int total_historial);
void validar_requisitos_catalogo(Curso catalogo[], int total_cursos,
                                  char historial[][10], int total_historial);

#endif
