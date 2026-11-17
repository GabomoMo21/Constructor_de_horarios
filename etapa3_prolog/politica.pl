% Política académica de CEmestre (Etapa 3).
% Solo hechos: reglas.pl los lee con cargar_politica/1. Se pueden editar los
% valores sin tocar el código; los nombres de carrera y los códigos deben
% escribirse igual que en el catálogo (con tildes, entre comillas simples).

% Balance entre carreras: porcentaje máximo de los créditos totales de una
% combinación que puede aportar cada carrera (0-100). Una carrera sin hecho
% no tiene límite.
max_porcentaje('Ingeniería en Computadores', 70).
max_porcentaje('Ingeniería Ambiental', 70).

% Límite por área: una combinación no puede tener más de N cursos de una
% misma área. Debe haber exactamente un hecho.
max_cursos_area(3).

% Incompatibilidades: no se pueden llevar ambos cursos a la vez porque cubren
% el mismo contenido. La relación es simétrica (basta declararla una vez).

% Ingeniería económica: mismo curso con distinto código en cada plan.
incompatibles(curso('Ingeniería en Computadores', 'PI5516'),
              curso('Ingeniería Ambiental', 'AE5121')).

% Métodos numéricos: «Análisis numérico para la ingeniería» (Computadores) y
% «Métodos numéricos» (Ambiental) cubren la misma base de cálculo numérico.
incompatibles(curso('Ingeniería en Computadores', 'CE1111'),
              curso('Ingeniería Ambiental', 'MA3106')).

% Estadística: «Probabilidad y estadística» (Computadores) y «Análisis
% estadístico para ingeniería ambiental» son el curso de estadística de cada plan.
incompatibles(curso('Ingeniería en Computadores', 'PI2609'),
              curso('Ingeniería Ambiental', 'AI2101')).

% Matemática general: el mismo curso (MA0101) aparece en ambos planes; llevarlo
% por las dos carreras sería repetirlo.
incompatibles(curso('Ingeniería en Computadores', 'MA0101'),
              curso('Ingeniería Ambiental', 'MA0101')).
