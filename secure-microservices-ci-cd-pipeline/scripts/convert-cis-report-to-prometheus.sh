#!/bin/bash

# Usage: ./convert-cis-report-to-prometheus.sh path/to/cis-benchmark-report.json

REPORT_FILE="$1"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "❌ Report file not found: $REPORT_FILE"
  exit 1
fi

echo "# TYPE cis_benchmark_total gauge"
echo "# TYPE cis_benchmark_pass gauge"
echo "# TYPE cis_benchmark_fail gauge"
echo "# TYPE cis_benchmark_warn gauge"
echo "# TYPE cis_benchmark_info gauge"

TOTAL=$(jq '[.[] | .tests[] | .results[]] | length' "$REPORT_FILE")
PASS=$(jq '[.[] | .tests[] | .results[] | select(.status == "PASS")] | length' "$REPORT_FILE")
FAIL=$(jq '[.[] | .tests[] | .results[] | select(.status == "FAIL")] | length' "$REPORT_FILE")
WARN=$(jq '[.[] | .tests[] | .results[] | select(.status == "WARN")] | length' "$REPORT_FILE")
INFO=$(jq '[.[] | .tests[] | .results[] | select(.status == "INFO")] | length' "$REPORT_FILE")

echo "cis_benchmark_total ${TOTAL}"
echo "cis_benchmark_pass ${PASS}"
echo "cis_benchmark_fail ${FAIL}"
echo "cis_benchmark_warn ${WARN}"
echo "cis_benchmark_info ${INFO}"
