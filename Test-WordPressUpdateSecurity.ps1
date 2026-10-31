#requires -Version 5.1
<# PowerShell Tool creado por el equipo Division81 del Grupo Oruss 
.SYNOPSIS
    Comprobacion preliminar y no intrusiva del parche de WordPress Core (GHSA-4w3m-c66w-69mg).
.DESCRIPTION
    Evalua una version facilitada por el administrador (o publicada en el meta generator)
    contra las versiones corregidas anunciadas por WordPress el 28/10/2026.
    Consulta la pagina principal y /wp-content/upgrade/ con peticiones GET ordinarias.
    NO intenta explotar la RCE ni demuestra si el directorio permite ejecutar PHP.
.EXAMPLE
    .\Test-WordPressUpdateSecurity.ps1 -Sitio 'https://ejemplo.com' -Version '7.1.4'
.EXAMPLE
    .\Test-WordPressUpdateSecurity.ps1 -Sitio 'https://ejemplo.com'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://')]
    [string]$Sitio,

    [string]$Version,

    [ValidateRange(3,60)]
    [int]$Timeout = 15
)

$ErrorActionPreference = 'Stop'

# Parches por rama segun el aviso oficial de WordPress (29/10/2026).
$Parches = @{
    '7.1' = '7.1.4';   '7.0' = '7.0.8';   '6.9' = '6.9.11'
    '6.8' = '6.8.12'; '6.7' = '6.7.11'; '6.6' = '6.6.11'
    '6.5' = '6.5.14'; '6.4' = '6.4.14'; '6.3' = '6.3.14'
    '6.2' = '6.2.15'; '6.1' = '6.1.16'; '6.0' = '6.0.18'
    '5.9' = '5.9.20'; '5.8' = '5.8.19'; '5.7' = '5.7.21'
    '5.6' = '5.6.23'; '5.5' = '5.5.24'; '5.4' = '5.4.25'
    '5.3' = '5.3.27'; '5.2' = '5.2.30'; '5.1' = '5.1.28'
    '5.0' = '5.0.31'; '4.9' = '4.9.35'; '4.8' = '4.8.34'
    '4.7' = '4.7.39'
}

function Consultar-Url {
    param([string]$Direccion)
    try {
        $r = Invoke-WebRequest -Uri $Direccion -Method Get -UseBasicParsing `
            -MaximumRedirection 5 -TimeoutSec $Timeout -Headers @{'User-Agent'='GrupoOruss-WP-Check/1.0'}
        return [pscustomobject]@{ Codigo = [int]$r.StatusCode; Cuerpo = [string]$r.Content; Error = '' }
    } catch {
        if ($_.Exception.Response) {
            return [pscustomobject]@{ Codigo = [int]$_.Exception.Response.StatusCode; Cuerpo = ''; Error = '' }
        }
        return [pscustomobject]@{ Codigo = $null; Cuerpo = ''; Error = $_.Exception.Message }
    }
}

try {
    $url = [uri]$Sitio
    if ($url.Scheme -ne 'https' -or -not $url.Host -or $url.UserInfo) {
        throw 'Indique una URL HTTPS valida, sin credenciales.'
    }
} catch {
    throw 'Sitio invalido. Ejemplo: -Sitio https://ejemplo.com'
}

$base = $Sitio.TrimEnd('/')
Write-Host "`nGRUPO ORUSS | WordPress Core - revision preliminar" -ForegroundColor Cyan
Write-Host ('Sitio: ' + $base)

$principal = Consultar-Url -Direccion ($base + '/')
$carpeta   = Consultar-Url -Direccion ($base + '/wp-content/upgrade/')

$fuente = 'Administrador (parametro -Version)'
if ([string]::IsNullOrWhiteSpace($Version)) {
    $fuente = 'No detectable externamente'
    if ($principal.Cuerpo) {
        foreach ($etiqueta in [regex]::Matches($principal.Cuerpo, '<meta\b[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            if ($etiqueta.Value -match '(?i)generator' -and
                $etiqueta.Value -match '(?i)WordPress\s+(?<v>\d+\.\d+(?:\.\d+)?)') {
                $Version = $Matches['v']
                $fuente = 'Etiqueta meta publica (no concluyente)'
                break
            }
        }
    }
}

$estado = 'NO DETERMINADO: confirme version en Escritorio > Actualizaciones.'
$parche = 'N/D'
if ($Version) {
    if ($Version -notmatch '^\d+\.\d+(?:\.\d+)?$') {
        throw 'Version invalida. Ejemplo: -Version 7.1.4'
    }
    $partes = $Version.Split('.')
    $rama = $partes[0] + '.' + $partes[1]
    if ($Parches.ContainsKey($rama)) {
        $parche = $Parches[$rama]
        if ([version]$Version -ge [version]$parche) {
            $estado = 'VERSION IGUAL O SUPERIOR AL PARCHE DE ESTA RAMA'
        } else {
            $estado = 'VERSION ANTERIOR AL PARCHE: PRIORICE ACTUALIZACION'
        }
    } else {
        $estado = 'RAMA FUERA DE LA MATRIZ: VERIFICAR CON WORDPRESS'
    }
}

$versionMostrar = if ($Version) { $Version } else { 'No detectada' }
$httpPrincipal = if ($null -ne $principal.Codigo) { $principal.Codigo } else { 'Error: ' + $principal.Error }
$httpCarpeta = if ($null -ne $carpeta.Codigo) { $carpeta.Codigo } else { 'Error: ' + $carpeta.Error }

Write-Host ('Pagina principal: HTTP ' + $httpPrincipal)
Write-Host ('Version: ' + $versionMostrar + ' | Fuente: ' + $fuente)
Write-Host ('Version corregida en esa rama: ' + $parche)
Write-Host ('Evaluacion: ' + $estado) -ForegroundColor Yellow
Write-Host ('/wp-content/upgrade/: HTTP ' + $httpCarpeta)
Write-Host 'IMPORTANTE: HTTP 200, 403 o 404 en el directorio NO permite concluir si existe ejecucion PHP.'
Write-Host 'Una version publica puede estar oculta o desactualizada; confirme siempre desde el administrador.'
Write-Host 'Este script no explota la vulnerabilidad, no certifica ausencia de compromiso y no modifica el sitio.'
Write-Host 'Referencia: https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-4w3m-c66w-69mg'
