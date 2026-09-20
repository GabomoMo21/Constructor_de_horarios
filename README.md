# CEmestre

CEmestre es el proyecto del curso **Paradigmas de Programación (CE1106)**. La idea del proyecto es construir, por etapas, un sistema que ayude a preparar una matrícula a partir del plan de estudios, el historial del estudiante y los horarios disponibles.

Cada etapa se trabaja como un programa independiente. En esta primera parte se utiliza **C** y el resultado que se genere servirá como entrada para la siguiente etapa del proyecto.

## Etapa 1 - C

Esta etapa se encarga de cargar y organizar los datos de los cursos, leer el historial de cursos aprobados por el estudiante y hacer las validaciones necesarias antes de pasar la información a las siguientes partes del proyecto.

El flujo general de esta etapa es:

1. Leer el catálogo desde `horarios.csv`.
2. Leer los cursos aprobados desde `historial.csv`.
3. Validar requisitos y correquisitos de cada curso.
4. Revisar los horarios para detectar choques entre cursos y grupos.
5. Revisar el grafo de requisitos con DFS para detectar ciclos.
6. Exportar el catálogo procesado a un archivo que pueda usar la siguiente etapa.

Los módulos de lectura, historial y choques ya están separados. El catálogo también conserva la carrera, el periodo y el grupo de cada bloque de horario, para que las validaciones posteriores trabajen con los datos completos. Todavía falta integrar la detección de ciclos y la exportación final.

## Estructura del repositorio

```text
CEmestre/
├── README.md
├── .gitignore
│
├── etapa1_c/
│   ├── main.c
│   ├── constantes.h
│   ├── estructuras.h
│   ├── lector_horarios.c
│   ├── lector_horarios.h
│   ├── historial.c
│   ├── historial.h
│   ├── choques.c
│   └── choques.h
│
└── datos/
    ├── entrada/
    │   ├── horarios.csv
    │   └── historial.csv
    │
    └── salida/
```

La carpeta `etapa1_c` contiene solamente el código de la primera etapa. Los archivos de entrada y salida se mantienen en `datos` para no mezclar el código fuente con la información que procesa el programa.

Cuando se agreguen las siguientes etapas, cada una tendrá su propia carpeta. De esta forma el código de C, Racket, Prolog y Java puede mantenerse separado aunque todos formen parte del mismo proyecto.

## Archivos principales

| Archivo | Función |
|---|---|
| `main.c` | Coordina la ejecución de los diferentes módulos. |
| `constantes.h` | Guarda los límites y constantes utilizados por el programa. |
| `estructuras.h` | Contiene las estructuras compartidas, como `Curso` y `Horario`. |
| `lector_horarios.c/.h` | Lee el catálogo y convierte los datos del CSV a las estructuras de C. |
| `historial.c/.h` | Lee el historial del estudiante y valida requisitos y correquisitos. |
| `choques.c/.h` | Compara bloques de horario para determinar si existe un choque. |
| `datos/entrada/horarios.csv` | Catálogo recolectado de las dos carreras trabajadas por el grupo. |
| `datos/entrada/historial.csv` | Códigos de los cursos que el estudiante ya aprobó. |
| `datos/salida/` | Lugar donde se guardará el archivo producido por esta etapa. |

## Datos de entrada

### `horarios.csv`

El catálogo actual contiene **83 filas** entre Ingeniería en Computadores e Ingeniería Ambiental. Cada fila representa un curso dentro de una carrera y utiliza las siguientes columnas:

```text
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos
```

Los horarios incluyen el periodo, el grupo y uno o más bloques de día y hora. Por ejemplo:

```text
P1-G1=MIE[07:30-09:20];VIE[07:30-09:20]
```

Esto representa el grupo 1 del periodo 1, con lecciones miércoles y viernes en el horario indicado. El lector guarda cada bloque por separado, pero mantiene el periodo y el grupo al que pertenece.

En el archivo hay cursos que comparten código entre las dos carreras. Por esa razón, el programa usa la combinación de carrera y código para distinguirlos. Esto evita mezclar cursos como `FI1101`, que no tiene exactamente los mismos requisitos en ambos planes.

### `historial.csv`

El historial es más simple. Contiene los códigos de los cursos que el estudiante ya aprobó:

```text
Codigo
MA0101
CE1101
CE1104
```

Estos códigos se usan para comprobar los requisitos y correquisitos del catálogo.

## Cómo funciona el programa

`main.c` funciona como punto de entrada y llama a los demás módulos. La intención es mantener ahí solamente el orden general del programa y dejar la lógica específica en su archivo correspondiente.

Por ejemplo, la lectura del catálogo se realiza en `lector_horarios.c`, la revisión del historial en `historial.c` y la comparación de horarios en `choques.c`. Esto permite revisar o modificar una parte sin tener que concentrar todo el programa en un solo archivo.

Para la detección de choques, dos bloques chocan cuando pertenecen al mismo día y sus rangos de hora se traslapan. Si un curso tiene varios grupos o varios bloques por grupo, se deben revisar todos los bloques cargados.

Para los requisitos se utiliza el historial del estudiante. Cada requisito indicado para un curso se compara con los códigos de los cursos aprobados. Los correquisitos se manejan por separado porque forman parte de la validación de matrícula.

## Decisiones tomadas hasta ahora

Se utilizan **arreglos estáticos y `structs`** porque el tamaño del catálogo es pequeño y conocido. Esto mantiene la implementación sencilla y evita usar memoria dinámica donde no hace falta.

Las constantes se colocan en `constantes.h` para que los tamaños máximos no queden repetidos en varios archivos. Las estructuras compartidas se mantienen en `estructuras.h`, ya que son utilizadas por más de un módulo.

El catálogo actual llega hasta **84 bloques de horario en un mismo curso**, por lo que se reservó espacio para 100 bloques por curso. También se aumentó el tamaño máximo de una línea del CSV a 4096 caracteres, porque algunos campos de horarios son bastante largos. Son límites fijos porque el archivo es pequeño y conocido, y así no hace falta usar memoria dinámica.

Los requisitos y correquisitos vacíos del CSV se guardan como `No hay`. Esto permite que el resto del programa trate de la misma forma los registros vacíos y los que ya venían escritos de esa manera.

También se separaron los datos del código fuente. Esta decisión es importante para las siguientes etapas, porque el archivo producido por C será consumido después por otro programa y no por funciones internas de esta misma etapa.

## Compilación

Desde la raíz del repositorio se puede compilar la etapa actual con:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/choques.c -o cemestre
```

En Windows se puede agregar la extensión `.exe` al nombre del ejecutable:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/choques.c -o cemestre.exe
```

## Ejecución

El programa debe ejecutarse desde la raíz del repositorio para que las rutas relativas a `datos/entrada` y `datos/salida` funcionen correctamente.

Linux/macOS:

```bash
./cemestre
```

Windows:

```text
cemestre.exe
```

## Estado de desarrollo

La reorganización inicial del repositorio y la adaptación del lector al catálogo actual ya están hechas. El programa carga las 83 filas del CSV, conserva carrera, periodo y grupo, y puede leer todos los bloques de horario del archivo sin recortarlos.

Todavía falta cerrar la forma en que se usarán los correquisitos para `puede_matricular`, implementar la detección de ciclos con DFS y generar el archivo de salida. Esta sección se mantendrá mientras se desarrolla la etapa y se puede reemplazar por la documentación final cuando todas las partes estén integradas.
