#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lector_horarios.h"

void limpiar_cadena(char *src) {
    int i = 0, j = 0;
    while (src[i]) {
        if (src[i] != '"' && src[i] != '\r' && src[i] != '\n') {
            src[j++] = src[i];
        }
        i++;
    }
    src[j] = '\0';
}

int parsear_linea_csv(char *linea, char tokens[][512], int max_tokens) {
    char *ptr = linea;
    char buffer[512];
    int idx_buf = 0;
    int token_count = 0;
    int entre_comillas = 0;

    while (*ptr != '\0' && token_count < max_tokens) {
        if (*ptr == '"') {
            entre_comillas = !entre_comillas;
        } else if (*ptr == ',' && !entre_comillas) {
            buffer[idx_buf] = '\0';
            limpiar_cadena(buffer);
            strcpy(tokens[token_count++], buffer);
            idx_buf = 0;
        } else {
            if (idx_buf < (int)sizeof(buffer) - 1) {
                buffer[idx_buf++] = *ptr;
            }
        }
        ptr++;
    }
    buffer[idx_buf] = '\0';
    limpiar_cadena(buffer);
    if (token_count < max_tokens) {
        strcpy(tokens[token_count++], buffer);
    }

    return token_count;
}

int buscar_curso(Curso catalogo[], int total_cursos, const char *codigo) {
    for (int i = 0; i < total_cursos; i++) {
        if (strcmp(catalogo[i].codigo, codigo) == 0) {
            return i;
        }
    }
    return -1;
}

void parsear_horario_str(const char *str_horario, int grupo, Curso *curso) {
    char temp[256];
    strncpy(temp, str_horario, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';

    char *p = temp;
    while (*p != '\0' && curso->cant_horarios < 5) {
        if (p[0] >= 'A' && p[0] <= 'Z' && p[1] >= 'A' && p[1] <= 'Z' && p[2] >= 'A' && p[2] <= 'Z' && p[3] == '[') {
            Horario h;
            h.grupo = grupo;
            snprintf(h.dias, sizeof(h.dias), "%.3s", p);
            
            p += 4;
            if (strlen(p) >= 11 && p[5] == '-') {
                snprintf(h.horainicio, sizeof(h.horainicio), "%.5s", p);
                p += 6;
                snprintf(h.horafin, sizeof(h.horafin), "%.5s", p);
                
                curso->horarios[curso->cant_horarios] = h;
                curso->cant_horarios++;
            }
        }
        p++;
    }
}

int cargar_catalogo(const char *nombre_archivo, Curso catalogo[]) {

    FILE *archivo = fopen(nombre_archivo, "r");

    if (archivo == NULL) {
        fprintf(stderr, "Error al abrir el archivo %s\n", nombre_archivo);
        return -1;
    }

    char buffer[2048];
    char tokens[10][512];

    int total_cursos = 0;
    int es_encabezado = 1;

    while (fgets(buffer, sizeof(buffer), archivo)) {

        buffer[strcspn(buffer, "\r\n")] = '\0';

        if (strlen(buffer) == 0)
            continue;

        if (es_encabezado) {
            es_encabezado = 0;
            continue;
        }

        int num_tokens = parsear_linea_csv(buffer, tokens, 10);

        if (num_tokens < 7)
            continue;

        char *codigo = tokens[1];
        char *nombre = tokens[2];
        char *str_horario = tokens[4];

        int pos = buscar_curso(catalogo, total_cursos, codigo);

        if (pos == -1) {

            if (total_cursos >= MAX_CURSOS)
                continue;

            pos = total_cursos;

            strncpy(
                catalogo[pos].codigo,
                codigo,
                sizeof(catalogo[pos].codigo) - 1
            );
            catalogo[pos].codigo[
                sizeof(catalogo[pos].codigo) - 1
            ] = '\0';

            strncpy(
                catalogo[pos].nombre,
                nombre,
                sizeof(catalogo[pos].nombre) - 1
            );
            catalogo[pos].nombre[
                sizeof(catalogo[pos].nombre) - 1
            ] = '\0';

            catalogo[pos].creditos = atoi(tokens[3]);

            strncpy(
                catalogo[pos].requisitos,
                tokens[5],
                sizeof(catalogo[pos].requisitos) - 1
            );
            catalogo[pos].requisitos[
                sizeof(catalogo[pos].requisitos) - 1
            ] = '\0';

            strncpy(
                catalogo[pos].correquisitos,
                tokens[6],
                sizeof(catalogo[pos].correquisitos) - 1
            );
            catalogo[pos].correquisitos[
                sizeof(catalogo[pos].correquisitos) - 1
            ] = '\0';

            catalogo[pos].cant_horarios = 0;
            catalogo[pos].cumple_requisitos = 0;
            catalogo[pos].cumple_correquisitos = 0;
            catalogo[pos].puede_matricular = 0;
            catalogo[pos].tiene_choque = 0;

            total_cursos++;
        }

        parsear_horario_str(
            str_horario,
            1,
            &catalogo[pos]
        );
    }

    fclose(archivo);

    return total_cursos;
