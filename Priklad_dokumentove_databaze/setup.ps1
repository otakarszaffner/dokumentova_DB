# Obed Order System - Setup Script (Windows PowerShell)
# Bez specialnich znaku

param(
    [string]$CouchDBUrl = "http://localhost:5984",
    [string]$DbName = "lunch_orders",
    [string]$User = "admin",
    [string]$Password = "password"
)

$colors = @{
    Success = "Green"
    Error   = "Red"
    Info    = "Cyan"
    Warning = "Yellow"
}

function Write-Header {
    param([string]$Text)
    Write-Host "`n" + ("=" * 70) -ForegroundColor $colors.Info
    Write-Host "  $Text" -ForegroundColor $colors.Info
    Write-Host ("=" * 70) -ForegroundColor $colors.Info
    Write-Host ""
}

function New-BasicAuthHeader {
    param([string]$Username, [string]$Password)
    $auth = "$($Username):$($Password)"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($auth))
    return @{ Authorization = "Basic $encoded" }
}

function Invoke-CouchDBRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body
    )
    
    $headers = New-BasicAuthHeader $User $Password
    $uri = "$CouchDBUrl$Endpoint"
    
    $params = @{
        Uri     = $uri
        Method  = $Method
        Headers = $headers
        UseBasicParsing = $true
    }
    
    if ($Body) {
        $params["Body"] = $Body
        $params["ContentType"] = "application/json"
    }
    
    try {
        $response = Invoke-WebRequest @params
        return $response
    }
    catch {
        Write-Host "CHYBA: $($_.Exception.Message)" -ForegroundColor $colors.Error
        return $null
    }
}

# SETUP
Write-Header "Obedy - Setup"

# 1. Overeni pripojeni
Write-Host "Overuju pripojeni k CouchDB..." -ForegroundColor $colors.Info
try {
    $response = Invoke-WebRequest -Uri $CouchDBUrl -ErrorAction Stop -UseBasicParsing
    Write-Host "OK: Pripojeno k CouchDB`n" -ForegroundColor $colors.Success
}
catch {
    Write-Host "CHYBA: Nelze se pripojit k CouchDB!" -ForegroundColor $colors.Error
    Write-Host "  Je docker up?" -ForegroundColor $colors.Warning
    exit 1
}

# 2. Smazani stare databaze
Write-Host "Mazu starou databazi (pokud existuje)..." -ForegroundColor $colors.Info
$response = Invoke-CouchDBRequest -Method DELETE -Endpoint "/$DbName"
Write-Host "OK`n" -ForegroundColor $colors.Success

# 3. Vytvoreni nove databaze
Write-Header "KROK 1: Vytvoreni Databaze"
Write-Host "Vytvarim databazi $DbName..." -ForegroundColor $colors.Info

$response = Invoke-CouchDBRequest -Method PUT -Endpoint "/$DbName"
if ($response.StatusCode -eq 201) {
    Write-Host "OK: Databaze vytvorena`n" -ForegroundColor $colors.Success
}
else {
    Write-Host "CHYBA: Chyba pri vytvoreni databaze" -ForegroundColor $colors.Error
    exit 1
}

# 4. Import dat
Write-Header "KROK 2: Import Dat"

$dataFile = "$PSScriptRoot\data.json"
if (-not (Test-Path $dataFile)) {
    Write-Host "CHYBA: Soubor $dataFile nebyl nalezen!" -ForegroundColor $colors.Error
    exit 1
}

Write-Host "Cteni data z: $dataFile" -ForegroundColor $colors.Info
$jsonData = Get-Content $dataFile -Raw -Encoding UTF8

Write-Host "Importuji dokumenty..." -ForegroundColor $colors.Info

$headers = New-BasicAuthHeader $User $Password
$headers["Content-Type"] = "application/json; charset=utf-8"
$uri = "$CouchDBUrl/$DbName/_bulk_docs"

try {
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $jsonData -ContentType "application/json; charset=utf-8" -UseBasicParsing
}
catch {
    Write-Host "CHYBA: $($_.Exception.Message)" -ForegroundColor $colors.Error
    exit 1
}

# Nepotřebujeme volat Invoke-CouchDBRequest, už máme response

if ($response.StatusCode -eq 201) {
    $result = $response.Content | ConvertFrom-Json
    Write-Host "OK: Import uspesny`n" -ForegroundColor $colors.Success
    
    $successCount = ($result | Where-Object { $_.ok -eq $true } | Measure-Object).Count
    Write-Host "   Importovano: $successCount dokumentu`n" -ForegroundColor $colors.Info
}
else {
    Write-Host "CHYBA: Chyba pri importu dat" -ForegroundColor $colors.Error
    exit 1
}

# 5. Overeni dat
Write-Header "KROK 3: Overeni Dat"

Write-Host "Kontroluji pocet dokumentu..." -ForegroundColor $colors.Info
$response = Invoke-CouchDBRequest -Method GET -Endpoint "/$DbName"
$dbInfo = $response.Content | ConvertFrom-Json

Write-Host "OK: Databaze je pripravena!" -ForegroundColor $colors.Success
Write-Host "   Databaze: $DbName" -ForegroundColor $colors.Info
Write-Host "   Pocet dokumentu: $($dbInfo.doc_count)" -ForegroundColor $colors.Info

Write-Header "Setup Uspesne Dokoncen!"

Write-Host "Dalsi kroky:" -ForegroundColor $colors.Info
Write-Host "  1. Adresa:" -ForegroundColor $colors.Info
Write-Host "     http://localhost:5984/_utils/" -ForegroundColor $colors.Success
Write-Host ""
Write-Host "  2. Prihlaseni:" -ForegroundColor $colors.Info
Write-Host "     Jmeno: admin" -ForegroundColor $colors.Success
Write-Host "     Heslo: password" -ForegroundColor $colors.Success
Write-Host ""
Write-Host "  3. Databaze: lunch_orders" -ForegroundColor $colors.Info
Write-Host ""
