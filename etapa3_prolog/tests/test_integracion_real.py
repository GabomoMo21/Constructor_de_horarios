"""Integracion con modulos reales: se habilita al recibir las partes 1-3.

No usa dobles. Ejecuta la politica de ejemplo en un proceso de SWI-Prolog.
La omision significa pendiente de integracion, NO prueba superada.
"""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
FIX = BASE / 'tests' / 'fixtures'
MODULOS = ['cargador.pl', 'reglas.pl', 'evaluador.pl']


@unittest.skipUnless(shutil.which('swipl') and all((BASE / m).is_file() for m in MODULOS),
                     'Faltan SWI-Prolog o los modulos productivos de Persona 1-3')
class IntegracionReal(unittest.TestCase):
    def test_contrato_reglas_y_extra_grupo_4(self):
        with tempfile.TemporaryDirectory() as tmp:
            salida = Path(tmp) / 'resultados.json'
            cmd = ['swipl', '-q', '-s', str(BASE / 'main.pl'), '--',
                   str(FIX / 'combinaciones_ejemplo.json'),
                   str(FIX / 'politica_ejemplo.pl'), str(salida)]
            proceso = subprocess.run(cmd, capture_output=True, text=True,
                                     timeout=30, check=False)
            self.assertEqual(proceso.returncode, 0, proceso.stderr)
            datos = json.loads(salida.read_text(encoding='utf-8'))['resultados']
            self.assertEqual([r['id'] for r in datos], [1, 2, 3, 4])
            self.assertEqual([r['cumple'] for r in datos], [True, False, True, False])
            self.assertEqual(datos[1]['razon']['regla'], 'incompatibilidad')
            sugerencia = datos[1]['curso_a_quitar']
            self.assertIsNotNone(sugerencia)
            self.assertEqual(sugerencia['codigo'], 'MA0101')
            self.assertIn(sugerencia['carrera'],
                          ['Ingeniería en Computadores', 'Ingeniería Ambiental'])
            self.assertIsNone(datos[3]['curso_a_quitar'])
            self.assertEqual(datos[2]['creditos_totales'], 0)
            for resultado in datos:
                self.assertIsInstance(resultado['cumple'], bool)
                self.assertEqual(resultado['creditos_totales'],
                                 sum(c['creditos'] for c in resultado['selecciones']))


if __name__ == '__main__':
    unittest.main()
