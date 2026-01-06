#!/bin/bash
IMAGE=$1
echo "[Trivy] Scanning $IMAGE"
trivy image --exit-code 1 --severity CRITICAL,HIGH --format table $IMAGE
