# CEmestre

CEmestre es el proyecto del curso **Paradigmas de Programación (CE1106)**. El proyecto se desarrolla por etapas y cada una utiliza un paradigma distinto. En esta primera etapa se usa **C** para cargar el catálogo de cursos, revisar requisitos y correquisitos, detectar choques de horario, validar ciclos en los requisitos y generar un archivo que pueda utilizar la siguiente etapa.

Cada etapa funciona como un programa independiente. En este caso, el programa recibe los archivos de entrada desde `datos/entrada` y genera `datos/salida/catalogo_procesado.csv`.

## Funcionalidad de la Etapa 1

El programa realiza el siguiente proceso:

1. Carga el catálogo desde `horarios.csv`.
2. Carga los cursos aprobados desde `historial.csv`.
3. Valida los requisitos y correquisitos de cada curso.
4. Compara los bloques de horario para detectar choques.
5. Recorre el grafo de requisitos con DFS para detectar ciclos.
6. Exporta el catálogo procesado a un archivo CSV.

El programa no genera un horario final ni selecciona combinaciones de cursos. Esa parte corresponde a las siguientes etapas del proyecto.

## Arquitectura del proyecto

```text
Constructor_de_horarios/
├── README.md
├── .gitignore
│
├── etapa1_c/
│   ├── main.c
│   ├── constantes.h
│   ├── estructuras.h
│   ├── lector_horarios.c
│   ├── lector_horarios.h
│   ├── catalogo.c
│   ├── catalogo.h
│   ├── historial.c
│   ├── historial.h
│   ├── requisitos.c
│   ├── requisitos.h
│   ├── choques.c
│   ├── choques.h
│   ├── ciclos.c
│   ├── ciclos.h
│   ├── exportador.c
│   └── exportador.h
│
└── datos/
    ├── entrada/
    │   ├── horarios.csv
    │   └── historial.csv
    │
    └── salida/
        └── catalogo_procesado.csv
```

La separación se hizo por responsabilidad. `main.c` mantiene el orden general de ejecución y cada módulo contiene una parte específica del procesamiento.

| Archivo | Función |
|---|---|
| `main.c` | Coordina la ejecución de la etapa. |
| `constantes.h` | Contiene los límites utilizados por el programa. |
| `estructuras.h` | Define las estructuras `Curso` y `Horario`. |
| `lector_horarios.c/.h` | Lee el catálogo y convierte los datos del CSV a las estructuras de C. |
| `catalogo.c/.h` | Contiene operaciones reutilizadas sobre el catálogo, como buscar un curso. |
| `historial.c/.h` | Lee el historial y permite consultar si un curso ya fue aprobado. |
| `requisitos.c/.h` | Valida requisitos, correquisitos y matrícula. |
| `choques.c/.h` | Compara bloques de horario para detectar traslapes. |
| `ciclos.c/.h` | Recorre los requisitos con DFS para detectar ciclos. |
| `exportador.c/.h` | Genera el CSV de salida. |

## Datos de entrada

### Catálogo de cursos

`datos/entrada/horarios.csv` contiene cursos de Ingeniería en Computadores e Ingeniería Ambiental con las siguientes columnas:

```text
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos
```

Los horarios conservan el periodo, el grupo y sus bloques de día y hora. Por ejemplo:

```text
P1-G1=MIE[07:30-09:20];VIE[07:30-09:20]
```

El lector guarda cada bloque por separado, pero mantiene el periodo y grupo al que pertenece.

### Historial

`datos/entrada/historial.csv` contiene los códigos de los cursos ya aprobados por el estudiante:

```text
Codigo
MA0101
CE1101
CE1104
```

El historial solamente representa cursos aprobados. Un curso que el estudiante perdió no aparece en este archivo.

## Decisiones de diseño

### Arreglos y estructuras estáticas

Se utilizan arreglos estáticos y `structs` porque el catálogo es pequeño y se conocen límites suficientes para esta etapa. Esto permite mantener la implementación simple y evita agregar memoria dinámica donde no hace falta.

