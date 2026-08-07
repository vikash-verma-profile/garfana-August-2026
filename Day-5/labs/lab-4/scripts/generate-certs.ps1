# Generates a self-signed cert for local HTTPS labs (localhost).
# Uses OpenSSL in PATH when available; otherwise falls back to Docker (alpine/openssl).

$ErrorActionPreference = "Stop"
$certDir = Join-Path (Split-Path $PSScriptRoot -Parent) "certs"
New-Item -ItemType Directory -Force -Path $certDir | Out-Null

$key = Join-Path $certDir "privkey.pem"
$crt = Join-Path $certDir "fullchain.pem"

$opensslArgs = @(
  "req", "-x509", "-nodes", "-newkey", "rsa:2048", "-days", "365",
  "-keyout", $key, "-out", $crt,
  "-subj", "/CN=localhost",
  "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1"
)

$openssl = Get-Command openssl -ErrorAction SilentlyContinue
if ($openssl) {
  & openssl @opensslArgs
} else {
  Write-Host "openssl not found in PATH; using Docker alpine/openssl"
  docker run --rm -v "${certDir}:/certs" alpine/openssl req -x509 -nodes -newkey rsa:2048 -days 365 `
    -keyout /certs/privkey.pem -out /certs/fullchain.pem `
    -subj "/CN=localhost" `
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
  if ($LASTEXITCODE -ne 0) { throw "Failed to generate certs via Docker" }
}

Write-Host "Wrote $crt and $key"
