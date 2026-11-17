% Política fija para test_reglas.pl (no editar sin ajustar las pruebas).
max_porcentaje('Ingeniería en Computadores', 70).
max_porcentaje('Ingeniería Ambiental', 60).
max_cursos_area(2).
incompatibles(curso('Ingeniería en Computadores', 'PI5516'),
              curso('Ingeniería Ambiental', 'AE5121')).
incompatibles(curso('Ingeniería en Computadores', 'MA0101'),
              curso('Ingeniería Ambiental', 'MA0101')).
