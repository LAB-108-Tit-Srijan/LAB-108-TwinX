
Add-Type -AssemblyName System.Drawing

$inputPath = "assets\images\app_logo.png"
$outputPath = "assets\images\app_logo_small.png"

$img = [System.Drawing.Image]::FromFile($inputPath)

# Create a larger canvas with the logo centered (smaller)
$canvasSize = 1024
$logoSize = 900  # Smaller logo
$padding = ($canvasSize - $logoSize) / 2

$canvas = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.Clear([System.Drawing.Color]::White)

$destRect = New-Object System.Drawing.Rectangle($padding, $padding, $logoSize, $logoSize)
$graphics.DrawImage($img, $destRect)

$canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$canvas.Dispose()
$img.Dispose()

Write-Host "Created padded icon: $outputPath"
