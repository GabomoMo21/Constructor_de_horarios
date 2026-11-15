#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
swipl -q -s etapa3_prolog/tests/test_exportador.pl -g run_tests -t halt
