# Sistema de Diseño Vibenance

## Identidad de marca

Vibenance es un cliente móvil personal de finanzas para Firefly III. La identidad visual transmite **claridad, control y modernidad** mediante una paleta luminosa, neutros refinados y una semántica de color que guía al usuario en sus flujos de dinero.

### Isotipo

El isotipo consiste en un **círculo con degradado diagonal** que fluye de cian (`#00CED8`) a azul central (`#4374F8`) y termina en violeta (`#8C38FF`). Sobre ese fondo se disponen **tres barras verticales redondeadas en blanco** que representan la evolución y el ritmo de la actividad financiera.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">
  <defs>
    <linearGradient id="bg-gradient" x1="12%" y1="12%" x2="88%" y2="88%">
      <stop offset="0%" stop-color="#00CED8" />
      <stop offset="50%" stop-color="#4374F8" />
      <stop offset="100%" stop-color="#8C38FF" />
    </linearGradient>
  </defs>
  <circle cx="500" cy="500" r="500" fill="url(#bg-gradient)" />
  <g fill="#FFFFFF">
    <rect x="212" y="383.5" width="127" height="233" rx="63.5" />
    <rect x="403" y="299" width="127" height="402" rx="63.5" />
    <rect x="593.5" y="214" width="127" height="572" rx="63.5" />
  </g>
</svg>
```

| Elemento | Valor |
|----------|-------|
| Círculo degradado | `#00CED8` → `#4374F8` → `#8C38FF` |
| Barras | `#FFFFFF`, `rx=63.5` |
| Barra izquierda | `x=212`, `y=383.5`, `w=127`, `h=233` |
| Barra central | `x=403`, `y=299`, `w=127`, `h=402` |
| Barra derecha | `x=593.5`, `y=214`, `w=127`, `h=572` |

### Tipografía

La interfaz se construye sobre **Outfit** (Google Fonts) con una escala Material 3 y pesos que van de 500 a 700 para jerarquías de títulos, cuerpo y datos numéricos.

## Arquitectura de color semántica

La paleta se organiza en capas: **marca**, **neutros**, **flujos de dinero** y **capas de producto**. Cada color semántico cuenta con versión clara y oscura cuando el contexto lo requiere.

### Marca / primario

| Token | Valor | Uso |
|-------|-------|-----|
| `primary` | `#4374F8` | Botones, acentos, indicadores de selección |
| `primaryCyan` | `#00CED8` | Inicio del degradado de marca |
| `primaryViolet` | `#8C38FF` | Final del degradado de marca |
| `blueLight` | `#6AA6FF` | Énfasis luminoso en modo oscuro |

El degradado de marca se usa en el isotipo, splash y momentos de branding.

### Neutros (modo claro)

| Token | Valor | Uso |
|-------|-------|-----|
| `bg` | `#F8FAFC` | Fondo de pantalla |
| `surface` | `#FFFFFF` | Tarjetas, bottom sheet, diálogos |
| `sectionHeader` | `#F1F5F9` | Cabeceras de sección, chips de fondo |
| `border` | `#E2E8F0` | Bordes de tarjetas y divisores |
| `textPrimary` | `#0F172A` | Texto principal y títulos |
| `textMuted` | `#64748B` | Texto secundario, hints, iconos inactivos |

### Neutros (modo oscuro)

| Token | Valor | Uso |
|-------|-------|-----|
| `bgDark` | `#090D16` | Fondo de pantalla |
| `surfaceDark` | `#151D2A` | Tarjetas y superficies elevadas |
| `sectionHeaderDark` | `#1E293B` | Cabeceras de sección en modo oscuro |
| `borderDark` | `#243044` | Bordes y divisores en modo oscuro |
| `textPrimaryDark` | `#F8FAFC` | Texto principal en modo oscuro |
| `textMutedDark` | `#94A3B8` | Texto secundario en modo oscuro |

### Flujos de dinero

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `income` / `incomeDark` | `#047857` | `#10B981` | Ingresos, depósitos, saldo positivo |
| `expense` / `expenseDark` | `#BE123C` | `#F43F5E` | Gastos, retiradas, saldo negativo |
| `transfer` / `transferDark` | `#475569` | `#64748B` | Transferencias internas |

Se mantienen los alias retrocompatibles:

- `coral` → `expense`
- `coralDark` → `expense`
- `coralLight` → `expenseDark`
- `incomeLight` ha sido reemplazado por `incomeDark` (el viejo alias sigue disponible en código heredado; la implementación actual usa `incomeDark`).

### Capas de producto

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `aiLayer` / `aiLayerDark` | `#6D28D9` | `#8B5CF6` | IA, categorización automática |
| `syncLayer` / `syncLayerDark` | `#0E7490` | `#06B6D4` | Sincronización, importador bancario |

### Advertencias

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `warning` / `warningLight` | `#D97706` | `#FBBF24` | Alertas, estados de atención |

## ColorScheme Material 3

`FtTheme` deriva el `ColorScheme` a partir de `seedColor: FtColors.primary` (`#4374F8`) y lo ajusta con los tokens semánticos:

- **Superficies**: `surface`, `surfaceContainer*`, `bg`.
- **Texto**: `onSurface` → `textPrimary`; `onSurfaceVariant` → `textMuted`.
- **Errores**: `error` → `expense` / `expenseDark`.
- **Secundario**: `secondary` → `transfer` / `transferDark`.

## Accesibilidad

Todos los colores semánticos de primer nivel están elegidos para cumplir **WCAG AA** sobre sus fondos típicos:

- `primary` `#4374F8` sobre blanco.
- `income` `#047857` sobre blanco.
- `expense` `#BE123C` sobre blanco.
- `textPrimary` `#0F172A` sobre `surface` `#FFFFFF`.
- `textMuted` `#64748B` sobre `surface` `#FFFFFF`.

En modo oscuro, `textPrimaryDark` `#F8FAFC` y `textMutedDark` `#94A3B8` mantienen contraste sobre `surfaceDark` `#151D2A`.

## Aplicación de activos

### Android

- Fondo de icono adaptativo: `#090D16` (`ic_launcher_background`).
- Primer plano adaptativo: barras blancas centradas dentro de una **zona segura del ~66%** del canvas de 108–432 px.
- Icono monocromo: mismo primer plano convertido a luminancia/alfa.

### Web

- Favicon SVG/PNG/ICO desde el paquete de iconos.
- `theme-color` del PWA: `#4374F8`.
- Iconos `Icon-192.png` / `Icon-512.png` a partir del logo completo.
- Iconos `Icon-maskable-192.png` / `Icon-maskable-512.png` con el logo escalado al 80% para respetar la máscara.

### Otros

- `assets/images/logo.svg` / `logo.png` (1024 px).
- `fastlane/metadata/android/en-US/images/icon.png` (512 px).
- `.playstore/app_logo.png` (512 px).

## Convenciones de implementación

- Usar `FtColors.*` para colores semánticos; evitar valores hexadecimales hardcodeados en widgets.
- Preferir `incomeOf(context)`, `expenseOf(context)`, `transferOf(context)` cuando el color depende del tema.
- Para ajustes de opacidad utilizar `Color.withValues(alpha: ...)` (Flutter ≥3.22).
- Mantener `useMaterial3: true` en `ThemeData` para respetar los tokens de `ColorScheme`.
