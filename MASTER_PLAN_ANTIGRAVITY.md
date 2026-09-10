# PLAN MAESTRO DE DESARROLLO — ANTIGRAVITY IDE

> **Proyecto:** Sistema Integral de Gestión de Torneos Deportivos  
> **Componentes:** App Android (Flutter) + Google Sheets Backend (Apps Script con Caché) + Portal Web Público (React/Vite Mundialista)  
> **Modo de Ejecución en Antigravity IDE:** Ejecución por fases secuenciales con validación autónoma.

---

## 1. OBJETIVO Y ALCANCE

Construir una plataforma deportiva de alto rendimiento compuesta por:
1. **Backend Google Sheets + Apps Script API:** Funciona como base de datos por evento (un Spreadsheet por torneo), expuesta mediante un script web con capa de caché (`CacheService`) para soportar miles de visitas sin agotar cuotas.
2. **App Móvil Android (Flutter):** Aplicación administrativa con inicio de sesión por roles (`SUPER_ADMIN` y `MESA_CONTROL`). Permite gestionar eventos, inscribir equipos por grupos, programar partidos, configurar el reloj de cuenta regresiva y operar la mesa de control táctil en vivo (comenzando por el módulo de **Fútbol**, con arquitectura preparada para Vóley y Básquet).
3. **Portal Web Público (React + Vite + Tailwind):** Sitio web temático "Dark Stadium / Mundialista", optimizado para celulares y PC, con cuenta regresiva en vivo, tablas de grupos, visualizador de llaves eliminatorias (Brackets interactivos) y actualización automática sin recargar página.

---

## 2. ARQUITECTURA DE ARCHIVOS Y DIRECTORIOS

```
torneo_deportivo/
├── backend/
│   ├── Code.js                      # API REST Google Apps Script (Auth, Caché, CRUD)
│   ├── appsscript.json              # Manifiesto de configuración de Apps Script
│   └── sheets_schema_template.json  # Definición exacta de hojas, columnas y fórmulas
├── mobile_app/                      # Proyecto Android en Flutter
│   ├── lib/
│   │   ├── main.dart                # Punto de entrada y enrutamiento
│   │   ├── config/                  # Constantes, temas y endpoints de la API
│   │   ├── models/                  # Usuario, Equipo, Partido, TorneoConfig, Bracket
│   │   ├── services/                # ApiService, AuthService (Tokens/Roles), SyncService
│   │   └── views/
│   │       ├── auth/                # LoginScreen (Usuario + PIN)
│   │       ├── admin/               # Configuración de torneo, grupos y brackets
│   │       ├── live/                # Mesa de control táctil (marcadores + / - y estados)
│   │       └── fixtures/            # Programación de partidos y cuenta regresiva
│   └── pubspec.yaml
├── web_portal/                      # Portal de resultados en React + Vite + Tailwind
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx                  # Layout principal con tema Dark Stadium
│   │   ├── components/
│   │   │   ├── CountdownBanner.tsx  # Reloj regresivo digital animado
│   │   │   ├── GroupStandings.tsx   # Tabla de posiciones y selector de grupos
│   │   │   ├── MatchCard.tsx        # Tarjeta de partido (en vivo con pulse, terminado)
│   │   │   ├── PlayoffsBracket.tsx  # Árbol interactivo de llaves eliminatorias
│   │   │   └── HeaderNavbar.tsx     # Barra de navegación con selector de evento
│   │   ├── hooks/
│   │   │   └── useTournamentData.ts # Polling cada 25s con gestión de estado
│   │   └── index.css                # Estilos personalizados (luces de estadio, glassmorphism)
│   ├── package.json
│   └── vite.config.ts
└── MASTER_PLAN_ANTIGRAVITY.md
```

---

## 3. ESQUEMA DE GOOGLE SHEETS & SEGURIDAD

Cada archivo de Google Spreadsheet representa un evento (ej. *"Juegos Magisteriales 2026"*). Contiene 5 hojas obligatorias:

### Hoja 1: `USUARIOS_ADMIN`
| Campo | Tipo | Ejemplo | Descripción |
| :--- | :--- | :--- | :--- |
| `id_usuario` | String | `USR-001` | Identificador único |
| `nombre` | String | Juan Pérez | Nombre para mostrar |
| `usuario` | String | `admin_magisterial` | Login |
| `pin_hash` | String | `8c6976e5b5410415...` | Hash SHA-256 del PIN/Contraseña |
| `rol` | String | `SUPER_ADMIN` / `MESA_CONTROL` | Permisos asignados |
| `estado` | String | `ACTIVO` / `BLOQUEADO` | Estado del usuario |

