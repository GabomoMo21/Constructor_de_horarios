"""Prueba de integracion del codigo de Persona 4 con dobles de Persona 1-3.

Se ejecuta con: python3 -m unittest discover -s etapa3_prolog/tests -p 'test_*.py'
Requiere swipl; si no existe se marca como omitida, nunca como prueba exitosa.
"""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
TESTS = BASE / 'tests'


@unittest.skipUnless(shutil.which('swipl'), 'SWI-Prolog no esta instalado')
class ContratoCLI(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for nombre in ('main.pl', 'exportador.pl', 'modelo.pl'):
            shutil.copy2(BASE / nombre, self.root / nombre)
        for nombre in ('cargador.pl', 'reglas.pl', 'evaluador.pl'):
            shutil.copy2(TESTS / 'dobles' / nombre, self.root / nombre)
        self.entrada = TESTS / 'fixtures' / 'combinaciones_ejemplo.json'
        self.politica = TESTS / 'fixtures' / 'politica_ejemplo.pl'
        self.salida = self.root / 'resultados.json'

    def ejecutar(self, *args):
        return subprocess.run(
            ['swipl', '-q', '-s', str(self.root / 'main.pl'), '--', *map(str, args)],
            cwd=self.root, capture_output=True, text=True, timeout=20,
            check=False,
        )

    def test_tres_resultados_y_sugerencia(self):
        p = self.ejecutar(self.entrada, self.politica, self.salida)
        self.assertEqual(p.returncode, 0, p.stderr)
        data = json.loads(self.salida.read_text(encoding='utf-8'))
        self.assertEqual(len(data['resultados']), 4)
        aceptada, rechazada, sin_creditos, sin_sugerencia = data['resultados']
        self.assertEqual(aceptada['id'], 1)
        self.assertEqual(aceptada['creditos_totales'], 7)
        self.assertIs(aceptada['cumple'], True)
        self.assertIsNone(aceptada['razon'])
        self.assertIsNone(aceptada['curso_a_quitar'])
        self.assertEqual(aceptada['selecciones'][0]['area'], 'computacion')
        self.assertEqual(rechazada['id'], 2)
        self.assertIs(rechazada['cumple'], False)
        self.assertEqual(rechazada['razon']['regla'], 'incompatibilidad')
        self.assertEqual(rechazada['curso_a_quitar'], {
            'carrera': 'Ingeniería Ambiental', 'codigo': 'MA0101', 'grupo': 2
        })
        self.assertEqual(sin_creditos['creditos_totales'], 0)
        self.assertIs(sin_sugerencia['cumple'], False)
        self.assertIsNone(sin_sugerencia['curso_a_quitar'])

    def test_archivo_vacio_es_json_valido(self):
        p = self.ejecutar(TESTS / 'fixtures' / 'combinaciones_vacias.json',
                          self.politica, self.salida)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(json.loads(self.salida.read_text(encoding='utf-8')),
                         {'resultados': []})

    def test_argumentos_incorrectos_da_error(self):
        p = self.ejecutar(self.entrada)
        self.assertEqual(p.returncode, 2)
        self.assertIn('Uso:', p.stderr)

    def test_politica_inexistente_da_error(self):
        p = self.ejecutar(self.entrada, self.root / 'no-existe.pl', self.salida)
        self.assertNotEqual(p.returncode, 0)


if __name__ == '__main__':
    unittest.main()
