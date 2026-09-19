# CEmestre — Etapa 1 (C) — Estado del proyecto

Este README describe con todo detalle lo que ya está hecho (Persona 1, Persona 2 y Persona 3) para que Persona 4 (ciclos + exportación + documentación final) pueda arrancar sin tener que leer todo el código desde cero y comprendiendo la arquitectura completa del sistema.

---

## 1. Estructura y organización de archivos

El proyecto se encuentra dividido modularmente para mantener una separación limpia de responsabilidades entre los integrantes del equipo:

- **`horarios.h`**: Contiene las estructuras de datos globales compartidas (`Curso`, `Horario`) y las constantes principales del sistema (como límites de arreglos y strings).

- **`horarios.csv`**: Archivo de entrada que contiene el catálogo completo de cursos recolectado por la Persona 1.

- **`historial.csv`**: Archivo de entrada que contiene los códigos de los cursos aprobados por el estudiante, gestionado por la Persona 2.

- **`lector_horarios.h` y `lector_horarios.c`**: Módulo desarrollado por la Persona 1 encargado de la lectura robusta, carga en memoria y limpieza inicial del catálogo de cursos (`cargar_catalogo`).

- **`historial.h` y `historial.c`**: Módulo desarrollado por la Persona 2 encargado de cargar el historial académico y validar de forma lógica el cumplimiento de requisitos y correquisitos.

- **`choques.h` y `choques.c`**: Módulo desarrollado por la Persona 3 encargado de la conversión de formatos de hora y la detección automatizada de cruces de horario entre los grupos del catálogo.

- **`main.c`**: Archivo principal que integra y ejecuta secuencialmente los módulos anteriores.

### Notas importantes sobre la compilación y desarrollo

Cada integrante trabaja exclusivamente en su propio par de archivos `.c` y `.h`. 

Está estrictamente prohibido que los módulos individuales contengan su propia función `main()` dentro del repositorio final. 

Para realizar pruebas independientes de cada módulo, se pueden crear archivos temporales auxiliares (por ejemplo, `main_prueba_personaX.c`), los cuales no deben subirse ni incluirse en la compilación final del equipo.

### Cómo compilar todo el proyecto hasta esta etapa

Para compilar todos los módulos integrados mediante la línea de comandos con GCC, utiliza la siguiente instrucción:

`gcc -Wall -o proyecto lector_horarios.c historial.c choques.c main.c`

`./proyecto        # En sistemas Windows: .\proyecto.exe`

---

## 2. Formato detallado del archivo de entrada `horarios.csv`

El archivo de catálogo utiliza un formato de valores separados por comas (CSV), asegurando que la primera línea corresponda estrictamente a los encabezados obligatorios:

`Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos`

- **Requisitos / Correquisitos**: Se especifican mediante los códigos oficiales de los cursos separados por un punto y coma (por ejemplo: `CE1101;CE1104;MA1403`). En caso de que un curso no posea requisitos ni correquisitos previos, se debe indicar obligatoriamente con el texto literal `No hay`.

- **Horarios**: Los diferentes grupos disponibles para un curso se encuentran separados por una pleca con espacios (` | `). 

Cada bloque de horario de grupo mantiene la estructura interna siguiente:

`P1-G1=MIE[18:00-20:50];VIE[18:00-19:50]`

En esta nomenclatura, la estructura corresponde a: 
`Periodo-Grupo = DIA[hora_inicio-hora_fin];DIA[hora_inicio-hora_fin];...`

Un mismo grupo académico puede impartirse presencialmente en múltiples días de la semana dentro de la misma semana (motivo por el cual se utiliza el punto y coma `;` para separar los días del mismo grupo). 

Los días de la semana se abrevian estrictamente a 3 letras mayúsculas: `LUN`, `MAR`, `MIE`, `JUE`, `VIE`, `SAB`.

---

## 3. Formato del archivo de entrada `historial.csv` (Persona 2)

Este archivo maneja un registro simplificado de los cursos que el estudiante ya ha superado con éxito en ciclos anteriores. Consiste en una única columna con el encabezado `Codigo`, listando un código alfanumérico por cada línea:

`Codigo`
`MA0101`
`CE1101`
`CE1104`
`...`

---

## 4. Definición de Estructuras (`structs` en `horarios.h`)

Para garantizar la interoperabilidad de los datos entre las distintas etapas del proyecto, se utilizan las siguientes estructuras base centralizadas en el archivo de cabecera común:

typedef struct {
    int grupo;
    char dias[10];
    char horainicio[6];   // Formato estricto de texto "HH:MM"
    char horafin[6];      // Formato estricto de texto "HH:MM"
} Horario;

