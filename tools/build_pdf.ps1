# Render the built HTML to PDF using headless Edge.
#
#   powershell -File tools/build_pdf.ps1
#
# Run tools/build_html.py first. The print stylesheet lives in build_html.py,
# inside the @media print block.

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$html = Join-Path $root "build\git-by-example.html"
$pdf  = Join-Path $root "build\git-by-example.pdf"

if (-not (Test-Path $html)) {
    throw "No HTML build found. Run: python tools/build_html.py"
}

$edge = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edge) { throw "No Edge or Chrome found to render the PDF." }

# A dedicated profile directory matters: without it, a browser that is already
# running takes over the request and the headless process exits before printing.
$profile = Join-Path $env:TEMP "git-by-example-pdf-profile"

if (Test-Path $pdf) { Remove-Item $pdf -Force }

# #print-all makes the page open every collapsed question list before printing.
$uri = "file:///" + ($html -replace '\\', '/') + "#print-all"
$browserArgs = @(
    "--headless=new"
    "--disable-gpu"
    "--user-data-dir=$profile"
    "--no-pdf-header-footer"
    # Bookmarks built from the heading levels: part, chapter, section, subsection.
    "--generate-pdf-document-outline"
    "--print-to-pdf=$pdf"
    $uri
)

Start-Process -FilePath $edge -ArgumentList $browserArgs -Wait -NoNewWindow

if (Test-Path $pdf) {
    "{0}  {1:N0} KB" -f $pdf, ((Get-Item $pdf).Length / 1KB)
} else {
    throw "The browser exited without writing a PDF."
}
