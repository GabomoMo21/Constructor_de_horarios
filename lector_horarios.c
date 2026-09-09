#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void procesar_linea(char *linea){
    char *ptr = linea;
    char token[512];
    int idx = 0;
    int entre_comillas = 0;

    while (*ptr != '\0'){
        if (*ptr == '"'){
            entre_comillas = !entre_comillas;
        }
        else if (*ptr == ',' && !entre_comillas){
            token[idx] = '\0';
            printf("Dato:%s\t", token);
            idx = 0;
        }
        else {
            if (idx < (int)sizeof(token)-1){
                token[idx++] = *ptr;
            }
        }
        ptr++;
    }
    token [idx] = '\0';
    printf("Dato: %s\n", token);

}


int main (){
    FILE *archivohorario = fopen("horarios.csv", "r");
    if (archivohorario == NULL){
        fprintf (stderr, "Error al abrir el archivo");
        return 1;
    }
    char buffer[2048];

    while (fgets(buffer, sizeof(buffer), archivohorario)){
        buffer [strcspn (buffer, "\r\n")] = 0;
        procesar_linea(buffer);
    }

    fclose(archivohorario);
    return 0;
}