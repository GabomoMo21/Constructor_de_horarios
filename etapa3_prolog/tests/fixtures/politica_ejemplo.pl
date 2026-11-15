% Politica de ejemplo para las pruebas
max_porcentaje('Ingeniería en Computadores', 70).
max_porcentaje('Ingeniería Ambiental', 70).
max_cursos_area(3).
incompatibles(curso('Ingeniería en Computadores', 'MA0101'),
              curso('Ingeniería Ambiental', 'MA0101')).
incompatibles(curso('Ingeniería en Computadores', 'FI1101'),
              curso('Ingeniería Ambiental', 'FI1101')).
