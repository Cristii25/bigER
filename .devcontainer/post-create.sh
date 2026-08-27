#!/usr/bin/env bash
set -euo pipefail

echo "==> Corrigiendo ownership de directorios montados como volumen..."
# Docker crea los directorios padre de los volúmenes montados como root antes
# de que arranque el contenedor, lo que deja /home/vscode/.cache y
# /home/vscode/.gradle sin permisos de escritura para el usuario vscode.
sudo mkdir -p /home/vscode/.cache /home/vscode/.gradle
sudo chown -R vscode:vscode /home/vscode/.cache /home/vscode/.gradle

echo "==> Habilitando yarn (via corepack)..."
corepack enable
corepack prepare yarn@1.22.22 --activate

echo "==> Instalando dependencias de sistema para Xvfb / Electron (tests de la extensión)..."
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  xvfb \
  libnss3 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libgtk-3-0 \
  libxss1 \
  libasound2 \
  libgbm1
sudo rm -rf /var/lib/apt/lists/*

echo "==> Construyendo language-server (Gradle/Xtext/Xtend)..."
chmod +x language-server/gradlew
language-server/gradlew -p language-server/ build

echo "==> Instalando dependencias de webview..."
yarn --cwd webview

echo "==> Instalando dependencias de extension..."
yarn --cwd extension

cat <<'EOF'

==> Listo.
Para depurar la extensión: abre este workspace en el devcontainer y pulsa F5
(o "Run > Start Debugging"), que lanzará el Extension Development Host.

Si necesitas correr los tests de la extensión de forma headless (sin ventana),
usa Xvfb como wrapper, p.ej.:
    xvfb-run -a yarn --cwd extension test
EOF
