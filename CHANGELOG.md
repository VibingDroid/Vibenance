# Changelog

Todas las novedades notables de Vibenance se documentan en este archivo.

## [1.0.0] - 2026-10-29

### Lanzamiento inicial 1.0.0 (Google Play & GitHub Releases)
- Primera versión estable **1.0.0** (`1.0.0+1`) de **Vibenance** (`com.vibingdroid.vibenance`), cliente móvil moderno en Material 3 para Firefly III.
- **Soporte para Google Play Store:** nuevo flavor `play` para Android App Bundle (`.aab`) sin permisos de autoinstalación de paquetes (`REQUEST_INSTALL_PACKAGES`), manteniendo el actualizador in-app exclusivamente en las compilaciones directas (`stable` y `beta`).
- **Pantalla de Evolución financiera:** gráficos interactivos (`SfCartesianChart`) de Patrimonio Neto (activos menos pasivos con saldo en vivo del día actual), Saldo, Ingresos/Gastos y Categorías con selección por toque y desglose por cuentas.
- **Clasificador IA de transacciones:** integración opcional con servicio externo de categorización inteligente, vista de trabajos en curso y edición directa de transacciones.
- **Panel de Importación bancaria y Notificaciones Push (FCM):** consulta de estado, historial de ejecuciones, disparo manual y avisos push automáticos al finalizar importaciones.
- **Transacciones divididas (Splits) y filtros avanzados:** soporte completo para splits, filtro por rango de importes y exportación de movimientos a CSV.
- **Nuevo sistema de diseño:** paleta renovada con degradado de marca (`#00CED8` → `#4374F8` → `#8C38FF`), iconos adaptativos y desbloqueo biométrico con desenfoque.
