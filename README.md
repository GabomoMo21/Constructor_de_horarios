# CEmestre

CEmestre es el proyecto del curso **Paradigmas de Programación (CE1106)**. Cada etapa usa un paradigma diferente y se ejecuta como un programa independiente que lee y genera archivos.

La **Etapa 1 (C)** construye el catálogo validado de cursos, la **Etapa 2 (Racket)** genera combinaciones de horario y la **Etapa 3 (Prolog)** evalúa esas combinaciones con reglas de política académica. El resultado de Prolog se exporta en JSON para su lectura desde Java en la cuarta etapa.

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
├── ejecutar.ps1
├── pruebas.ps1
├── etapa1_c/
│   ├── main.c
│   ├── constantes.h
│   ├── estructuras.h
│   ├── lector_horarios.c / .h
│   ├── catalogo.c / .h
│   ├── historial.c / .h
│   ├── requisitos.c / .h
│   ├── choques.c / .h
│   ├── ciclos.c / .h
│   └── exportador.c / .h
├── etapa2_racket/
│   ├── tipos.rkt
│   ├── utilidades_csv.rkt
│   ├── lector_catalogo.rkt
│   ├── lector_preferencias.rkt
│   ├── compatibilidad.rkt
│   ├── generador.rkt
│   ├── filtros.rkt
│   ├── exportador.rkt
│   ├── main.rkt
│   └── tests/
├── etapa3_prolog/
│   ├── modelo.pl
│   ├── lector.pl
│   ├── politica.pl
│   ├── reglas.pl
│   ├── evaluador.pl
│   ├── exportador.pl
│   ├── main.pl
│   └── tests/
└── datos/
    ├── entrada/
    │   ├── horarios.csv
    │   ├── historial.csv
    │   ├── preferencias.csv
    │   └── preferencias_mixtas_ejemplo.csv
    └── salida/
        ├── catalogo_procesado.csv
        ├── combinaciones.json
        └── resultados.json
```

Los programas se conectan mediante el CSV de C y los JSON de Racket y Prolog. `ejecutar.ps1` ejecuta las tres etapas en ese orden y `pruebas.ps1` realiza las pruebas de cada lenguaje y de la integración.

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
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos,Area
```

La columna `Area` se agrega para las reglas de Prolog. Los horarios conservan el grupo y sus bloques de día y hora. Por ejemplo:

```text
G1=MIE[07:30-09:20];VIE[07:30-09:20]
```

El lector guarda cada bloque por separado, pero mantiene el grupo al que pertenece. Los números de grupo son únicos dentro de cada curso.

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

El lector no depende de que todos los grupos usen exactamente el mismo separador. Busca las marcas de grupo, como `G2=`, y después reconoce los bloques con formato `DIA[hora-hora]`.

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
- Se conserva el grupo de cada bloque para no perder información de matrícula.
- En `datos/entrada/horarios.csv` los grupos están identificados como `G1`, `G2`, etc., con números únicos dentro de cada curso. El lector de C utiliza esa nomenclatura y el exportador la conserva en `catalogo_procesado.csv`.
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
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos,TieneChoque,PuedeMatricular,Area
```

Se agregó `Carrera` porque es necesaria para distinguir códigos compartidos entre los dos planes.

Los horarios se guardan en un solo campo conservando grupo, día y hora:

```text
G1=MIE[07:30-09:20];VIE[07:30-09:20] | G2=LUN[10:00-11:50]
```

Los campos de texto se escriben entre comillas para evitar que una coma dentro del texto cambie la cantidad de columnas. `TieneChoque` y `PuedeMatricular` se exportan como `SI` o `NO`.

El archivo se escribe en UTF-8 y usa coma como separador. Si Excel no reconoce automáticamente la codificación o el separador, puede importarse desde **Datos > Desde texto/CSV**, seleccionando **UTF-8** y **coma**. No es necesario modificar el archivo para utilizarlo en la siguiente etapa.

## Manejo de errores y límites

El programa comprueba que los archivos de entrada y salida puedan abrirse antes de continuar. Si no se puede cargar el catálogo o el historial, `main.c` termina la ejecución con un mensaje de error.

También existen límites definidos en `constantes.h`. Si el catálogo, historial o cantidad de horarios supera el espacio reservado, el programa muestra una advertencia en lugar de escribir fuera de los arreglos.

## Compilación de la Etapa 1

El programa debe compilarse desde la raíz del repositorio.

Linux/macOS:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/catalogo.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/requisitos.c etapa1_c/choques.c etapa1_c/ciclos.c etapa1_c/exportador.c -o cemestre
```

