# Vibenance Trade Republic Bridge (`vibenance-tr-bridge`)

Microservicio puente en Python (**FastAPI + Docker**) basado en la librería [`cdamken/tr-api`](https://github.com/cdamken/tr-api) para integrar la cartera, posiciones, saldo de efectivo, planes de ahorro y movimientos de **Trade Republic** en la aplicación **Vibenance** (Flutter Android y Web).

---

## 1. Arquitectura

```text
[Vibenance App (Flutter Android / Web)]
          │
          │ HTTPS / REST (Cabecera X-Bridge-Api-Key)
          ▼
[Contenedor Docker: vibenance-tr-bridge (FastAPI + Python 3.12)]
          │
          │ cdamken/tr-api (Auth Web v2 + WSS Protocol)
          ▼
[Trade Republic API (api.traderepublic.com / wss://api.traderepublic.com)]
```

### Ventajas clave:
- **Elimina problemas de CORS** en Flutter Web.
- **Persistencia de sesión**: Mantiene cookies (`JSESSIONID`, `tr_refresh`, `tr_device`) en un volumen persistente (`/app/data/tr_state`).
- **Seguridad**: Protegido por token de API estático (`X-Bridge-Api-Key`).
- **Aislamiento**: Todo el manejo del protocolo WebSocket y formatos binarios se delega al microservicio.

---

## 2. Despliegue en VPS / Servidor Docker

### 2.1. Estructura de archivos
El código del puente se encuentra en `docker/tr-bridge/`:
```text
docker/tr-bridge/
├── Dockerfile
├── docker-compose.example.yml
├── pyproject.toml
├── requirements.txt
├── README.md
└── app/
    ├── main.py
    ├── config.py
    ├── dependencies.py
    ├── schemas.py
    └── routers/
        ├── auth.py
        └── portfolio.py
```

### 2.2. Configuración de variables de entorno
Copia el archivo `docker-compose.example.yml` a `docker-compose.yml`:
```bash
cp docker-compose.example.yml docker-compose.yml
```

Edita las variables requeridas:
| Variable | Descripción | Valor por defecto | Ejemplo / Recomendado |
|---|---|---|---|
| `TR_BRIDGE_API_KEY` | Token secreto para autorizar peticiones desde la app | `[CAMBIA_ESTE_TOKEN]` | Generar token aleatorio seguro |
| `TR_STATE_DIR` | Directorio interno donde se guardan perfiles y cookies | `/app/data/tr_state` | `/app/data/tr_state` |
| `ALLOWED_ORIGINS` | Orígenes permitidos para CORS (separados por coma) | `*` | `https://vibenance.tudominio.com,*` |
| `REQUEST_TIMEOUT` | Timeout en segundos para peticiones HTTP | `30.0` | `30.0` |
| `WS_TIMEOUT` | Timeout en segundos para WebSocket TR snapshot | `90.0` | `90.0` |

### 2.3. Levantar el servicio con Docker Compose
```bash
docker compose up -d --build
```

El contenedor:
1. Se construirá a partir de `python:3.12-slim`.
2. Instalará dependencias y `cdamken/tr-api` desde Git.
3. Expondrá el servicio en el puerto del host `8085` (mapeado internamente al puerto `8000`).
4. Montará el volumen persistente `vibenance_tr_state_data` en `/app/data/tr_state`.

### 2.4. Comprobación de salud (Health Check)
Puedes verificar el estado del microservicio ejecutando:
```bash
curl -H "X-Bridge-Api-Key: TU_TOKEN_AQUI" http://localhost:8085/api/v1/health
```
Respuesta esperada:
```json
{
  "status": "ok",
  "authenticated": false,
  "active_phone": null
}
```

---

## 3. Conexión desde la App Vibenance

1. **Abrir Ajustes:** Entra en el menú lateral de Vibenance y pulsa en **Ajustes** -> **Inversiones**.
2. **Activar la integración:** En la sección **Integración Trade Republic**, activa el switch **"Activar Inversiones Trade Republic"**.
3. **Configurar parámetros:**
   - **URL del microservicio puente:** La URL pública o interna del microservicio (ej. `https://tr-bridge.tudominio.com` o `http://192.168.1.100:8085`).
   - **API Key del puente:** El token definido en `TR_BRIDGE_API_KEY`. Se guardará de forma cifrada en `flutter_secure_storage`.
   - **ID de cuenta de activos Firefly III (opcional):** Identificador de la cuenta de activos de Firefly III para vinculación.
4. **Probar conexión:** Pulsa el botón **"Probar conexión"**. Verás un mensaje verde de confirmación si el puente responde correctamente a `/api/v1/health`.
5. **Guardar:** Pulsa el botón **"Guardar"**.

---

## 4. Uso de la Cartera en Vibenance

Una vez activada la integración:
1. Aparecerá inmediatamente en el **menú lateral principal** el ítem **"Inversiones (TR)"** con icono bursátil.
2. Al entrar por primera vez, verás el estado de inicio de sesión. Pulsa **"Conectar con Trade Republic"**:
   - **Paso 1:** Introduce tu número de teléfono internacional (ej. `+34600000000`) y tu PIN de 4 dígitos.
   - **Paso 2:** Recibirás una notificación push en la app oficial de Trade Republic con un código de 4 dígitos. Introdúcelo en el modal para verificar.
3. Una vez autenticado:
   - **Pestaña Cartera:** Valor total, rentabilidad absoluta y porcentual, desglose de efectivo y lista de posiciones ordenadas.
   - **Pestaña Planes:** Total mensual programado y detalle de cada plan de ahorro.
   - **Pestaña Actividad:** Historial de movimientos, ejecuciones y cobro de intereses/dividendos.
4. La app dispone de soporte **Offline-First** (caché instantánea del último snapshot) y soporte de **Pull-to-Refresh**.
