#!/usr/bin/env bash
set -e

if [ -f package.json ]; then
  npm install
fi

if [ -d backend ] && [ -f backend/package.json ]; then
  npm --prefix backend install
fi

if [ -d frontend ] && [ -f frontend/package.json ]; then
  npm --prefix frontend install
fi

if command -v npx >/dev/null 2>&1; then
  npx prisma generate 2>/dev/null || true
fi

printf '\nAmbiente preparado.\n'
printf 'Documentação de stack: md/documentation/stacks/03-TECHNICAL-DESIGN.md\n'
