# WordPress Core Update RCE — comprobación preliminar (PowerShell)

**Grupo Oruss · División 81 · 30 de octubre de 2026**

Herramienta gratuita de **consulta no intrusiva** para orientar la revisión de la vulnerabilidad de condición de carrera en las actualizaciones completas de WordPress Core. **No es un exploit RCE.**

Aviso oficial: [GHSA-4w3m-c66w-69mg](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-4w3m-c66w-69mg). La corrección principal se publicó en WordPress **7.1.4**, el **28 de octubre de 2026**, y cuenta con backports a ramas antiguas. [Comunicado de WordPress](https://wordpress.org/news/2026/10/wordpress-7-1-4/).

## Inicio rápido en Windows

1. Descarga `Test-WordPressUpdateSecurity.ps1` y revísalo antes de ejecutarlo.
2. Abre **Windows PowerShell** en la carpeta donde guardaste el archivo.
3. Ejecuta (sustituye la URL y la versión, consultada en **Escritorio → Actualizaciones**):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-WordPressUpdateSecurity.ps1 -Sitio "https://ejemplo.com" -Version "7.1.4"
```

También admite la ejecución sin `-Version`, pero si el sitio no publica la versión en su HTML, el resultado será **NO DETERMINADO**:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-WordPressUpdateSecurity.ps1 -Sitio "https://ejemplo.com"
```

`-ExecutionPolicy Bypass` se aplica únicamente al proceso invocado; **no cambia la política persistente del equipo**. Úsalo solo tras inspeccionar el archivo y obtenerlo de una fuente confiable. Compatible con **Windows PowerShell 5.1+**; no requiere Python, plugins ni credenciales.

> La URL debe ser la raíz de la instalación WordPress, incluido un subdirectorio si allí está instalado. Si WordPress usa una ruta de `wp-content` personalizada, la comprobación HTTP no se adapta automáticamente.

## Qué comprueba

- Realiza una solicitud GET ordinaria a la página principal.
- Compara la **versión proporcionada por el administrador**, o la que pueda verse públicamente en el elemento `meta generator`, con la versión parcheada de la misma rama publicada por WordPress.
- Consulta mediante GET `https://sitio/wp-content/upgrade/` e informa el código HTTP.
- No escribe archivos, no se autentica, no hace fuzzing ni utiliza payloads de explotación.

## Qué NO comprueba

- **HTTP 403 no demuestra** que todo el subárbol esté bloqueado: puede indicar únicamente que el listado de directorios está deshabilitado. HTTP 200/404 tampoco demuestra vulnerabilidad ni protección.
- El mensaje «versión igual o superior al parche» se basa en la versión indicada o publicada; **no valida que el binario del servidor sea auténtico ni la integridad de la instalación**.
- La exposición histórica durante una actualización, la posibilidad de ejecutar archivos PHP dentro de una ruta temporal y el compromiso previo requieren revisión administrativa, del servidor y de logs.
- El chequeo **no** debe usarse como certificado de seguridad o como sustituto de un pentest.

## Recomendaciones para administradores

1. Confirmar la versión instalada desde **Escritorio → Actualizaciones**. Actualizar a **7.1.4** o a una versión que incorpore el backport de seguridad correspondiente. En lo posible, migrar a una rama con soporte activo.
2. Crear y verificar una copia de seguridad antes de actualizar y comprobar el funcionamiento del sitio después.
3. Restringir el acceso **web** directo y la ejecución HTTP de PHP bajo `wp-content/upgrade/` cuando el proveedor lo soporte, **sin** quitar permisos internos de escritura que necesita WordPress.
4. Revisar registros del servidor/WAF alrededor de las actualizaciones, buscando accesos anómalos a `wp-content/upgrade/` y a instaladores temporales; investigar archivos PHP inesperados o cuentas administrativas desconocidas si hay indicios.
5. No considerar el WAF como sustituto del parcheo. Verificar también si el origen puede accederse sin pasar por el WAF.

## Fuentes

- [WordPress 7.1.4 — anuncio oficial](https://wordpress.org/news/2026/10/wordpress-7-1-4/)
- [GHSA-4w3m-c66w-69mg — matriz de versiones afectadas y corregidas](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-4w3m-c66w-69mg)

## Uso responsable

Ejecutar únicamente contra dominios propios o con autorización expresa. Mantener la frecuencia de comprobación baja. No incluye explotación, fuerza bruta ni pruebas intrusivas.

## Licencia

MIT. © 2026 Equipo Division81 Grupo Oruss.
