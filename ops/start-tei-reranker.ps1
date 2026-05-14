# Start Docker Desktop if not running
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (!(Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting Docker Desktop..."
    Start-Process $dockerPath
    Write-Host "Waiting for Docker to start..."
    Start-Sleep -Seconds 15
}

# Start TEI reranker
Set-Location $PSScriptRoot
Write-Host "Starting TEI reranker (Xenova/bge-reranker-base)..."
docker compose up -d tei-reranker

# Wait for health check
Write-Host "Waiting for TEI to be ready..."
do {
    Start-Sleep -Seconds 5
    $health = curl -s http://localhost:8080/health
} while (-not $health)

Write-Host "TEI reranker is ready on http://localhost:8080"