Las constantes se encuentran en `constantes.h` para que los tamaños máximos no queden repetidos en diferentes archivos.

### Identificación de cursos

Un curso se busca usando **carrera y código**. Esto es necesario porque algunos códigos aparecen en ambos planes de estudio y no siempre tienen los mismos requisitos o correquisitos.

Por ejemplo, `FI1101` aparece en las dos carreras y sus condiciones no son iguales. Si se buscara únicamente por código, una carrera podría terminar usando los datos de la otra.

### Lectura de horarios

En el catálogo existen cursos con muchos grupos y bloques de horario. Por ejemplo, cursos como `MA1102` tienen decenas de bloques disponibles. Por esta razón se reservó espacio para hasta `MAX_HORARIOS` bloques por curso y una línea suficientemente amplia para leer los campos largos del CSV.

El lector no depende de que todos los grupos usen exactamente el mismo separador. Busca las marcas de periodo y grupo, como `P1-G2=`, y después reconoce los bloques con formato `DIA[hora-hora]`.

### Requisitos y correquisitos

Los requisitos deben estar aprobados y aparecer en el historial del estudiante.

Los correquisitos se revisan de una forma distinta:

- si el correquisito ya está aprobado, se considera cumplido;
- si no está aprobado, puede considerarse disponible si aparece en la misma carrera y cumple sus propios requisitos;
- si no está aprobado, no aparece en el catálogo o no cumple sus requisitos, el correquisito no se considera disponible.

Esto permite casos como `FI1201`, cuyo correquisito es `FI1101`. Si `FI1101` ya aparece como aprobado en el historial, el correquisito se considera cumplido y el laboratorio puede matricularse aunque el estudiante tenga que repetir únicamente el laboratorio.

### Detección de choques

Dos bloques chocan cuando se encuentran el mismo día y sus rangos de hora se traslapan. Los cursos de carreras diferentes no se comparan entre sí.

Un curso queda con `TieneChoque = SI` cuando al menos uno de sus bloques se cruza con un bloque de otro curso de la misma carrera. El programa revisa todos los grupos cargados antes de asignar este indicador.

### Detección de ciclos

Para los grupos de cuatro integrantes se implementó DFS sobre el grafo de requisitos. No se crea una estructura de grafo adicional: el catálogo ya contiene las relaciones necesarias porque cada curso guarda sus requisitos.

Cada curso utiliza uno de tres estados durante el recorrido:

```text
0 = no visitado
1 = visitando
2 = terminado
```

Si durante el DFS se llega a un curso que todavía está en estado `visitando`, se encontró un ciclo. El programa marca y reporta los cursos involucrados.

Si un requisito no forma parte del catálogo de los primeros semestres cargados, el DFS no puede continuar por esa rama y simplemente sigue con los demás requisitos.

## Decisiones específicas del dataset

Durante la limpieza y adaptación del catálogo se tomaron algunas decisiones a partir de los datos reales:

- Se conserva la carrera porque hay códigos compartidos entre los dos planes de estudio.
- Se conserva el periodo y grupo de cada bloque para no perder información de matrícula.
- Los requisitos o correquisitos vacíos se normalizan internamente como `No hay`.
- Se aumentaron los límites de lectura porque algunos cursos tienen campos de horario extensos y una gran cantidad de bloques.
- `Prueba Avanzada Inglés` aparecía sin código en una versión del catálogo y se corrigió a `CI0205` después de verificar el dato.

## Caso límite real

Uno de los casos encontrados fue la repetición de un mismo código entre las dos carreras. `FI1101`, por ejemplo, aparece en ambos planes, pero sus requisitos y correquisitos no son iguales.

La primera versión del lector buscaba solamente por código, por lo que podía tratar ambas filas como si fueran un solo curso. Se corrigió guardando la carrera dentro de `Curso` y utilizando la combinación **carrera + código** en las búsquedas.

Este mismo criterio se utiliza en la validación de correquisitos y en el DFS para evitar mezclar dependencias de planes distintos.

## Estructuras de datos desarrolladas

### `Horario`

