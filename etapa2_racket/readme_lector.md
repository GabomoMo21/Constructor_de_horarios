# Etapa 2 - Racket

## Descripción general

Esta etapa toma como entrada el catálogo ya procesado por la parte en C y un archivo de preferencias del estudiante.

La responsabilidad de esta parte es convertir esos archivos en estructuras de Racket que puedan ser utilizadas por los demás módulos del proyecto.

Actualmente la estructura de trabajo es:

```text
etapa2_racket/
├── tipos.rkt
├── utilidades_csv.rkt
├── lector_catalogo.rkt
├── lector_preferencias.rkt
└── tests/
    ├── test_lector.rkt
    ├── test_preferencias.rkt
    └── test_integracion_lectores.rkt
```

La idea es mantener los módulos separados por responsabilidad para que cada integrante pueda trabajar en su parte sin depender demasiado de los demás.

## 1. Flujo general de datos

La etapa en C recibe:

```text
datos/entrada/horarios.csv
datos/entrada/historial.csv
```

y genera:

```text
datos/salida/catalogo_procesado.csv
```

Racket no vuelve a procesar directamente `historial.csv` ni `horarios.csv`.

El flujo es:

```text
historial.csv ──┐
                │
                ▼
              C
                ▲
                │
horarios.csv ───┘
                │
                ▼
catalogo_procesado.csv
                │
                ▼
lector_catalogo.rkt
                │
                ▼
(Listof Grupo)
```

Además, Racket recibe:

```text
datos/entrada/preferencias.csv
```

que se procesa así:

```text
preferencias.csv
       │
       ▼
lector_preferencias.rkt
       │
       ▼
Preferencias
```

Finalmente, los demás módulos trabajan con:

```text
(Listof Grupo)
Preferencias
```

## 2. tipos.rkt

`tipos.rkt` contiene las estructuras compartidas por todos los módulos.

Este archivo funciona como contrato común del proyecto. Si se modifica una estructura, el cambio debe coordinarse con el resto del grupo porque puede afectar varios módulos.

Los demás archivos lo importan con:

```racket
(require "tipos.rkt")
```

o, desde `tests/`:

```racket
(require "../tipos.rkt")
```

### Horario

Representa un bloque horario.

```racket
(struct Horario
  ([dia : String]
   [inicio : Integer]
   [fin : Integer])
  #:transparent)
```

Ejemplo:

```text
MIE[07:30-09:20]
```

se representa como:

```racket
(Horario "MIE" 450 560)
```

Las horas se convierten a minutos desde las 00:00:

```text
07:30 -> 450
09:20 -> 560
18:00 -> 1080
```

Esto permite que el módulo de compatibilidad compare horarios usando enteros en lugar de trabajar con texto.

### IdGrupo

Identifica un grupo de forma única.

```racket
(struct IdGrupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [grupo : Integer])
  #:transparent)
```

La identidad del grupo se forma con:

```text
carrera + codigo + periodo + grupo
```

Ejemplo:

```racket
(IdGrupo
 "Ingeniería en Computadores"
 "CE1101"
 2
 1)
```

representa:

```text
CE1101 P2-G1
```

El período se conserva porque puede existir, por ejemplo:

```text
P1-G1
P2-G1
```

para el mismo curso.

### Grupo

Representa una opción concreta de grupo dentro del catálogo.

```racket
(struct Grupo
  ([carrera : String]
   [codigo : String]
   [periodo : Integer]
   [numero : Integer]
   [creditos : Integer]
   [horarios : (Listof Horario)])
  #:transparent)
```

Ejemplo conceptual:

```text
Curso: CE1101
Periodo: P1
Grupo: G1
Créditos: 3

MIE 07:30-09:20
VIE 07:30-09:20
```

queda representado como:

```racket
(Grupo
 "Ingeniería en Computadores"
 "CE1101"
 1
 1
 3
 (list
  (Horario "MIE" 450 560)
  (Horario "VIE" 450 560)))
```

### Preferencias

Representa las preferencias del estudiante.

```racket
(struct Preferencias
  ([carrera : String]
   [grupos-interes : (Listof IdGrupo)]
   [creditos-min : Integer]
   [creditos-max : Integer])
  #:transparent)
```