### Hoja 2: `CONFIG_EVENTO`
| Campo | Valor Ejemplo | Descripción |
| :--- | :--- | :--- |
| `nombre_evento` | Juegos Magisteriales 2026 | Nombre visual del torneo |
| `disciplina` | `FUTBOL` | Disciplina activa del módulo |
| `countdown_target` | `2026-10-15T09:00:00Z` | Fecha/hora del próximo partido o inauguración |
| `countdown_title` | Inauguración y Partido Inicial | Título para el portal web |
| `fase_actual` | `GRUPOS` | `GRUPOS`, `CUARTOS`, `SEMIFINAL`, `FINAL` |
| `clasificados_por_grupo` | `2` | Cantidad de equipos que avanzan |

### Hoja 3: `EQUIPOS_FUTBOL`
Columnas: `id_equipo`, `nombre`, `grupo`, `color_hex`, `pj`, `pg`, `pe`, `pp`, `gf`, `gc`, `dg`, `puntos`

### Hoja 4: `PARTIDOS_FUTBOL`
Columnas: `id_partido`, `fase`, `fecha_hora`, `cancha`, `local_id`, `visita_id`, `goles_local`, `goles_visita`, `penales_local`, `penales_visita`, `estado` (`PROGRAMADO`, `EN_VIVO`, `FINALIZADO`), `arbitro_asignado`

### Hoja 5: `BRACKET_FUTBOL`
Columnas: `cruce_id`, `ronda` (Cuartos, Semis, Final), `equipo_1_id`, `equipo_2_id`, `ganador_id`, `siguiente_cruce_id`

---

## 4. ESPECIFICACIÓN TÉCNICA DEL BACKEND (Google Apps Script)

### Requerimiento de Alto Tráfico y Rendimiento:
El script debe implementar `CacheService.getScriptCache()` con un TTL de 20 segundos para todas las consultas públicas.
- **`GET ?action=getPublicData&sheetId={ID}`**:
  1. Verifica si la respuesta serializada existe en `CacheService`. Si existe, retorna de inmediato.
  2. Si no existe, lee las hojas `CONFIG_EVENTO`, `EQUIPOS_FUTBOL`, `PARTIDOS_FUTBOL` y `BRACKET_FUTBOL`.
  3. Omite completamente la hoja `USUARIOS_ADMIN` por seguridad.
  4. Guarda el JSON en `CacheService` por 20 segundos y retorna.
- **`POST ?action=login`**:
  - Recibe `{ usuario, pin }`, busca en `USUARIOS_ADMIN`, calcula SHA-256 y si coincide, retorna `{ token, rol, nombre }`.
- **`POST ?action=updateScore`**:
  - Requiere `{ token, partidoId, golesLocal, golesVisita, estado }`.
  - Valida el token y actualiza la fila del partido. Recalcula automáticamente la tabla de posiciones en la hoja `EQUIPOS_FUTBOL`. Invalida la caché pública para refresco inmediato.
- **`POST ?action=saveTournamentConfig`**:
  - Requiere rol `SUPER_ADMIN`. Actualiza fechas, cuenta regresiva y configuración de clasificados.

---

## 5. ESPECIFICACIÓN DE LA APP MÓVIL (Flutter Android)

### Módulos Funcionales:
1. **Autenticación y Sesión:**
   - Login limpio y ágil para el personal en cancha.
   - Si el rol es `MESA_CONTROL`: Interfaz bloqueada exclusivamente para marcar goles y cambiar estados de partidos.
   - Si el rol es `SUPER_ADMIN`: Desbloquea pestañas de Configuración, Creación de Grupos, Equipos y Armado de Brackets.
2. **Módulo Fútbol - Grupos y Equipos:**
   - Crear equipos y asignarlos con un toque a Grupo A, B, C, D...
   - Selector de cuántos clasifican a la siguiente ronda (ej. 1ro y 2do de cada grupo).