typedef struct {
    char codigo[10];
    char nombre[maxstr];
    int creditos;
    char requisitos[maxstr];
    char correquisitos[maxstr];
    Horario horarios[50]; // Arreglo ampliado a 50 para soportar cursos masivos con múltiples grupos
    int cant_horarios;

    /* Campos de validación y estado llenados por la Persona 2 */
    int cumple_requisitos;
    int cumple_correquisitos;
    int puede_matricular;

    /* Campos de validación lógica añadidos por la Persona 3 */
    int tiene_choque;
} Curso;

El arreglo global `catalogo[]` (definido con un tamaño estático máximo de `maxcursos` = 100) representa la estructura de datos central sobre la cual iterarán y trabajarán de manera secuencial todas las etapas del sistema.

---

## 5. Especificación de funciones disponibles por módulo

### Módulo `lector_horarios.h` (Persona 1)

- `int cargar_catalogo(const char *nombre_archivo, Curso catalogo[]);`

*Descripción:* Lee el archivo CSV de catálogo, limpia los espacios vacíos y deserializa la información en el arreglo de structs. Retorna la cantidad total de cursos cargados de manera exitosa (o un valor de `-1` en caso de ocurrir un error crítico de lectura). Llena todos los atributos básicos del curso a excepción de los campos de validación lógica y cruces.

### Módulo `historial.h` (Persona 2)

- `int cargar_historial(const char *nombre_archivo, char historial[][10], int max_historial);`
- `int esta_aprobado(char historial[][10], int total_historial, const char *codigo);`
- `int cumple_lista_requisitos(const char *lista_str, char historial[][10], int total_historial);`
- `void validar_requisitos_catalogo(Curso catalogo[], int total_cursos, char historial[][10], int total_historial);`

*Descripción:* Conjunto de funciones utilitarias y de validación académica que cruzan el historial del estudiante contra los requisitos formales de cada materia del catálogo.

### Módulo `choques.h` (Persona 3)

- `int horarios_chocan(Horario h1, Horario h2);`
- `void detectar_choques_catalogo(Curso catalogo[], int total_cursos);`

*Descripción:* Módulo encargado de comparar los bloques horarios de los cursos para identificar empalmes temporales en un mismo día de la semana.

---

## 6. Resolución de casos límite técnicos (Ajustes de la Etapa)

1. **Ampliación del arreglo de horarios:** Durante las pruebas iniciales, el diseño contemplaba un tamaño estático limitado de 5 para el arreglo `horarios[5]`. Sin embargo, al procesar catálogos reales de la institución se identificaron materias con alta densidad de grupos simultáneos (como cursos del área de matemáticas con decenas de opciones). **Solución aplicada:** Se amplió la capacidad de almacenamiento estático a `Horario horarios[50]` dentro de `horarios.h` para blindar el programa ante desbordamientos de memoria y asegurar que ningún grupo quede fuera del análisis.

2. **Cursos sin asignación de horario presencial:** Cursos especiales o seminarios (tales como `SE1100` o proyectos específicos) que poseen campos de horarios completamente vacíos se configuran explícitamente con `cant_horarios = 0`. Esto permite que la lógica de detección de choques los filtre de manera segura sin interrumpir la ejecución ni arrojar fallos de segmentación.

---

## 7. Módulo implementado por la Persona 3: Detección de cruces de horario

Se desarrolló e incorporó de forma integral el módulo `choques.c` y `choques.h` para garantizar que el sistema valide automáticamente si los bloques de clases de distintas opciones se traslapan temporalmente:

- **Conversión matemática de horas:** Se implementó una función auxiliar interna denominada `hora_a_minutos`, la cual transforma de manera exacta el formato de cadena de texto `"HH:MM"` a una representación numérica entera basada en la cantidad total de minutos transcurridos desde la medianoche. Esto permite aplicar la fórmula lógica estándar de traslapo de intervalos (`A < D && C < B`) con absoluta precisión matemática.

- **Validación integrada en el flujo principal:** Se añadió la llamada directa al procedimiento `detectar_choques_catalogo(catalogo, total_cursos);` dentro del archivo controlador `main.c`, evaluando de forma automatizada y transparente el total de los cursos cargados en memoria.

---

## 8. Convenciones generales de desarrollo del proyecto

- **Paradigma:** Lenguaje C bajo un enfoque de programación imperativa estricta, cumpliendo con los lineamientos formales del curso.
- **Uso de estructuras:** Utilización obligatoria de tipos de datos estructurados (`structs`) para modelar las entidades del dominio académico.
- **Manejo de constantes:** Las dimensiones máximas y parámetros globales (`maxcursos`, `maxstr`, `maxhistorial`, etc.) se declaran centralizadamente en los archivos de cabecera (`.h`), evitando el uso de números mágicos dispersos por el código fuente.
- **Nomenclatura:** Todos los identificadores de funciones, variables y atributos siguen rigurosamente el estándar en idioma español utilizando el formato de nomenclatura `snake_case`.
- **Modularidad:** Cada módulo funcional expone limpiamente sus prototipos de funciones a través de su respectivo archivo de cabecera (`.h`), promoviendo el acoplamiento débil y la alta cohesión del software.