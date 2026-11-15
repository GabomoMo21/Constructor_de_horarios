"""Contrato de datos independientes del entorno SWI-Prolog."""
import json
import unittest
from pathlib import Path

FIXTURES = Path(__file__).resolve().parent / 'fixtures'


class FormatoEntrada(unittest.TestCase):
    def test_ejemplo_acepta_multicarrera_y_campos_exigidos(self):
        data = json.loads((FIXTURES / 'combinaciones_ejemplo.json').read_text(encoding='utf-8'))
        self.assertEqual(len(data['combinaciones']), 4)
        for combinacion in data['combinaciones']:
            total = 0
            for curso in combinacion['selecciones']:
                self.assertEqual(set(curso), {'carrera', 'codigo', 'grupo',
                                               'creditos', 'area'})
                self.assertGreater(curso['grupo'], 0)
                self.assertGreaterEqual(curso['creditos'], 0)
                total += curso['creditos']
            self.assertEqual(total, combinacion['creditos_totales'])
        carreras = {c['carrera'] for c in data['combinaciones'][0]['selecciones']}
        self.assertEqual(len(carreras), 2)

    def test_cero_combinaciones(self):
        self.assertEqual(json.loads((FIXTURES / 'combinaciones_vacias.json').read_text())['combinaciones'], [])


if __name__ == '__main__':
    unittest.main()
