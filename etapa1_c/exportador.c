#include <stdio.h>
#include "exportador.h"

// Escribe un texto entre comillas para mantener valido el CSV
static void escribir_campo_csv(FILE *archivo, const char *texto) {
    fputc('"', archivo);

    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == '"') {
            fputc('"', archivo);
        }
        fputc(texto[i], archivo);
    }

    fputc('"', archivo);
}

// Escribe todos los grupos y bloques de horario de un curso
static void escribir_horarios(FILE *archivo, const Curso *curso) {
    fputc('"', archivo);

    if (curso->cant_horarios == 0) {
        fprintf(archivo, "No hay");
        fputc('"', archivo);
        return;
    }

    int periodo_anterior = -1;
    int grupo_anterior = -1;

    for (int i = 0; i < curso->cant_horarios; i++) {
        Horario horario = curso->horarios[i];

        // Un cambio de periodo o grupo inicia otro grupo en la salida
        if (horario.periodo != periodo_anterior || horario.grupo != grupo_anterior) {
            if (i > 0) {
                fprintf(archivo, " | ");
            }

            fprintf(archivo, "P%d-G%d=", horario.periodo, horario.grupo);
            periodo_anterior = horario.periodo;
            grupo_anterior = horario.grupo;
        } else {
            fprintf(archivo, ";");
        }

        fprintf(archivo, "%s[%s-%s]",
                horario.dias,
                horario.horainicio,
                horario.horafin);
    }

    fputc('"', archivo);
}

// Exporta una fila por curso con los datos procesados en esta etapa
int exportar_catalogo(const char *nombre_archivo, Curso catalogo[], int total_cursos) {
    FILE *archivo = fopen(nombre_archivo, "w");

    if (archivo == NULL) {
        fprintf(stderr, "Error al crear el archivo %s\n", nombre_archivo);
        return -1;
    }

    fprintf(archivo,
            "Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos,TieneChoque,PuedeMatricular\n");

    for (int i = 0; i < total_cursos; i++) {
        escribir_campo_csv(archivo, catalogo[i].carrera);
        fputc(',', archivo);
        escribir_campo_csv(archivo, catalogo[i].codigo);
        fputc(',', archivo);
        escribir_campo_csv(archivo, catalogo[i].nombre);
        fprintf(archivo, ",%d,", catalogo[i].creditos);

        escribir_horarios(archivo, &catalogo[i]);
        fputc(',', archivo);
        escribir_campo_csv(archivo, catalogo[i].requisitos);
        fputc(',', archivo);
        escribir_campo_csv(archivo, catalogo[i].correquisitos);

        fprintf(archivo, ",%s,%s\n",
                catalogo[i].tiene_choque ? "SI" : "NO",
                catalogo[i].puede_matricular ? "SI" : "NO");
    }

    fclose(archivo);
    return 0;
}