Windows:

```bash
gcc -std=c11 -Wall -Wextra -Wpedantic etapa1_c/main.c etapa1_c/catalogo.c etapa1_c/lector_horarios.c etapa1_c/historial.c etapa1_c/requisitos.c etapa1_c/choques.c etapa1_c/ciclos.c etapa1_c/exportador.c -o cemestre.exe
```

## Ejecución de la Etapa 1

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

## Pruebas de la Etapa 1

Durante la revisión de esta etapa se comprobó que:

- el proyecto compila con `-Wall -Wextra -Wpedantic` sin advertencias;
- todos los registros del catálogo se cargan y se vuelven a exportar;
- los bloques de horario se conservan con su grupo;
- los códigos compartidos entre carreras se mantienen separados;
- un correquisito ya aprobado se acepta como cumplido;
- el DFS no reporta ciclos en el catálogo actual;
- el DFS sí detecta un ciclo cuando se agrega uno temporalmente para la prueba;
- el archivo de salida conserva las columnas definidas para la siguiente etapa.

## Ejecutable de la Etapa 1

El repositorio ignora archivos compilados para no mezclar binarios con el código fuente durante el desarrollo.

## Etapa 2: generación y filtrado de combinaciones (Racket)

### Objetivo y funcionamiento

La Etapa 2 recibe el catálogo validado por C y las preferencias del estudiante. Con esos datos genera combinaciones de grupos sin choques, conserva las que cumplen el rango de créditos y las exporta para Prolog. No elige un horario final, no ordena las alternativas por preferencias y no implementa las restricciones adicionales reservadas para la Etapa 3.

```text
datos/salida/catalogo_procesado.csv  datos/entrada/preferencias.csv
                 |                             |
       lector_catalogo.rkt          lector_preferencias.rkt
                 |                             |
            (Listof Grupo)                Preferencias
                 |_____________________________|
                               |
                       generador.rkt
                         (streams)
                               |
                      compatibilidad.rkt
                   (comprobación por grupo)
                               |
                         filtros.rkt
                    (rango de créditos)
                               |
                        exportador.rkt
                               |
                    combinaciones.json
```

`main.rkt` coordina las llamadas anteriores. La compatibilidad se consulta **durante** la generación, antes de agregar un grupo. Los filtros se aplican a las combinaciones que el generador va produciendo. No se guardan todas las combinaciones en una lista para exportarlas después.

### Módulos y responsabilidades

| Archivo | Responsabilidad |
|---|---|
| `tipos.rkt` | Define las estructuras compartidas de Typed Racket. |
| `utilidades_csv.rkt` | Separa campos CSV respetando comillas y convierte números. |
| `lector_catalogo.rkt` | Lee la salida de C y construye grupos con sus bloques horarios. |
| `lector_preferencias.rkt` | Lee los grupos de interés con su carrera y el rango de créditos. |
| `compatibilidad.rkt` | Verifica traslapes y evita elegir dos grupos del mismo curso. |
| `generador.rkt` | Explora subconjuntos y alternativas por curso mediante streams y poda temprana. |
| `filtros.rkt` | Define un filtro polimórfico y aplica el rango de créditos. |
| `exportador.rkt` | Escribe cada combinación en JSON según se consume el stream. |
| `main.rkt` | Conecta las entradas, la generación, el filtro y la salida. |

### Estructuras de datos desarrolladas

Se eligió **Typed Racket** para declarar los tipos de las funciones y detectar incompatibilidades entre módulos al compilar. Las estructuras son transparentes y no mutables:

| Estructura | Campos | Uso |
|---|---|---|
| `Horario` | `dia`, `inicio`, `fin` | Bloque horario con horas convertidas a minutos. |
| `IdGrupo` | `carrera`, `codigo`, `grupo` | Identificador ligero de un grupo solicitado. |
| `Grupo` | `carrera`, `codigo`, `numero`, `creditos`, `horarios`, `area` | Alternativa completa del catálogo, con varios bloques si corresponde. |
| `Preferencias` | `grupos-interes`, `creditos-min`, `creditos-max` | Restricciones proporcionadas por el estudiante. |
| `Combinacion` | `grupos`, `creditos-totales` | Resultado parcial o completo de la búsqueda, con total acumulado. |

Se identifica un curso por **carrera y código**, y un grupo por **carrera, código y número**. Esto importa porque las dos carreras pueden contener códigos iguales. Los identificadores de las preferencias no duplican horarios ni créditos: el catálogo sigue siendo la fuente de esos datos.

El generador usa temporalmente `(Listof (Listof Grupo))`: cada sublista contiene los grupos alternativos de un mismo curso. La lista `elegidos` y el acumulador `creditos` viajan como argumentos recursivos. Guardar el total dentro de `Combinacion` permite al filtro consultarlo sin sumar los grupos nuevamente; las pruebas del generador verifican que coincida con la suma real.

### Datos de entrada y lectura

**Catálogo procesado:** `datos/salida/catalogo_procesado.csv`, generado por la Etapa 1.

```text
Carrera,Codigo,Nombre,Creditos,Horarios,Requisitos,Correquisitos,TieneChoque,PuedeMatricular,Area
```

`leer-catalogo` incorpora únicamente grupos de cursos con `PuedeMatricular=SI`. Lee cada grupo `G1=...`, separa sus bloques horarios y transforma las horas `HH:MM` en minutos, para que la compatibilidad se calcule con enteros. Si un curso tiene `Horarios=No hay`, no se crea un grupo seleccionable para ese curso.

`TieneChoque` es un indicador del catálogo: no significa que **todos** los grupos del curso choquen con cualquier selección. Por eso la Etapa 2 compara los bloques reales de los grupos elegidos, sin repetir la validación de requisitos que ya realizó C.

**Preferencias:** `datos/entrada/preferencias.csv`.

```csv
Carrera,Codigo,Grupo,CreditosMin,CreditosMax
Ingeniería en Computadores,CE1101,G1,3,7
Ingeniería en Computadores,CE1101,G4,3,7
Ingeniería en Computadores,MA1102,G2,3,7
```

El ejemplo muestra el formato, no necesariamente los datos del archivo de preferencias entregado. Cada fila identifica un grupo aceptable; pueden indicarse varios grupos de un mismo curso. Las filas pueden mezclar carreras, pero deben tener el mismo rango de créditos. El lector rechaza rangos negativos o con mínimo mayor que máximo, así como grupos mal escritos, y conserva los intereses leídos como `IdGrupo`.

El lector de preferencias **no elimina intereses repetidos**. El generador evita incorporar opciones duplicadas con la lista `vistos`. Si se solicita un grupo inexistente o no habilitado, el generador no lo selecciona: actualmente ese caso no detiene la ejecución con un error del lector.

### Decisiones de compatibilidad

`compatibilidad.rkt` representa los bloques como intervalos de minutos. Dos horarios chocan cuando corresponden al mismo día y se cumplen simultáneamente:

```racket
(< (Horario-inicio horario1) (Horario-fin horario2))
(< (Horario-inicio horario2) (Horario-fin horario1))
```

Se utiliza `<` y no `<=` para permitir que una clase termine exactamente cuando comienza otra. `grupos-chocan?` compara todos los bloques de ambos grupos con `ormap`: basta un traslape para que exista choque. `compatible-con-combinacion?` usa `andmap` para exigir compatibilidad con **todos** los grupos ya elegidos. También impide seleccionar dos grupos del mismo curso, aunque sus horarios no choquen.

### Decisiones de generación y optimización

