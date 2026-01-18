# force-production-build.ps1 - Force Clean Production Build

Write-Host "=== Forcing Production Build ===" -ForegroundColor Red
Write-Host "Fixing Flutter 3.38.6 build bug...`n" -ForegroundColor Yellow

# STEP 1: Nuclear clean
Write-Host "[1/7] Nuclear cleaning..." -ForegroundColor Yellow
flutter clean
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "pubspec.lock" -Force -ErrorAction SilentlyContinue
Write-Host "   Done`n" -ForegroundColor Green

# STEP 2: Clear Flutter cache
Write-Host "[2/7] Clearing Flutter cache..." -ForegroundColor Yellow
flutter pub cache clean
flutter pub cache repair
Write-Host "   Done`n" -ForegroundColor Green

# STEP 3: Fresh dependencies
Write-Host "[3/7] Getting fresh dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "   Done`n" -ForegroundColor Green

# STEP 4: Build with STRICT flags
Write-Host "[4/7] Building with STRICT production flags..." -ForegroundColor Yellow
Write-Host "   This will take 30-60 seconds...`n" -ForegroundColor Gray

# Use environment variables to force production
$env:FLUTTER_WEB_USE_SKIA = "false"
$env:FLUTTER_BUILD_MODE = "release"

flutter build web `
  --release `
  --tree-shake-icons `
  --no-source-maps `
  --web-renderer canvaskit 2>$null

# Check if command failed (older Flutter doesn't support --web-renderer)
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Retrying without --web-renderer flag..." -ForegroundColor Yellow
    flutter build web `
      --release `
      --tree-shake-icons `
      --no-source-maps
}

Write-Host "   Build complete`n" -ForegroundColor Green

# STEP 5: CRITICAL - Remove development artifacts
Write-Host "[5/7] Removing development artifacts..." -ForegroundColor Yellow

$removed = 0

# Remove skwasm variants (development only)
Get-ChildItem "build/web/canvaskit" -Filter "skwasm*" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "   Removed: $($_.Name)" -ForegroundColor Red
    $removed++
}

# Remove .symbols files (debug symbols)
Get-ChildItem "build/web" -Recurse -Filter "*.symbols" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "   Removed: $($_.Name)" -ForegroundColor Red
    $removed++
}

# Remove duplicate canvaskit (keep smallest)
$canvaskitFiles = Get-ChildItem "build/web/canvaskit" -Filter "canvaskit.wasm" -ErrorAction SilentlyContinue
if ($canvaskitFiles.Count -gt 1) {
    $canvaskitFiles | Sort-Object Length -Descending | Select-Object -Skip 1 | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "   Removed duplicate: $($_.Name)" -ForegroundColor Red
        $removed++
    }
}

Write-Host "   Removed $removed development files`n" -ForegroundColor Green

# STEP 6: Analyze final build
Write-Host "[6/7] Analyzing final build..." -ForegroundColor Yellow

$mainJs = Get-Item "build/web/main.dart.js" -ErrorAction SilentlyContinue
if ($mainJs) {
    $sizeKB = [math]::Round($mainJs.Length / 1KB, 1)
    
    if ($sizeKB -lt 600) {
        Write-Host "   main.dart.js: $sizeKB KB" -ForegroundColor Green -NoNewline
        Write-Host " ✓ GOOD" -ForegroundColor Green
    } elseif ($sizeKB -lt 1000) {
        Write-Host "   main.dart.js: $sizeKB KB" -ForegroundColor Yellow -NoNewline
        Write-Host " ⚠ OK but could be better" -ForegroundColor Yellow
    } else {
        Write-Host "   main.dart.js: $sizeKB KB" -ForegroundColor Red -NoNewline
        Write-Host " ✗ TOO LARGE!" -ForegroundColor Red
    }
}

