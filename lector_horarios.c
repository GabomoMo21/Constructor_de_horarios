#include <stdio.h>
#include <stdlib.h>
#include <string.h>



int main (){
    FILE *archivohorario = fopen("horarios.csv", "r");
    if (archivohorario == NULL){
        printf ("Error al abrir el archivo");
        return 1;
    }
    char buffer[1024];

    while (fgets(buffer, sizeof(buffer), archivohorario)){
        buffer [strcspn (buffer, "\r\n")] = 0;

        char *token = strtok(buffer, ",");

        while (token != NULL){
            printf("Dato: %s\t", token);
            token = strtok(NULL, ",");
        }
        printf("\n");
    }

    fclose(archivohorario);
    return 0;
}