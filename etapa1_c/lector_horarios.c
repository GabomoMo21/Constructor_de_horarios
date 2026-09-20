#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lector_horarios.h"

static void limpiar_cadena(char *texto) {
    int i = 0;
    int j = 0;

    while (texto[i] != '\0') {
        if (texto[i] != '"' && texto[i] != '\r' && texto[i] != '\n') {
            texto[j++] = texto[i];
        }
        i++;
    }

    texto[j] = '\0';
}

static int parsear_linea_csv(char *linea, char campos[][MAX_LINEA], int max_campos) {
    char campo[MAX_LINEA];
    int pos_campo = 0;
    int total_campos = 0;
    int entre_comillas = 0;
    char *p = linea;

    while (*p != '\0' && total_campos < max_campos) {
        if (*p == '"') {
            entre_comillas = !entre_comillas;
        } else if (*p == ',' && !entre_comillas) {
            campo[pos_campo] = '\0';
            limpiar_cadena(campo);
            strcpy(campos[total_campos], campo);
            total_campos++;
            pos_campo = 0;
        } else if (pos_campo < MAX_LINEA - 1) {
            campo[pos_campo++] = *p;
        }
        p++;
    }

    if (total_campos < max_campos) {
        campo[pos_campo] = '\0';
        limpiar_cadena(campo);
        strcpy(campos[total_campos], campo);
        total_campos++;
    }

    return total_campos;
}

static int buscar_curso(Curso catalogo[], int total_cursos,
                        const char *carrera, const char *codigo) {
    for (int i = 0; i < total_cursos; i++) {
        if (strcmp(catalogo[i].carrera, carrera) == 0 &&
            strcmp(catalogo[i].codigo, codigo) == 0) {
            return i;
        }
    }

    return -1;
}

static void guardar_texto(char destino[], int tam_destino, const char *origen) {
    strncpy(destino, origen, tam_destino - 1);
    destino[tam_destino - 1] = '\0';
}

static void guardar_requisito(char destino[], int tam_destino, const char *origen) {
    if (origen[0] == '\0') {
        guardar_texto(destino, tam_destino, "No hay");
    } else {
        guardar_texto(destino, tam_destino, origen);
    }
}

static void parsear_horarios(const char *texto, Curso *curso) {
    const char *p = texto;
    int periodo_actual = 0;
    int grupo_actual = 0;

    while (*p != '\0') {
        int periodo;
        int grupo;
        int caracteres_leidos = 0;

        if (sscanf(p, "P%d-G%d=%n", &periodo, &grupo, &caracteres_leidos) == 2 &&
            caracteres_leidos > 0) {
            periodo_actual = periodo;
            grupo_actual = grupo;
            p += caracteres_leidos;
            continue;
        }

        char dia[4];
        char hora_inicio[6];
        char hora_fin[6];
        caracteres_leidos = 0;

        if (sscanf(p, "%3[A-Z][%5[0-9:]-%5[0-9:]]%n",
                   dia, hora_inicio, hora_fin, &caracteres_leidos) == 3 &&
            caracteres_leidos > 0) {

            if (curso->cant_horarios >= MAX_HORARIOS) {
                fprintf(stderr, "Advertencia: demasiados horarios para %s\n", curso->codigo);
                return;
            }

            Horario horario;
            horario.periodo = periodo_actual;
            horario.grupo = grupo_actual;
            guardar_texto(horario.dias, sizeof(horario.dias), dia);
            guardar_texto(horario.horainicio, sizeof(horario.horainicio), hora_inicio);
            guardar_texto(horario.horafin, sizeof(horario.horafin), hora_fin);

            curso->horarios[curso->cant_horarios] = horario;
            curso->cant_horarios++;

            p += caracteres_leidos;
            continue;
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

    char linea[MAX_LINEA];
    char campos[MAX_CAMPOS][MAX_LINEA];
    int total_cursos = 0;
    int es_encabezado = 1;

    while (fgets(linea, sizeof(linea), archivo) != NULL) {
        linea[strcspn(linea, "\r\n")] = '\0';

        if (linea[0] == '\0') {
            continue;
        }

        if (es_encabezado) {
            es_encabezado = 0;
            continue;
        }

        int total_campos = parsear_linea_csv(linea, campos, MAX_CAMPOS);

        if (total_campos < MAX_CAMPOS) {
            continue;
        }

        const char *carrera = campos[0];
        const char *codigo = campos[1];
        const char *nombre = campos[2];
        const char *texto_horarios = campos[4];

        int pos = buscar_curso(catalogo, total_cursos, carrera, codigo);

        if (pos == -1) {
            if (total_cursos >= MAX_CURSOS) {
                fprintf(stderr, "Advertencia: se alcanzo el maximo de cursos (%d)\n", MAX_CURSOS);
                break;
            }

            pos = total_cursos;

            guardar_texto(catalogo[pos].carrera, sizeof(catalogo[pos].carrera), carrera);
            guardar_texto(catalogo[pos].codigo, sizeof(catalogo[pos].codigo), codigo);
            guardar_texto(catalogo[pos].nombre, sizeof(catalogo[pos].nombre), nombre);
            catalogo[pos].creditos = atoi(campos[3]);
            guardar_requisito(catalogo[pos].requisitos, sizeof(catalogo[pos].requisitos), campos[5]);
            guardar_requisito(catalogo[pos].correquisitos, sizeof(catalogo[pos].correquisitos), campos[6]);

            catalogo[pos].cant_horarios = 0;
            catalogo[pos].cumple_requisitos = 0;
            catalogo[pos].cumple_correquisitos = 0;
            catalogo[pos].puede_matricular = 0;
            catalogo[pos].tiene_choque = 0;

            total_cursos++;
        }

        parsear_horarios(texto_horarios, &catalogo[pos]);
    }

    fclose(archivo);
    return total_cursos;
}
