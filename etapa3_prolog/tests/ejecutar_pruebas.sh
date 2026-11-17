#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
swipl -q \
    -s etapa3_prolog/tests/test_reglas.pl \
    -s etapa3_prolog/tests/test_evaluador.pl \
    -s etapa3_prolog/tests/test_exportador.pl \
    -s etapa3_prolog/tests/test_integracion.pl \
    -g run_tests -t halt