3. **Mesa de Control en Vivo (Touch Friendly):**
   - Diseñado para usarse con una mano bajo la luz del sol.
   - Botones grandes `+` y `-` para goles locales y visitantes.
   - Botón selector de estado: `Programado` $\rightarrow$ `En Vivo` $\rightarrow$ `Entretiempo` $\rightarrow$ `Finalizado`.
   - Si finaliza en empate en eliminatorias: Activa automáticamente inputs de definición por penales.
4. **Programación y Contador Web:**
   - Date & Time Picker nativo para definir el inicio del próximo partido/evento.
   - Al guardar, sincroniza el campo `countdown_target` en el Sheet para que el portal web comience su cuenta atrás.

---

## 6. ESPECIFICACIÓN DEL PORTAL WEB (React + Tailwind)

### Experiencia Visual Mundialista:
- **Atmósfera "Dark Stadium":**
  - Fondo oscuro degradado (`bg-gradient-to-b from-slate-950 via-slate-900 to-indigo-950`).
  - Acentos de neón verde césped (`#10b981`) y dorado trofeo (`#f59e0b`).
  - Tarjetas de partido con efecto glassmorphism (`backdrop-blur-md bg-white/5 border border-white/10`).
- **Componente Countdown:**
  - Cajas de dígitos iluminadas: DÍAS | HORAS | MINUTOS | SEGUNDOS con animación al cambiar cada segundo.
  - Al llegar a 00:00:00: Muestra mensaje dinámico ("¡TORNEO EN VIVO!").
- **Componente Tabla de Posiciones:**
  - Pestañas estilizadas para alternar entre Grupo A, B, C, etc.
  - Las filas que clasifican a la siguiente fase se resaltan con borde verde y badge "Clasificado".
- **Visualizador de Llaves (Playoffs Bracket):**
  - Diagrama en árbol visual que une Cuartos de Final $\rightarrow$ Semifinales $\rightarrow$ Final.
  - El equipo ganador se ilumina en dorado con avance visual hacia la siguiente llave.
- **Actualización Automática:**
  - Hook con polling cada 25 segundos para reflejar goles y cambios de estado sin recargas.

---

## 7. FASES SECUENCIALES DE IMPLEMENTACIÓN EN ANTIGRAVITY IDE

### FASE 1: Backend Google Apps Script & Plantilla de Sheets
1. Generar `backend/Code.js` con las funciones de autenticación (SHA-256), manejo de `CacheService` y endpoints REST.
2. Generar `backend/sheets_schema_template.json` con la estructura de las hojas y fórmulas automáticas para la tabla de posiciones.

### FASE 2: Aplicación Móvil Android (Flutter)
1. Inicializar proyecto Flutter en `mobile_app/`.
2. Crear capa de servicios (`ApiService` y `AuthService`).
3. Construir pantalla de Login con validación de roles.
4. Construir panel de configuración de grupos, equipos y cuenta regresiva.
5. Construir pantalla de control táctil de partidos en vivo para el árbitro/mesa.

### FASE 3: Portal Web Público (React + Vite)
1. Inicializar proyecto React/Vite en `web_portal/` con Tailwind CSS.
2. Implementar el componente del reloj regresivo `CountdownBanner.tsx`.
3. Implementar la tabla de grupos y fixture `GroupStandings.tsx`.
4. Implementar el árbol interactivo de llaves `PlayoffsBracket.tsx`.
5. Integrar el hook de sincronización con caché.

### FASE 4: Pruebas de Integración y Validación
1. Ejecutar pruebas unitarias de cálculo de posiciones y desempates.
2. Verificar el tiempo de respuesta de la caché (< 200ms).
3. Validar el flujo extremo a extremo: Cambio de gol en App móvil $\rightarrow$ Reflejo en Portal Web.

---

## 8. INSTRUCCIÓN DE ARRANQUE PARA ANTIGRAVITY IDE

Cuando abras este proyecto en **Antigravity IDE**, envía la siguiente instrucción para iniciar el desarrollo:

```text
Por favor lee el archivo MASTER_PLAN_ANTIGRAVITY.md en la raíz del proyecto y comienza ejecutando la FASE 1:
1. Crea el archivo backend/Code.js con la API completa de Google Apps Script (Auth SHA-256, CacheService con TTL de 20 segundos y endpoints REST).
2. Genera la plantilla de esquema backend/sheets_schema_template.json con todas las hojas, columnas y fórmulas descritas.
3. Una vez completado, procede automáticamente con la FASE 2 para inicializar la app móvil en Flutter.
```