1. **Opciones agrupadas por curso.** `seleccionar-opciones` conserva únicamente los grupos indicados en las preferencias y descarta identificadores repetidos. `agrupar-opciones` reúne las alternativas del mismo curso.
2. **Subconjuntos permitidos.** `explorar-cursos` puede omitir un curso o elegir uno de sus grupos. De esta manera genera alternativas con distintos subconjuntos de los cursos de interés, pero nunca incluye dos grupos del mismo curso ni entrega la combinación completamente vacía. Este comportamiento fue consultado al profesor y confirmado como válido siempre que se respeten las preferencias.
3. **Recursión e inmutabilidad.** Los cursos pendientes, los grupos elegidos y la suma de créditos pasan como parámetros. Se agrega un grupo con `cons` y se invierte la selección con `reverse` al construir una `Combinacion`, sin utilizar `set!`.
4. **Streams reales.** `explorar-cursos`, `explorar-opciones` y `concatenar` construyen la salida con `stream`, `stream-cons` y `empty-stream`, no mediante una lista completa. `concatenar` recibe la siguiente rama como función para evaluarla cuando sea necesaria.
5. **Poda temprana (requisito para cuatro integrantes).** En `explorar-opciones`, antes de descender por un grupo se ejecuta `(compatible? grupo elegidos)`. Si es falso, esa rama devuelve `empty-stream` y no continúa explorando los cursos restantes. Se podan los choques durante la generación, no al terminar cada combinación.

La poda actual es por compatibilidad, **no por créditos máximos**. El rango de créditos se aplica en `filtros.rkt`; separar ambos pasos mantiene claro qué valida cada módulo.

### Filtrado de créditos y polimorfismo paramétrico

`filtros.rkt` define la operación genérica:

```racket
(: filtrar-stream
   (All (A) (-> (-> A Boolean) (Sequenceof A) (Sequenceof A))))
(define (filtrar-stream condicion elementos)
  (stream-filter condicion elementos))
```

`All (A)` expresa que funciona con distintos tipos de elementos y predicados, no solo con `Combinacion`. Se reutiliza en `filtrar-por-creditos` con una `lambda` que llama a `creditos-validos?`. La condición específica obtiene `Combinacion-creditos-totales` y acepta límites **inclusivos** mediante `>=` y `<=`.

Se utiliza `Sequenceof` en las firmas porque es el tipo empleado por `typed/racket/stream`. El flujo concreto sigue siendo un stream y `stream-filter` conserva su procesamiento diferido. La función propia delega la operación de filtrado a la biblioteca; el polimorfismo está en la firma y en que el predicado se recibe como parámetro.

### Formato de salida y justificación

La salida de Racket es **JSON UTF-8**, acordado como contrato hacia la Etapa 3. Cada combinación contiene una lista variable de grupos y sus créditos totales:

```json
{
  "combinaciones": [
    {
      "creditos_totales": 7,
      "selecciones": [
        {"carrera": "Ingeniería en Computadores", "codigo": "CE1101", "grupo": 1, "creditos": 3, "area": "computacion"},
        {"carrera": "Ingeniería en Computadores", "codigo": "MA1102", "grupo": 2, "creditos": 4, "area": "matematica"}
      ]
    }
  ]
}
```

**Por qué JSON:** la relación entre una combinación y sus grupos se representa directamente mediante un arreglo anidado. En CSV habría que repetir datos de la combinación en varias filas o agregar un identificador para agruparlas. Generar hechos Prolog también habría sido posible, pero acoplaría el archivo a ese lenguaje. JSON mantiene una estructura que Prolog puede leer y que Java también puede consumir.

**Cómo se escribe:** `exportador.rkt` recorre el stream con `stream-first` y `stream-rest`; cada elemento se escribe antes de solicitar el siguiente. `escribir-grupos` recorre recursivamente la lista interna de cada combinación. Para insertar comas se pasa el parámetro `primero?`, sin mantener contadores mutables. Se utiliza `display` para la estructura fija y `write-json` para escapar correctamente los valores.

Si ninguna combinación cumple el rango, la salida es un documento válido:

```json
{"combinaciones":[]}
```

Esta exportación no materializa todas las combinaciones en memoria. Si la escritura falla a mitad del proceso, no se garantiza que el archivo de salida quede completo; no se implementó un reemplazo atómico.

