# CEmestre — Etapa 1 (C) — Estado del proyecto

Este README describe lo que ya está hecho (Persona 1 y Persona 2) para que **Persona 3**
(choques de horario) y **Persona 4** (ciclos + exportación + documentación final)
puedan arrancar sin tener que leer todo el código desde cero.

---

## 1. Estructura de archivos

```
horarios.h            Structs compartidos: Curso, Horario, constantes
horarios.csv          Catálogo de cursos (entrada) — recolectado por Persona 1
historial.csv         Cursos aprobados por el estudiante (entrada) — formato Persona 2

lector_horarios.h/.c  Persona 1: carga y limpieza del catálogo (cargar_catalogo)
historial.h/.c        Persona 2: historial + validación de requisitos/correquisitos

main.c                Único main() del proyecto. Aquí se van enganchando los módulos.
```

Cada persona trabaja en su propio `.c`/`.h` y **no debe tener un `main()` propio**
en el archivo que sube al repo final (para probar su módulo solo, pueden hacer un
`main_prueba_personaX.c` aparte y no subirlo, o subirlo fuera de la compilación
final).

### Cómo compilar todo lo que hay hasta ahora

```bash
gcc -Wall -o proyecto lector_horarios.c historial.c main.c
./proyecto        # en Windows: .\proyecto.exe
```

---

## 2. Formato del archivo de entrada `horarios.csv`

Columnas (separadas por coma, con encabezado en la primera línea):

```
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos
```

- **Requisitos / Correquisitos**: códigos separados por `;` (ej. `CE1101;CE1104;MA1403`),
  o el texto literal `No hay` si el curso no tiene.
- **Horarios**: grupos separados por ` | `, cada uno con este formato:

  ```
  P1-G1=MIE[18:00-20:50];VIE[18:00-19:50]
  ```

  Es decir: `Periodo-Grupo = DIA[hora_inicio-hora_fin];DIA[hora_inicio-hora_fin];...`
  Un mismo grupo puede reunirse varios días (por eso el `;` dentro del grupo).
  Los días vienen en 3 letras: `LUN, MAR, MIE, JUE, VIE, SAB`.

## 3. Formato de `historial.csv` (Persona 2)

Un código de curso por línea, con encabezado `Codigo`:

```
Codigo
MA0101
CE1101
CE1104
...
```

---

## 4. Structs en `horarios.h`

```c
typedef struct {
    int grupo;
    char dias[10];
    char horainicio[6];   // "HH:MM"
    char horafin[6];      // "HH:MM"
} Horario;

typedef struct {
    char codigo[10];
    char nombre[maxstr];
    int creditos;
    char requisitos[maxstr];
    char correquisitos[maxstr];
    Horario horarios[5];
    int cant_horarios;

    /* Llenados por Persona 2 */
    int cumple_requisitos;
    int cumple_correquisitos;
    int puede_matricular;

    /* Persona 3 debe llenar este campo */
    int tiene_choque;
} Curso;
```

`catalogo[]` (arreglo de `Curso`, tamaño `maxcursos` = 100) es la estructura
central que van a ir llenando **todas** las etapas. Persona 3 no crea una
estructura nueva: recorre `catalogo[]`, compara los `Horario` de cada curso
contra los de los demás, y marca `tiene_choque = 1` cuando corresponda.

---

## 5. Funciones ya disponibles

### `lector_horarios.h` (Persona 1)
```c
int cargar_catalogo(const char *nombre_archivo, Curso catalogo[]);
```
Devuelve la cantidad de cursos cargados (o -1 si falla). Llena todo excepto
`cumple_requisitos`, `cumple_correquisitos`, `puede_matricular` y `tiene_choque`.

### `historial.h` (Persona 2)
```c
int cargar_historial(const char *nombre_archivo, char historial[][10], int max_historial);
int esta_aprobado(char historial[][10], int total_historial, const char *codigo);
int cumple_lista_requisitos(const char *lista_str, char historial[][10], int total_historial);
void validar_requisitos_catalogo(Curso catalogo[], int total_cursos, char historial[][10], int total_historial);
```

---

## 6. ⚠️ IMPORTANTE — Revisar antes de programar los choques