Guarda un bloque específico de un grupo:

```c
int periodo;
int grupo;
char dias[10];
char horainicio[6];
char horafin[6];
```

Un mismo grupo puede ocupar varias posiciones del arreglo de horarios si tiene lecciones en días diferentes.

### `Curso`

Guarda la información necesaria de cada curso:

```text
carrera
codigo
nombre
creditos
requisitos
correquisitos
horarios[]
cant_horarios
cumple_requisitos
cumple_correquisitos
puede_matricular
tiene_choque
```

### Arreglos principales

El catálogo se mantiene en:

```c
Curso catalogo[MAX_CURSOS];
```

El historial utiliza:

```c
char historial[MAX_HISTORIAL][MAX_CODIGO];
```

Para DFS se utilizan arreglos de enteros para guardar el estado de cada curso, la ruta actual y cuáles cursos forman parte de un ciclo. No se utiliza memoria dinámica para estas estructuras.

## Archivo de salida

La etapa genera:

```text
datos/salida/catalogo_procesado.csv
```

Se eligió CSV porque mantiene una estructura sencilla, es fácil de revisar y puede ser leído posteriormente por Racket sin depender del programa en C.

Cada fila incluye:

```text
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos,TieneChoque,PuedeMatricular
```

Se agregó `Carrera` porque es necesaria para distinguir códigos compartidos entre los dos planes.

Los horarios se guardan en un solo campo conservando periodo, grupo, día y hora:

```text
P1-G1=MIE[07:30-09:20];VIE[07:30-09:20] | P1-G2=LUN[10:00-11:50]
```

Los campos de texto se escriben entre comillas para evitar que una coma dentro del texto cambie la cantidad de columnas. `TieneChoque` y `PuedeMatricular` se exportan como `SI` o `NO`.

El archivo se escribe en UTF-8 y usa coma como separador. Si Excel no reconoce automáticamente la codificación o el separador, puede importarse desde **Datos > Desde texto/CSV**, seleccionando **UTF-8** y **coma**. No es necesario modificar el archivo para utilizarlo en la siguiente etapa.

## Manejo de errores y límites

El programa comprueba que los archivos de entrada y salida puedan abrirse antes de continuar. Si no se puede cargar el catálogo o el historial, `main.c` termina la ejecución con un mensaje de error.

También existen límites definidos en `constantes.h`. Si el catálogo, historial o cantidad de horarios supera el espacio reservado, el programa muestra una advertencia en lugar de escribir fuera de los arreglos.

## Compilación

El programa debe compilarse desde la raíz del repositorio.

Linux/macOS:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/catalogo.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/requisitos.c etapa1_c/choques.c etapa1_c/ciclos.c etapa1_c/exportador.c -o cemestre
```

Windows:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/catalogo.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/requisitos.c etapa1_c/choques.c etapa1_c/ciclos.c etapa1_c/exportador.c -o cemestre.exe
```

## Ejecución

El programa se ejecuta desde la raíz para que las rutas relativas funcionen correctamente.

Linux/macOS:

```bash
./cemestre
```

Windows:

```text
cemestre.exe
```

Al finalizar se genera `datos/salida/catalogo_procesado.csv`.

## Pruebas realizadas

Durante la revisión de esta etapa se comprobó que:

- el proyecto compila con `-Wall -Wextra -Wpedantic` sin advertencias;
- todos los registros del catálogo se cargan y se vuelven a exportar;
- los bloques de horario se conservan con su periodo y grupo;
- los códigos compartidos entre carreras se mantienen separados;
- un correquisito ya aprobado se acepta como cumplido;
- el DFS no reporta ciclos en el catálogo actual;
- el DFS sí detecta un ciclo cuando se agrega uno temporalmente para la prueba;
- el archivo de salida conserva las columnas definidas para la siguiente etapa.

## Ejecutable para la revisión

El repositorio ignora archivos compilados para no mezclar binarios con el código fuente durante el desarrollo. Antes de la defensa se debe generar el ejecutable en el equipo que se utilizará para la revisión usando el comando de compilación anterior.