### Coordinación desde `main.rkt`

`ejecutar-etapa2` recibe tres rutas: catálogo, preferencias y archivo de salida. Su secuencia es:

```text
leer-catalogo → leer-preferencias → generar-combinaciones
             → filtrar-por-creditos → exportar-combinaciones
```

`main.rkt` no vuelve a implementar lectura, choque de horarios ni serialización. `module+ main` permite ejecutar el programa desde la terminal con tres argumentos, mientras que `provide ejecutar-etapa2` permite llamarlo desde otro archivo.

### Casos límite reales y cómo se trataron

| Caso | Tratamiento |
|---|---|
| Un mismo grupo aparece varias veces en el CSV de preferencias | El lector conserva las filas; `seleccionar-opciones` usa `IdGrupo` y `vistos` para que se considere una sola alternativa. |
| Dos clases terminan y empiezan a la misma hora | Las comparaciones estrictas permiten que sean contiguas sin considerarlas choque. |
| Un grupo tiene varios bloques | La compatibilidad compara todos los bloques; un solo traslape impide agregar el grupo. |
| Dos carreras tienen un mismo código de curso | Los identificadores incluyen la carrera y evitan mezclar planes de estudio. |
| No hay combinaciones dentro del rango | El exportador produce `{"combinaciones":[]}` sin error. |
| Un curso tiene cero créditos | Puede formar parte de una combinación y se sigue evaluando su compatibilidad horaria. |
| Una preferencia no corresponde a un grupo del catálogo | No se genera esa opción; actualmente no se rechaza con un error de lectura. |

Un caso que encontramos durante la integración fue precisamente el de los **intereses repetidos**: no sería correcto producir varias combinaciones idénticas solo porque se escribió la misma fila varias veces. Por eso se evita duplicar opciones en la selección previa a la búsqueda. Las pruebas del generador comprueban este comportamiento; el archivo de preferencias puede conservar duplicados como datos de entrada.

### Instalación y ejecución

La Etapa 2 requiere Racket con Typed Racket y las bibliotecas usadas por los módulos. Para `typed/racket/stream` se instala el paquete:

```powershell
raco pkg install --auto typed-racket-stream
```

Desde la raíz del repositorio:

```powershell
raco make etapa2_racket/main.rkt
racket etapa2_racket/main.rkt datos/salida/catalogo_procesado.csv datos/entrada/preferencias.csv datos/salida/combinaciones.json
```

Es necesario generar antes el catálogo procesado ejecutando la Etapa 1. La Etapa 2 produce el archivo JSON; no crea una interfaz ni elige una combinación como horario definitivo.

En Windows, cuando `racket` o `raco` no están en el `PATH`, pueden ejecutarse mediante la ruta de instalación, por ejemplo:

```powershell
& "C:\Program Files\Racket\Raco.exe" make etapa2_racket/main.rkt
& "C:\Program Files\Racket\Racket.exe" etapa2_racket/main.rkt datos/salida/catalogo_procesado.csv datos/entrada/preferencias.csv datos/salida/combinaciones.json
```

### Pruebas

Los archivos incluidos en `etapa2_racket/tests/` revisan distintas partes del programa:

| Archivo | Qué comprueba |
|---|---|
| `test_lector.rkt` | Lectura de grupos, créditos y bloques horarios del catálogo. |
| `test_preferencias.rkt` | Lectura de los grupos solicitados, rango de créditos e identificadores de interés, incluidas varias carreras. No exige unicidad en el archivo de entrada. |
| `test_integracion_lectores.rkt` | Que los grupos solicitados aparezcan entre los grupos disponibles del catálogo utilizado. |
| `test_compatibilidad.rkt` | Traslapes, horarios contiguos y compatibilidad de grupos. |
| `test_generador.rkt` y el submódulo de `generador.rkt` | Alternativas, subconjuntos, poda temprana, créditos acumulados e intereses repetidos. |
| `test_filtros.rkt` | Límites de créditos, uso polimórfico del filtro y exportación JSON vacía o con resultados. |