Ejemplo:

```racket
(Preferencias
 "Ingeniería en Computadores"
 (list
  (IdGrupo "Ingeniería en Computadores" "CE1101" 1 1)
  (IdGrupo "Ingeniería en Computadores" "CE1101" 2 1)
  (IdGrupo "Ingeniería en Computadores" "MA1102" 1 2))
 12
 18)
```

### Combinacion

Será utilizada por el generador y los módulos posteriores.

```racket
(struct Combinacion
  ([grupos : (Listof Grupo)]
   [creditos-totales : Integer])
  #:transparent)
```

Representa una combinación de grupos junto con la suma total de créditos.

## 3. utilidades_csv.rkt

Este archivo contiene funciones genéricas para trabajar con CSV.

No contiene lógica específica del catálogo ni de las preferencias.

Actualmente expone:

```racket
(provide separar-csv texto-a-entero)
```

### separar-csv

Firma:

```racket
(: separar-csv (-> String (Listof String)))
```

Recibe una línea CSV y devuelve una lista con sus campos.

A diferencia de un `string-split` simple, esta función respeta campos entre comillas.

Ejemplo:

```text
Ingeniería en Computadores,CE1101,P1,G1,12,18
```

se convierte en una lista equivalente a:

```racket
(list
 "Ingeniería en Computadores"
 "CE1101"
 "P1"
 "G1"
 "12"
 "18")
```

Esta función es reutilizada por `lector_catalogo.rkt` y `lector_preferencias.rkt`.

### texto-a-entero

Firma:

```racket
(: texto-a-entero (-> String Integer))
```

Convierte un texto numérico a entero.

Ejemplo:

```racket
(texto-a-entero "12")
```

devuelve:

```text
12
```

Si el texto no representa un entero válido, genera un error.

La función es genérica y no conoce conceptos como `P1` o `G1`.

## 4. lector_catalogo.rkt

Este módulo se encarga de leer:

```text
datos/salida/catalogo_procesado.csv
```

La función pública es:

```racket
leer-catalogo
```

Firma:

```racket
(: leer-catalogo
   (-> Path-String (Listof Grupo)))
```

Los demás módulos solamente necesitan utilizar esta función.

### Estructura actual del catálogo procesado

El archivo generado por C contiene:

```text
Carrera
Codigo
Nombre
Creditos
Horarios
Requisitos
Correquisitos
TieneChoque
PuedeMatricular
```

Para construir los `Grupo`, el lector utiliza principalmente:

```text
Carrera
Codigo
Creditos
Horarios
PuedeMatricular
```

La lógica de requisitos y correquisitos ya fue aplicada anteriormente por C, por lo que Racket no necesita recalcularla.

### hora-a-minutos

Convierte una hora `HH:MM` a minutos.

Ejemplo:

```text
07:30 -> 450
18:00 -> 1080
```

### texto-a-horario

Convierte:

```text
MIE[07:30-09:20]
```

en:

```racket
(Horario "MIE" 450 560)
```

### texto-a-grupo

Convierte:

```text
P1-G3=MIE[07:30-09:20];VIE[07:30-09:20]
```

en una estructura `Grupo`.

El resultado conserva:

```text
carrera
codigo
periodo
numero de grupo
creditos
bloques horarios
```

### parsear-grupos

Una fila del catálogo puede contener varios grupos separados por `|`.

Ejemplo:

```text
P1-G1=... | P1-G2=... | P2-G1=...
```

se transforma en:

```racket
(list Grupo Grupo Grupo)
```

Si el campo de horarios contiene `No hay`, devuelve:

```racket
'()
```

### procesar-fila

Procesa una fila completa del catálogo.

Primero separa las columnas usando `separar-csv`.

Después revisa `PuedeMatricular`.

Si:

```text
PuedeMatricular = SI
```

genera los grupos correspondientes.

Si:

```text
PuedeMatricular = NO
```

devuelve una lista vacía.

Por lo tanto, todos los grupos producidos por `leer-catalogo` pertenecen a cursos que C ya determinó como habilitados.

