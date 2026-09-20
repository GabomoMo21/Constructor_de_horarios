#include <stdio.h>
#include <string.h>
#include "ciclos.h"
#include "catalogo.h"

// Obtiene un requisito de una lista separada por ;
static int siguiente_requisito(const char *lista, int *posicion, char codigo[]) {
    int i = 0;

    // Ignorar espacios antes del codigo
    while (lista[*posicion] == ' ' || lista[*posicion] == '\t') {
        (*posicion)++;
    }

    if (lista[*posicion] == '\0') {
        return 0;
    }

    // Copiar el codigo hasta ; o hasta el final
    while (lista[*posicion] != '\0' && lista[*posicion] != ';') {
        if (i < MAX_CODIGO - 1) {
            codigo[i++] = lista[*posicion];
        }
        (*posicion)++;
    }

    // Quitar espacios al final del codigo
    while (i > 0 && (codigo[i - 1] == ' ' || codigo[i - 1] == '\t')) {
        i--;
    }

    codigo[i] = '\0';

    if (lista[*posicion] == ';') {
        (*posicion)++;
    }

    return codigo[0] != '\0';
}

// Marca los cursos encontrados dentro de un ciclo
static void marcar_ciclo(int ruta[], int profundidad, int inicio, int en_ciclo[]) {
    for (int i = 0; i <= profundidad; i++) {
        if (ruta[i] == inicio) {
            for (int j = i; j <= profundidad; j++) {
                en_ciclo[ruta[j]] = 1;
            }
            return;
        }
    }
}

// Recorre los requisitos de un curso usando DFS
static void dfs(Curso catalogo[], int total_cursos, int indice,
                int estado[], int ruta[], int profundidad, int en_ciclo[]) {
    // 1 significa que el curso se esta visitando
    estado[indice] = 1;
    ruta[profundidad] = indice;

    if (catalogo[indice].requisitos[0] != '\0' &&
        strcmp(catalogo[indice].requisitos, "No hay") != 0) {
        int posicion = 0;
        char requisito[MAX_CODIGO];

        // Revisar cada requisito del curso actual
        while (siguiente_requisito(catalogo[indice].requisitos,
                                   &posicion, requisito)) {
            int siguiente = buscar_curso(catalogo, total_cursos,
                                         catalogo[indice].carrera, requisito);

            // El requisito puede estar fuera del catalogo actual
            if (siguiente == -1) {
                continue;
            }

            // Si no ha sido visitado, continuar el recorrido
            if (estado[siguiente] == 0) {
                dfs(catalogo, total_cursos, siguiente,
                    estado, ruta, profundidad + 1, en_ciclo);
            }
            // Volver a un curso que se esta visitando indica un ciclo
            else if (estado[siguiente] == 1) {
                marcar_ciclo(ruta, profundidad, siguiente, en_ciclo);
            }
        }
    }

    // 2 significa que ya se termino de revisar el curso
    estado[indice] = 2;
}

// Revisa todo el catalogo y reporta si existen ciclos
int detectar_ciclos_catalogo(Curso catalogo[], int total_cursos) {
    int estado[MAX_CURSOS] = {0};
    int ruta[MAX_CURSOS];
    int en_ciclo[MAX_CURSOS] = {0};
    int hay_ciclo = 0;

    // Iniciar DFS desde cada curso que aun no fue visitado
    for (int i = 0; i < total_cursos; i++) {
        if (estado[i] == 0) {
            dfs(catalogo, total_cursos, i, estado, ruta, 0, en_ciclo);
        }
    }

    // Revisar si algun curso fue marcado como parte de un ciclo
    for (int i = 0; i < total_cursos; i++) {
        if (en_ciclo[i]) {
            hay_ciclo = 1;
            break;
        }
    }

    if (!hay_ciclo) {
        printf("No se encontraron ciclos en los requisitos.\n");
        return 0;
    }

    printf("Se encontraron ciclos en los requisitos.\n");
    printf("Cursos involucrados:\n");

    for (int i = 0; i < total_cursos; i++) {
        if (en_ciclo[i]) {
            printf("  [%s | %s] %s\n",
                   catalogo[i].carrera,
                   catalogo[i].codigo,
                   catalogo[i].nombre);
        }
    }

    return 1;
}