Desde la raíz se pueden ejecutar las pruebas independientes de compatibilidad, generación y filtros:

```powershell
raco test etapa2_racket/compatibilidad.rkt etapa2_racket/generador.rkt etapa2_racket/tests/test_compatibilidad.rkt etapa2_racket/tests/test_generador.rkt etapa2_racket/tests/test_filtros.rkt
```

Las pruebas de lectura utilizan rutas relativas a `etapa2_racket/tests/`; para ejecutarlas sin cambiar su código:

```powershell
cd etapa2_racket/tests
raco test test_lector.rkt test_preferencias.rkt test_integracion_lectores.rkt
cd ../..
```


### Alcance de esta entrega

La Etapa 2 genera y filtra alternativas a partir de los grupos elegidos en `preferencias.csv`, que pueden incluir ambas carreras. No recomienda cursos, no presenta horarios definitivos y no aplica las reglas de la Etapa 3. El contrato de salida es el JSON que recibe Prolog.

## Etapa 3: evaluación de política académica (Prolog)

### Objetivo y funcionamiento

La Etapa 3 recibe las combinaciones generadas por Racket y las compara con tres políticas académicas: incompatibilidades entre cursos, límite de cursos por área y balance de créditos entre carreras. Para cada combinación determina si cumple todas las reglas o cuál es la primera regla incumplida. La etapa no crea horarios, no vuelve a filtrar por créditos y no presenta una interfaz gráfica.

```text
combinaciones.json ──> lector.pl ──> combinacion(Id, Cursos)
                                           |
politica.pl ─────────> reglas.pl ──────────> evaluador.pl
                                           |
                                      exportador.pl
                                           |
                                      resultados.json
```

`main.pl` coordina la carga, la evaluación y la exportación. El evaluador aplica las reglas, mientras que el exportador transforma los resultados a JSON para que Java pueda leerlos sin repetir las validaciones.

### Módulos y responsabilidades

| Archivo | Responsabilidad |
|---|---|
| `modelo.pl` | Define las consultas sobre los términos `curso/5` y el cálculo de créditos. |
| `lector.pl` | Lee el JSON de Racket y construye combinaciones con términos de Prolog. |
| `politica.pl` | Contiene los hechos que definen los valores de la política académica. |
| `reglas.pl` | Carga los hechos de política y comprueba las tres reglas. |
| `evaluador.pl` | Determina la primera violación y busca un curso que pueda eliminarse. |
| `exportador.pl` | Recorre las combinaciones, utiliza el evaluador y genera el JSON final. |
| `main.pl` | Conecta los módulos y recibe las rutas desde la línea de comandos. |

### Representación de los datos y carga

La entrada es `datos/salida/combinaciones.json`. Cada selección incluye la carrera, el código, el grupo, los créditos y el área. El lector convierte cada combinación a un término de esta forma:

```prolog
combinacion(Id, [
    curso(Carrera, Codigo, Grupo, Creditos, Area)
]).
```

La lista conserva los cursos elegidos y el identificador mantiene su posición en el archivo. Las carreras, códigos y áreas se representan como átomos; los grupos y créditos se manejan como enteros. Se utiliza una lista de `combinacion/2` y los resultados intermedios se transmiten mediante argumentos, sin mantenerlos en variables globales.

El campo `Area` se definió por curso en `horarios.csv` y se transmite a Prolog a través de C y Racket. Se usa un conjunto común de áreas para las dos carreras: `matematica`, `ciencias`, `computacion`, `ingenieria`, `humanidades` y `gestion`. Por ejemplo, `MA0101` corresponde a `matematica`, `CE1101` a `computacion` y `AI1100` a `ingenieria`. La clasificación utiliza el contenido del curso y no únicamente el prefijo del código.

### Archivo de política y reglas

Los valores de las políticas se guardan como hechos en `etapa3_prolog/politica.pl`. Se separan del código para que puedan modificarse durante la defensa sin reescribir los predicados.

```prolog
max_porcentaje('Ingeniería en Computadores', 70).
max_porcentaje('Ingeniería Ambiental', 70).
max_cursos_area(3).
incompatibles(curso('Ingeniería en Computadores', 'MA0101'),
              curso('Ingeniería Ambiental', 'MA0101')).
```