### Resultado actual

Con el catálogo utilizado durante las pruebas, `leer-catalogo` generó:

```text
672 grupos
```

Cada grupo conserva correctamente:

```text
carrera
codigo
periodo
numero
creditos
horarios
```

También se verificó que `P1-G1` y `P2-G1` se mantienen como grupos distintos.

## 5. lector_preferencias.rkt

Este módulo lee:

```text
datos/entrada/preferencias.csv
```

Su función pública es:

```racket
leer-preferencias
```

Firma:

```racket
(: leer-preferencias
   (-> Path-String Preferencias))
```

### Formato utilizado

El archivo tiene:

```csv
Carrera,Codigo,Periodo,Grupo,CreditosMin,CreditosMax
Ingeniería en Computadores,CE1101,P1,G1,12,18
Ingeniería en Computadores,CE1101,P1,G4,12,18
Ingeniería en Computadores,CE1101,P2,G1,12,18
Ingeniería en Computadores,MA1102,P1,G2,12,18
Ingeniería en Computadores,MA1102,P2,G3,12,18
```

Todas las filas deben mantener:

```text
misma carrera
mismo crédito mínimo
mismo crédito máximo
```

Puede haber varios grupos del mismo curso.

### texto-a-periodo

Convierte:

```text
P1 -> 1
P2 -> 2
```

### texto-a-grupo

Convierte:

```text
G1 -> 1
G15 -> 15
```

### fila-a-id-grupo

Convierte una fila en un `IdGrupo`.

Ejemplo:

```text
Ingeniería en Computadores,CE1101,P2,G1,12,18
```

produce:

```racket
(IdGrupo
 "Ingeniería en Computadores"
 "CE1101"
 2
 1)
```

### validar-rango-creditos

Comprueba:

```text
creditos-min >= 0
creditos-min <= creditos-max
```

Ejemplo válido:

```text
12 - 18
```

Ejemplo inválido:

```text
18 - 12
```

### procesar-filas-preferencias

Procesa todas las filas y comprueba:

```text
la carrera sea la misma
el mínimo sea el mismo
el máximo sea el mismo
cada fila tenga la cantidad esperada de campos
el rango de créditos sea válido
```

Después construye una única estructura `Preferencias`.

## 6. Codificación de los CSV

Los archivos deben guardarse en UTF-8.

Esto es importante para carreras y textos que contienen caracteres como:

```text
í
ó
á
é
ñ
```

Por ejemplo:

```text
Ingeniería en Computadores
```

Si el CSV no está guardado en UTF-8 puede aparecer incorrectamente como:

```text
Ingenier�a en Computadores
```

Esto no es solo visual. Si después se comparan las carreras con `string=?`, las dos cadenas no coincidirían.

En Excel se recomienda guardar como:

```text
CSV UTF-8 (delimitado por comas) (*.csv)
```

## 7. Pruebas

Las pruebas están dentro de:

```text
tests/
```

### test_lector.rkt

Prueba el lector del catálogo.

Se verificó:

```text
lectura del archivo completo
cantidad de grupos
conversión de horas
conversión de bloques horarios
conservación de P1 y P2
varios bloques por grupo
acceso a carrera, código, período, grupo y créditos
```

### test_preferencias.rkt

Prueba el archivo de preferencias.

Verifica:

```text
lectura de carrera
lectura de créditos mínimos y máximos
creación de IdGrupo
cantidad de grupos de interés
consistencia de carrera
rango válido
```

### test_integracion_lectores.rkt

Prueba ambos lectores juntos.

El flujo es:

```text
catalogo_procesado.csv
        ↓
leer-catalogo
        ↓
(Listof Grupo)
        │
        ▼
comparación
        ▲
        │
Preferencias
        ↑
leer-preferencias
        ↑
preferencias.csv
```

La prueba verifica que todos los grupos solicitados en preferencias existan realmente dentro del catálogo.

La comparación utiliza:

```text
carrera
codigo
periodo
grupo
```

Con las preferencias utilizadas actualmente se obtuvo:

