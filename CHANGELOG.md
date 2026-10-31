# Changelog

Todas las novedades notables de Vibenance se documentan en este archivo.

## [1.0.3] - 2026-10-31

### Added
- Logotipos oficiales SVG de bancos descargados de Brandfetch e integrados en cuentas, pantalla de inicio y evolución (patrimonio y saldo).

## [1.0.2] - 2026-10-30

### Nuevas características
- **Insignias y colores corporativos de bancos:** soporte para más de 20 bancos y neobancos que operan en España (BBVA, Santander, CaixaBank, ING, Sabadell, Bankinter, Revolut, Openbank, N26, MyInvestor, Trade Republic, etc.) con sus colores oficiales y siglas.
- **Detección inteligente de entidad:** identificación prioritaria por los 4 dígitos de entidad del código IBAN español (`ESxxEEEE...`), con fallback automático por palabras clave en el nombre de la cuenta cuando el IBAN no esté presente o sea extranjero.
- **Exportación CSV unificada:** la columna "Entidad" en la exportación de transacciones reutiliza la misma lógica de detección que las insignias visuales.

## [1.0.1] - 2026-10-30

### Correcciones
- **Icono adaptativo con degradado:** el icono de la app en Android 8+ ahora muestra correctamente el degradado oficial de marca (`#00CED8` → `#4374F8` → `#8C38FF`) en lugar de un fondo oscuro sólido.
- **Capturas de Play Store actualizadas:** se reemplazaron las capturas heredadas de Waterfly III por capturas reales de Vibance (Movimientos, Análisis y Evolución).
- **Feature Graphic renovado:** nuevo banner 1024×500 con isotipo, tipografía Outfit, mockups de las pantallas reales y paleta de marca sobre fondo Material 3.
- **Pipeline de publicación automática en Google Play:** el workflow de GitHub Actions ahora sube el `.aab` directamente a Google Play Store (canal detectado automáticamente).

## [1.0.0] - 2026-10-29

### Lanzamiento inicial 1.0.0 (Google Play & GitHub Releases)
- Primera versión estable **1.0.0** (`1.0.0+1`) de **Vibance** (`com.vibingdroid.vibance`), cliente móvil moderno en Material 3 para Firefly III.
- **Soporte para Google Play Store:** nuevo flavor `play` para Android App Bundle (`.aab`) sin permisos de autoinstalación de paquetes (`REQUEST_INSTALL_PACKAGES`), manteniendo el actualizador in-app exclusivamente en las compilaciones directas (`stable` y `beta`).
- **Pantalla de Evolución financiera:** gráficos interactivos (`SfCartesianChart`) de Patrimonio Neto (activos menos pasivos con saldo en vivo del día actual), Saldo, Ingresos/Gastos y Categorías con selección por toque y desglose por cuentas.
- **Clasificador IA de transacciones:** integración opcional con servicio externo de categorización inteligente, vista de trabajos en curso y edición directa de transacciones.
- **Panel de Importación bancaria y Notificaciones Push (FCM):** consulta de estado, historial de ejecuciones, disparo manual y avisos push automáticos al finalizar importaciones.
- **Transacciones divididas (Splits) y filtros avanzados:** soporte completo para splits, filtro por rango de importes y exportación de movimientos a CSV.
- **Nuevo sistema de diseño:** paleta renovada con degradado de marca (`#00CED8` → `#4374F8` → `#8C38FF`), iconos adaptativos y desbloqueo biométrico con desenfoque.