`cargar_politica/1` lee y valida los hechos del archivo. Los únicos predicados dinámicos se utilizan para almacenar esa política de entrada; no se emplea `assert/retract` para resultados de las combinaciones.

| Regla | Predicado | Criterio |
|---|---|---|
| Incompatibilidades | `violacion_incompatibilidad/2` | Rechaza si aparecen ambos cursos de un par declarado, sin importar el orden. |
| Límite por área | `violacion_area/2` | Rechaza si la cantidad de cursos en alguna área es mayor que `max_cursos_area/1`. |
| Balance | `violacion_balance/2` | Rechaza si alguna carrera supera su porcentaje máximo de los créditos totales. |

Para balance se compara `CreditosCarrera * 100 > Maximo * CreditosTotales`, evitando divisiones y redondeos. Si los créditos totales son cero, ninguna carrera supera su porcentaje. Una carrera sin hecho `max_porcentaje/2` se interpreta con un máximo de 100 %.

Las incompatibilidades se declaran una sola vez; `son_incompatibles/2` permite consultarlas en ambos sentidos. Los pares escogidos corresponden a contenidos repetidos o semejantes entre los planes:

- `PI5516` y `AE5121`: ambos se denominan Ingeniería económica, aunque usan códigos distintos.
- `CE1111` y `MA3106`: Análisis numérico para la ingeniería y Métodos numéricos cubren métodos de cálculo numérico.
- `PI2609` y `AI2101`: Probabilidad y estadística y Análisis estadístico para ingeniería ambiental cubren contenidos de estadística.
- `MA0101` de Computadores y `MA0101` de Ambiental: se trata de Matemática general, presente en ambos planes.

### Primera regla violada

Se acordó el orden **incompatibilidad → área → balance**. Primero se comprueban los pares concretos de cursos, luego la cantidad de cursos de cada área y finalmente el porcentaje global de créditos. `primera_violacion/2` prueba las reglas en ese orden y utiliza el corte (`!`) para conservar únicamente la primera razón. Los predicados `cumple_incompatibilidad/1`, `cumple_area/1` y `cumple_balance/1` usan negación por falla (`\+`) para expresar cumplimiento.

Por ejemplo, con `max_cursos_area(2)`, los cursos `PI5516` de Computadores (3 créditos), `AE5121` de Ambiental (3 créditos) y `AE4208` de Ambiental (4 créditos) suman 10 créditos. Hay una incompatibilidad entre los dos primeros y tres cursos del área `gestion`. El balance es de 30 % y 70 %, dentro de los máximos de la política. Con el orden elegido se informa `incompatibilidad(...)`; si se revisara el área primero, se informaría `limite_area(gestion, 3)`.

### Consultas en más de un modo

`son_incompatibles/2` sirve tanto para comprobar un par conocido como para buscar el curso incompatible con otro. Por ejemplo, después de cargar `reglas.pl` en SWI-Prolog:

```prolog
?- reglas:cargar_politica('etapa3_prolog/politica.pl').
true.

?- reglas:son_incompatibles(
       curso('Ingeniería en Computadores', 'PI5516'),
       curso('Ingeniería Ambiental', 'AE5121')).
true.

?- reglas:son_incompatibles(
       curso('Ingeniería Ambiental', 'MA3106'), X).
X = curso('Ingeniería en Computadores', 'CE1111').
```

`creditos_de_carrera/3` también puede recibir una carrera específica para calcular sus créditos o una carrera libre para enumerar las carreras presentes. Esto aprovecha la unificación y el backtracking de Prolog sin crear predicados separados para cada consulta.

### Requisito adicional para cuatro integrantes

Para cada combinación rechazada, `buscar_curso_a_quitar/2` utiliza `select/3` para elegir un curso y obtener la lista restante. Luego aplica `cumple_todas/1` sobre esa lista, reutilizando las tres validaciones. Se devuelve el primer curso que permite cumplir las reglas; si ninguno sirve, la respuesta es `ninguna`.