```text
Cantidad de grupos en el catálogo:
672

Cantidad de grupos de interés:
5

CE1101 P1-G1
CE1101 P1-G4
CE1101 P2-G1
MA1102 P1-G2
MA1102 P2-G3
```

Todos fueron encontrados correctamente.

## 8. Cómo utilizar los lectores desde otros módulos

Para leer el catálogo:

```racket
(require "lector_catalogo.rkt")

(define grupos
  (leer-catalogo
   "../datos/salida/catalogo_procesado.csv"))
```

`grupos` tendrá tipo:

```racket
(Listof Grupo)
```

Para leer preferencias:

```racket
(require "lector_preferencias.rkt")

(define preferencias
  (leer-preferencias
   "../datos/entrada/preferencias.csv"))
```

`preferencias` tendrá tipo:

```racket
Preferencias
```

## 9. Datos disponibles para compatibilidad

El módulo de compatibilidad puede consultar:

```racket
(Grupo-carrera grupo)
(Grupo-codigo grupo)
(Grupo-periodo grupo)
(Grupo-numero grupo)
(Grupo-creditos grupo)
(Grupo-horarios grupo)
```

Para cada horario:

```racket
(Horario-dia horario)
(Horario-inicio horario)
(Horario-fin horario)
```

No necesita volver a interpretar cadenas como:

```text
MIE[07:30-09:20]
```

porque el lector ya realizó esa conversión.

## 10. Datos disponibles para el generador

El generador puede utilizar el `(Listof Grupo)` producido por `leer-catalogo` y la estructura `Preferencias` producida por `leer-preferencias`.

Los grupos de interés se obtienen con:

```racket
(Preferencias-grupos-interes preferencias)
```

El rango de créditos con:

```racket
(Preferencias-creditos-min preferencias)
(Preferencias-creditos-max preferencias)
```

La carrera con:

```racket
(Preferencias-carrera preferencias)
```

## 11. Sobre P1 y P2

Actualmente el período se conserva intencionalmente.

En el catálogo existen casos donde un mismo curso puede tener:

```text
P1-G1
P2-G1
```

con horarios diferentes.

Por lo tanto, `G1` por sí solo no identifica completamente al grupo.

La identidad utilizada es:

```text
(carrera, codigo, periodo, grupo)
```

Esto también permite que las preferencias distingan entre:

```text
CE1101 P1-G1
CE1101 P2-G1
```

Si posteriormente el equipo decide modificar el significado de `P1` y `P2`, el cambio debe hacerse de forma coordinada porque actualmente forma parte de `IdGrupo` y `Grupo`.

## 12. Responsabilidad de cada archivo

```text
tipos.rkt
    Define las estructuras compartidas.

utilidades_csv.rkt
    Contiene funciones genéricas para procesar CSV.

lector_catalogo.rkt
    Convierte catalogo_procesado.csv en (Listof Grupo).

lector_preferencias.rkt
    Convierte preferencias.csv en Preferencias.

tests/test_lector.rkt
    Pruebas del catálogo.

tests/test_preferencias.rkt
    Pruebas de preferencias.

tests/test_integracion_lectores.rkt
    Comprueba que catálogo y preferencias sean compatibles.
```

## 13. Interfaces públicas

Las interfaces principales son:

```racket
leer-catalogo
; Path-String -> (Listof Grupo)
```

y:

```racket
leer-preferencias
; Path-String -> Preferencias
```

Las estructuras compartidas están disponibles desde:

```racket
tipos.rkt
```

El resto de funciones de los lectores son auxiliares internas.

## 14. Estado actual

Actualmente se ha comprobado:

```text
lector_catalogo.rkt funcionando
lector_preferencias.rkt funcionando
utilidades_csv.rkt funcionando
tipos.rkt integrado con ambos lectores
P1 y P2 conservados correctamente
horas convertidas a minutos
varios bloques por grupo correctamente procesados
preferencias convertidas a IdGrupo
rango de créditos validado
codificación UTF-8 comprobada
integración catálogo + preferencias comprobada
grupos de preferencias validados contra el catálogo
```

A partir de estas salidas, los módulos de compatibilidad, generación, filtros y exportación pueden trabajar sin volver a procesar los archivos de entrada.
