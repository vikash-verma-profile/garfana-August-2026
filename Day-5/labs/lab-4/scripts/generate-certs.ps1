# Generates a self-signed cert for local HTTPS labs (localhost).
# Requires OpenSSL in PATH (Git for Windows includes it).

$ErrorActionPreference = "Stop"
$certDir = Join-Path (Split-Path $PSScriptRoot -Parent) "certs"
New-Item -ItemType Directory -Force -Path $certDir | Out-Null

$key = Join-Path $certDir "privkey.pem"
$crt = Join-Path $certDir "fullchain.pem"

openssl req -x509 -nodes -newkey rsa:2048 -days 365 `
  -keyout $key -out $crt `
  -subj "/CN=localhost" `
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

Write-Host "Wrote $crt and $key"