También se contempla la eliminación del único curso de una combinación: si la lista vacía resultante cumple las políticas, ese curso es una solución válida. En cambio, eliminar un curso de un par incompatible puede no ser suficiente cuando los créditos restantes superan el balance máximo de una carrera.

### Formato de salida para Java

La salida es `datos/salida/resultados.json`. Se eligió JSON por la estructura de listas de cursos y porque permite representar el veredicto y la razón como campos definidos, sin requerir que Java analice cadenas de texto.

```json
{
  "resultados": [
    {
      "id": 1,
      "creditos_totales": 7,
      "selecciones": [
        {"carrera": "Ingeniería en Computadores", "codigo": "CE1101", "grupo": 1, "creditos": 3, "area": "computacion"},
        {"carrera": "Ingeniería Ambiental", "codigo": "MA1102", "grupo": 2, "creditos": 4, "area": "matematica"}
      ],
      "cumple": true,
      "razon": null,
      "curso_a_quitar": null
    }
  ]
}
```

Para una combinación rechazada, `cumple` es `false`, `razon` indica la regla y su detalle, y `curso_a_quitar` contiene carrera, código y grupo cuando existe una eliminación válida. `null` significa que no corresponde una razón o que no existe un curso cuya eliminación solucione el rechazo.

### Casos límite y pruebas

El proyecto contempla combinaciones con cero créditos, un porcentaje exactamente igual al máximo permitido, un área con exactamente el número de cursos permitido, varias reglas incumplidas al mismo tiempo y rechazos que no pueden resolverse quitando un curso. El lector y el exportador también manejan listas vacías de combinaciones.

Las pruebas automatizadas usan `plunit` para reglas, evaluador, exportación e integración. Los ejemplos de entrada están en `etapa3_prolog/tests/fixtures/`, de modo que las políticas y sus resultados se pueden comprobar sin modificar los datos normales del proyecto.

## Ejecución y pruebas en Windows

Desde la raíz del repositorio se utilizan **PowerShell**, GCC, Racket y SWI-Prolog. Se requieren `gcc`, `racket`, `raco` y `swipl`. Los scripts incluyen las rutas habituales de instalación de Racket y SWI-Prolog en Windows.

### Ejecutar las tres etapas

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\ejecutar.ps1
```

Este comando compila C, genera `catalogo_procesado.csv`, ejecuta Racket con `datos/entrada/preferencias.csv` y finalmente evalúa sus combinaciones con Prolog. El resultado se escribe en `datos/salida/resultados.json`.

Para generar un ejemplo con cursos de ambas carreras:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\ejecutar.ps1 -Preferencias datos/entrada/preferencias_mixtas_ejemplo.csv
```

La política puede elegirse mediante `-Politica` para probar otros parámetros con el mismo programa.

### Ejecutar las pruebas

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\pruebas.ps1
```

El script ejecuta las pruebas de Prolog y Racket, comprueba cuatro combinaciones básicas y otros seis casos para demostrar los tres motivos de rechazo y la eliminación de un curso. La tabla que aparece en la terminal muestra el veredicto, la primera regla violada y el curso que se puede quitar. También ejecuta las tres etapas con preferencias de ambas carreras. Los resultados quedan en `datos/salida/resultados_politicas.json` y `datos/salida/resultados.json`.

Los seis casos de `combinaciones_politicas.json` incluyen una combinación aceptada, un rechazo por incompatibilidad, uno por área, uno por balance, una incompatibilidad que no se resuelve quitando un solo curso y un rechazo de un único curso que sí se puede corregir. La prueba de integración comprueba que las bajas propuestas realmente cumplan las tres políticas.

`ejecutar.ps1` muestra también los resultados de la ejecución normal en una tabla, además de guardar el JSON para Java.

Para ejecutar Prolog de forma independiente también se puede utilizar:

```powershell
swipl -q -s etapa3_prolog/main.pl -- datos/salida/combinaciones.json etapa3_prolog/politica.pl datos/salida/resultados.json
```

Los resultados generados pueden abrirse directamente como JSON. Cada etapa conserva su ejecutable o intérprete propio; los scripts únicamente organizan las llamadas y los archivos de intercambio.