El parseo actual de horarios tiene **dos limitaciones** que van a afectar
directamente el trabajo de Persona 3. Conviene resolverlas en equipo (probablemente
entre Persona 1 y Persona 3) antes de avanzar mucho con la detección de choques:

1. **El arreglo `horarios[5]` es demasiado pequeño.** Varios cursos del catálogo
   real tienen 20 o hasta 30 grupos distintos (ej. `MA0101` tiene 43 entradas de
   horario). Con `Horario horarios[5]`, solo se guardan los primeros 5 bloques de
   horario que aparecen en el texto — se pierde información real. Para detectar
   choques bien, hace falta poder guardar todos los horarios de todos los grupos
   de un curso (por ejemplo, subir el tamaño del arreglo, o usar un arreglo
   dinámico/una constante más alta en el archivo de constantes).

2. **El número de grupo no se está guardando correctamente.** En
   `lector_horarios.c`, la función `parsear_horario_str` se llama así:

   ```c
   parsear_horario_str(str_horario, 1, &catalogo[pos]);
   ```

   El `1` es un valor fijo — es decir, **todos** los bloques de horario de un
   curso quedan marcados con `grupo = 1`, sin importar si en realidad eran del
   grupo `P1-G1`, `P2-G3`, etc. Para el choque de horarios esto importa mucho:
   un estudiante solo se matricula en **un grupo** de cada curso, así que hay
   que poder identificar qué bloques de horario pertenecen al mismo grupo (para
   no comparar, por accidente, un grupo contra otro grupo del mismo curso, y
   sobre todo para saber qué franjas van juntas cuando el estudiante elige un
   grupo específico).

   Sugerencia: cambiar `parsear_horario_str` para que extraiga el identificador
   real (ej. `"P1-G1"`) del texto y lo guarde como texto en `Horario`, en vez de
   pasar un entero fijo.

Documenten en el README final cómo resolvieron esto — es justo el tipo de "caso
límite real" que pide la rúbrica (sección 2.2.2 del enunciado).

---

## 7. Tarea de Persona 3: detección de choques de horario

**Objetivo:** para cada par de cursos (y cada par de grupos dentro de esos
cursos), determinar si sus horarios se traslapan en el mismo día.

**Sugerencia de módulo** (siguiendo el mismo patrón que `historial.h/.c`):

```c
// choques.h
#ifndef CHOQUES_H
#define CHOQUES_H
#include "horarios.h"

/* Compara dos bloques de horario y devuelve 1 si se traslapan
 * (mismo día y las horas se cruzan), 0 si no. */
int horarios_chocan(Horario h1, Horario h2);

/* Recorre todo el catálogo, compara cada curso contra los demás,
 * y llena el campo tiene_choque de cada Curso. */
void detectar_choques_catalogo(Curso catalogo[], int total_cursos);

#endif
```

**Lógica para comparar dos bloques de horario:**
1. Si `h1.dias` y `h2.dias` son distintos (ej. `"MAR"` vs `"MIE"`), no chocan.
2. Si son el mismo día, revisar si los rangos `[horainicio, horafin]` se
   traslapan. Dos rangos `[A, B]` y `[C, D]` se traslapan si `A < D && C < B`
   (hay que convertir `"HH:MM"` a minutos totales para comparar como números,
   no como texto).

**Integrar en `main.c`:** agregar `#include "choques.h"` y llamar
`detectar_choques_catalogo(catalogo, total_cursos);` después de cargar el
catálogo (no depende del historial ni de nada de Persona 2).

**Dato de la Guía de Horarios:** hay cursos sin horario definido (campo
`Horarios` vacío en el CSV, ej. `SE1100`, `CI1407`) — esos simplemente no
generan bloques de `Horario` (`cant_horarios = 0`) y nunca chocan con nada;
el código de Persona 1 ya los deja con `cant_horarios = 0`, así que la
función de choques debe manejar ese caso sin fallar.

---

## 8. Convenciones del proyecto

- Todo el código en C, paradigma imperativo (obligatorio, ver enunciado).
- Uso obligatorio de `structs`.
- Constantes (`maxcursos`, `maxstr`, `maxhistorial`, etc.) van en los `.h`,
  no dispersas en el código.
- Nombres de funciones y variables en español, `snake_case`.
- Cada módulo tiene su `.h` con los prototipos que expone al resto del equipo.