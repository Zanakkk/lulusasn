# optimize-build.ps1 - Optimized Flutter Web Build

Write-Host "=== LulusASN Optimized Build ===" -ForegroundColor Green

# Step 1: TOTAL CLEAN
Write-Host "`n[1/6] Deep cleaning..." -ForegroundColor Yellow
flutter clean
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   Clean complete" -ForegroundColor Green

# Step 2: Cache repair
Write-Host "`n[2/6] Repairing cache..." -ForegroundColor Yellow
flutter pub cache repair
Write-Host "   Cache repaired" -ForegroundColor Green

# Step 3: Get dependencies
Write-Host "`n[3/6] Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "   Dependencies fetched" -ForegroundColor Green

# Step 4: Optimized build
Write-Host "`n[4/6] Building (optimized)..." -ForegroundColor Yellow
Write-Host "   This may take 20-40 seconds..." -ForegroundColor Gray

flutter build web `
  --release `
  --tree-shake-icons `
  --no-source-maps `
  --dart-define=FLUTTER_WEB_USE_SKIA=false `
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/a57a36c59a67e50dcb1f48c1d7dcfd0a8e656bc8/

Write-Host "   Build complete" -ForegroundColor Green

# Step 5: Analyze
Write-Host "`n[5/6] Analyzing build..." -ForegroundColor Yellow

$mainJs = Get-Item "build/web/main.dart.js" -ErrorAction SilentlyContinue
if ($mainJs) {
    $sizeKB = [math]::Round($mainJs.Length / 1KB, 1)
    $color = if ($sizeKB -lt 500) { "Green" } elseif ($sizeKB -lt 1000) { "Yellow" } else { "Red" }
    Write-Host "   main.dart.js: $sizeKB KB" -ForegroundColor $color

    if ($sizeKB -gt 1000) {
        Write-Host "   WARNING: File too large! Should be <500 KB" -ForegroundColor Red
    }
}

# Check for canvaskit
$canvaskit = Get-ChildItem "build/web/canvaskit" -ErrorAction SilentlyContinue -File
if ($canvaskit) {
    $totalWasm = ($canvaskit | Where-Object { $_.Extension -eq ".wasm" } | Measure-Object -Property Length -Sum).Sum
    $wasmMB = [math]::Round($totalWasm / 1MB, 2)
    Write-Host "   CanvasKit WASM: $wasmMB MB" -ForegroundColor Cyan

    if ($wasmMB -gt 2) {
        Write-Host "   WARNING: CanvasKit too large! Should be ~1.5 MB" -ForegroundColor Red
    }
}

# Total size
$total = (Get-ChildItem "build/web" -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalMB = [math]::Round($total / 1MB, 2)
$color = if ($totalMB -lt 4) { "Green" } elseif ($totalMB -lt 6) { "Yellow" } else { "Red" }
Write-Host "   Total size: $totalMB MB" -ForegroundColor $color

if ($totalMB -gt 5) {
    Write-Host "   WARNING: Build too large! Should be 3-4 MB" -ForegroundColor Red
}

# Step 6: Copy static files
Write-Host "`n[6/6] Copying static files..." -ForegroundColor Yellow
"User-agent: *`nAllow: /`nSitemap: https://lulusasn-e15a3.web.app/sitemap.xml" | Out-File "build/web/robots.txt" -Encoding utf8
Write-Host "   robots.txt created" -ForegroundColor Green

# Summary
Write-Host "`n=== Build Summary ===" -ForegroundColor Cyan
Write-Host "Total size: $totalMB MB" -ForegroundColor Cyan
Write-Host "main.dart.js: $([math]::Round((Get-Item 'build/web/main.dart.js').Length / 1KB, 1)) KB" -ForegroundColor Cyan

# Top 5 largest files
Write-Host "`nTop 5 largest files:" -ForegroundColor Cyan
Get-ChildItem "build/web" -Recurse -File |
    Sort-Object Length -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 1)
        Write-Host "  $($_.Name): $size KB"
    }

# Recommendations
Write-Host "`n=== Recommendations ===" -ForegroundColor Magenta
if ($totalMB -gt 5) {
    Write-Host "Build is too large! Check:" -ForegroundColor Red
    Write-Host "1. Remove unused packages from pubspec.yaml" -ForegroundColor Yellow
    Write-Host "2. Check for large assets (images, fonts)" -ForegroundColor Yellow
    Write-Host "3. Use 'flutter build web --analyze-size' for details" -ForegroundColor Yellow
} else {
    Write-Host "Build size is acceptable!" -ForegroundColor Green
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Test locally: cd build\web && python -m http.server 8000"
Write-Host "2. Deploy: firebase deploy --only hosting"
Write-Host "3. Test PageSpeed: https://pagespeed.web.dev/`n"