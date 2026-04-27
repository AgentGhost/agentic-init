# Start Docker Desktop if not running
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (!(Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting Docker Desktop..."
    Start-Process $dockerPath
    Write-Host "Waiting for Docker to start..."
    Start-Sleep -Seconds 15
}

# Run docker-compose
Set-Location $PSScriptRoot
docker-compose up -d
docker ps