# Check canvaskit
$canvaskitWasm = Get-ChildItem "build/web/canvaskit/*.wasm" -ErrorAction SilentlyContinue
if ($canvaskitWasm) {
    $totalWasmMB = [math]::Round(($canvaskitWasm | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    
    if ($totalWasmMB -lt 2) {
        Write-Host "   CanvasKit: $totalWasmMB MB" -ForegroundColor Green -NoNewline
        Write-Host " ✓ GOOD" -ForegroundColor Green
    } else {
        Write-Host "   CanvasKit: $totalWasmMB MB" -ForegroundColor Red -NoNewline
        Write-Host " ✗ TOO LARGE!" -ForegroundColor Red
    }
    
    # List all WASM files
    Write-Host "   WASM files found:" -ForegroundColor Cyan
    $canvaskitWasm | ForEach-Object {
        $mb = [math]::Round($_.Length / 1MB, 2)
        Write-Host "     - $($_.Name): $mb MB" -ForegroundColor Gray
    }
}

# Total size
$total = (Get-ChildItem "build/web" -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalMB = [math]::Round($total / 1MB, 2)

if ($totalMB -lt 4) {
    Write-Host "   Total: $totalMB MB" -ForegroundColor Green -NoNewline
    Write-Host " ✓ EXCELLENT!" -ForegroundColor Green
} elseif ($totalMB -lt 6) {
    Write-Host "   Total: $totalMB MB" -ForegroundColor Yellow -NoNewline
    Write-Host " ⚠ OK" -ForegroundColor Yellow
} else {
    Write-Host "   Total: $totalMB MB" -ForegroundColor Red -NoNewline
    Write-Host " ✗ TOO LARGE!" -ForegroundColor Red
}

Write-Host ""

# STEP 7: Create robots.txt
Write-Host "[7/7] Creating static files..." -ForegroundColor Yellow
"User-agent: *`nAllow: /`nSitemap: https://lulusasn-e15a3.web.app/sitemap.xml" | Out-File "build/web/robots.txt" -Encoding utf8
Write-Host "   robots.txt created`n" -ForegroundColor Green

# Final summary
Write-Host "=== Final Summary ===" -ForegroundColor Cyan
Write-Host "Build size: $totalMB MB" -ForegroundColor Cyan
Write-Host "Files removed: $removed development artifacts`n" -ForegroundColor Cyan

# Top 10 largest files
Write-Host "Top 10 largest files:" -ForegroundColor Cyan
Get-ChildItem "build/web" -Recurse -File | 
    Sort-Object Length -Descending | 
    Select-Object -First 10 | 
    ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 1)
        $relativePath = $_.FullName -replace [regex]::Escape("$PWD\build\web\"), ""
        Write-Host "  $relativePath - $size KB"
    }

# Health check
Write-Host "`n=== Health Check ===" -ForegroundColor Magenta
$issues = 0

if ($mainJs.Length -gt 1MB) {
    Write-Host "✗ main.dart.js is too large" -ForegroundColor Red
    $issues++
}

if ($totalWasmMB -gt 2) {
    Write-Host "✗ CanvasKit WASM is too large" -ForegroundColor Red
    $issues++
}

if ($totalMB -gt 5) {
    Write-Host "✗ Total build size is too large" -ForegroundColor Red
    $issues++
}

$symbolsLeft = Get-ChildItem "build/web" -Recurse -Filter "*.symbols" -ErrorAction SilentlyContinue
if ($symbolsLeft) {
    Write-Host "✗ Debug symbols still present" -ForegroundColor Red
    $issues++
}

$skwasmLeft = Get-ChildItem "build/web/canvaskit" -Filter "skwasm*" -ErrorAction SilentlyContinue
if ($skwasmLeft) {
    Write-Host "✗ Skwasm variants still present (should only have canvaskit)" -ForegroundColor Red
    $issues++
}

if ($issues -eq 0) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
} else {
    Write-Host "`n$issues issues found!" -ForegroundColor Red
    Write-Host "If issues persist, you may need to:" -ForegroundColor Yellow
    Write-Host "1. Update Flutter: flutter upgrade" -ForegroundColor Yellow
    Write-Host "2. Check pubspec.yaml for heavy packages" -ForegroundColor Yellow
    Write-Host "3. Use: flutter build web --analyze-size" -ForegroundColor Yellow
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Test locally: cd build\web && python -m http.server 8000"
Write-Host "2. Deploy: firebase deploy --only hosting"
Write-Host "3. Hard refresh browser: Ctrl+Shift+R"
Write-Host "4. Test PageSpeed: https://pagespeed.web.dev/`n"