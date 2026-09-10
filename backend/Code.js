/**
 * ============================================================================
 * PLATAFORMA DE GESTIÓN DE TORNEOS DEPORTIVOS — API GOOGLE APPS SCRIPT
 * ============================================================================
 * Arquitectura:
 * - Capa de Caché: CacheService (TTL: 20 segundos para consultas públicas)
 * - Seguridad: SHA-256 para contraseñas/PINes y Tokens de sesión firmados
 * - Control de Roles: SUPER_ADMIN y MESA_CONTROL
 * - Compatibilidad Multi-Spreadsheet mediante parámetro ?sheetId=
 * ============================================================================
 */

// Configuración global del Script
const CONFIG = {
  CACHE_TTL_SECONDS: 60,
  SECRET_SALT: 'TorneoMagisterial2026_SaltKey_SecureToken',
  TOKEN_EXPIRY_HOURS: 24,
  SHEET_NAMES: {
    USERS: 'USUARIOS_ADMIN',
    CONFIG: 'CONFIG_EVENTO',
    TEAMS: 'EQUIPOS_FUTBOL',
    MATCHES: 'PARTIDOS_FUTBOL',
    BRACKET: 'BRACKET_FUTBOL'
  }
};

/**
 * Manejador de peticiones GET
 */
function doGet(e) {
  try {
    const params = (e && e.parameter) ? e.parameter : {};
    const action = params.action || 'getPublicData';
    const sheetId = params.sheetId;

    if (action === 'ping') {
      return createJsonResponse({
        success: true,
        message: 'Torneo Sports API en línea',
        timestamp: new Date().toISOString()
      });
    }

    if (action === 'getPublicData') {
      if (!sheetId) {
        return createJsonResponse({
          success: false,
          error: 'Parámetro sheetId requerido'
        }, 400);
      }
      return getPublicDataWithCache(sheetId);
    }

    return createJsonResponse({
      success: false,
      error: 'Acción GET desconocida: ' + action
    }, 400);

  } catch (error) {
    return createJsonResponse({
      success: false,
      error: error.message || error.toString()
    }, 500);
  }
}

/**
 * Manejador de peticiones POST
 */
function doPost(e) {
  try {
    let payload = {};
    if (e && e.postData && e.postData.contents) {
      try {
        payload = JSON.parse(e.postData.contents);
      } catch (err) {
        payload = {};
      }
    }

    const params = (e && e.parameter) ? e.parameter : {};
    const action = payload.action || params.action;
    const sheetId = payload.sheetId || params.sheetId;

    if (!sheetId) {
      return createJsonResponse({
        success: false,
        error: 'Parámetro sheetId requerido en payload o query'
      }, 400);
    }

    const ss = getSpreadsheet(sheetId);
    if (!ss) {
      return createJsonResponse({
        success: false,
        error: 'No se pudo acceder al Google Spreadsheet con ID: ' + sheetId
      }, 404);
    }

    switch (action) {
      case 'login':
        return handleLogin(ss, payload);

      case 'updateScore':
        return handleUpdateScore(ss, sheetId, payload);

      case 'saveTournamentConfig':
        return handleSaveTournamentConfig(ss, sheetId, payload);

      case 'saveTeam':
        return handleSaveTeam(ss, sheetId, payload);

      case 'saveMatch':
        return handleSaveMatch(ss, sheetId, payload);

      case 'uploadTeamLogo':
        return handleUploadTeamLogo(ss, sheetId, payload);

      case 'deleteTeam':
        return handleDeleteTeam(ss, sheetId, payload);

      case 'deleteMatch':
        return handleDeleteMatch(ss, sheetId, payload);

      case 'batchSaveMatches':
        return handleBatchSaveMatches(ss, sheetId, payload);

      case 'setupSheets':
        return handleSetupSheets(ss, sheetId, payload);

      default:
        return createJsonResponse({
          success: false,
          error: 'Acción POST desconocida: ' + action
        }, 400);
    }

  } catch (error) {
    return createJsonResponse({
      success: false,
      error: error.message || error.toString()
    }, 500);
  }
}

// ============================================================================
// SERVICIOS DE CACHÉ Y LECTURA PÚBLICA
// ============================================================================

/**
 * Obtiene todos los datos públicos del torneo con caché de 20 segundos
 */
function getPublicDataWithCache(sheetId) {
  const cache = CacheService.getScriptCache();
  const cacheKey = 'public_data_' + sheetId;
  const cachedData = cache.get(cacheKey);

  if (cachedData) {
    return createJsonResponse(JSON.parse(cachedData), 200, true);
  }

  const ss = getSpreadsheet(sheetId);
  if (!ss) {
    return createJsonResponse({
      success: false,
      error: 'Spreadsheet no encontrado: ' + sheetId
    }, 404);
  }

  // Lectura de hojas públicas (USUARIOS_ADMIN OMITIDA POR SEGURIDAD)
  const config = readConfigSheet(ss);
  const teams = readSheetAsObjects(ss, CONFIG.SHEET_NAMES.TEAMS);
  const matches = readSheetAsObjects(ss, CONFIG.SHEET_NAMES.MATCHES);
  const bracket = readSheetAsObjects(ss, CONFIG.SHEET_NAMES.BRACKET);

  const responsePayload = {
    success: true,
    sheetId: sheetId,
    timestamp: new Date().toISOString(),
    config: config,
    teams: teams,
    matches: matches,
    bracket: bracket
  };

  try {
    // Almacenar en caché por 20 segundos (máximo de CacheService)
    cache.put(cacheKey, JSON.stringify(responsePayload), CONFIG.CACHE_TTL_SECONDS);
  } catch (cacheErr) {
    Logger.log('Advertencia de caché: ' + cacheErr.toString());
  }

  return createJsonResponse(responsePayload, 200, false);
}

/**
 * Invalida la caché del torneo al realizar modificaciones
 */
function invalidateTournamentCache(sheetId) {
  try {
    const cache = CacheService.getScriptCache();
    cache.remove('public_data_' + sheetId);
  } catch (err) {
    Logger.log('Error invalidando caché: ' + err.toString());
  }
}

// ============================================================================
// CONTROLADORES DE ACCIONES (POST)
// ============================================================================

/**
 * POST action=login
 * Autentica con usuario y PIN numérico usando SHA-256
 */
function handleLogin(ss, payload) {
  const usuario = (payload.usuario || '').trim();
  const pin = (payload.pin || '').toString().trim();

  if (!usuario || !pin) {
    return createJsonResponse({
      success: false,
      error: 'Usuario y PIN son requeridos'
    }, 400);
  }

  const users = readSheetAsObjects(ss, CONFIG.SHEET_NAMES.USERS);
  const pinHash = computeSHA256(pin);

  const matchedUser = users.find(u => 
    u.usuario && u.usuario.toString().toLowerCase() === usuario.toLowerCase()
  );

  if (!matchedUser) {
    return createJsonResponse({
      success: false,
      error: 'Credenciales inválidas'
    }, 401);
  }

  if (matchedUser.pin_hash !== pinHash) {
    return createJsonResponse({
      success: false,
      error: 'Credenciales inválidas'
    }, 401);
  }

  if (matchedUser.estado && matchedUser.estado.toString().toUpperCase() !== 'ACTIVO') {
    return createJsonResponse({
      success: false,
      error: 'Usuario bloqueado o inactivo'
    }, 403);
  }

  const token = generateAuthToken(matchedUser);

  return createJsonResponse({
    success: true,
    message: 'Autenticación exitosa',
    token: token,
    id_usuario: matchedUser.id_usuario,
    nombre: matchedUser.nombre,
    usuario: matchedUser.usuario,
    rol: matchedUser.rol
  });
}

/**
 * POST action=updateScore
 * Actualiza marcador en vivo, penales y estado. Recalcula tabla de posiciones.
 */
function handleUpdateScore(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token);
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 401);
  }

  const partidoId = payload.partidoId;
  const golesLocal = payload.golesLocal !== undefined ? Number(payload.golesLocal) : null;
  const golesVisita = payload.golesVisita !== undefined ? Number(payload.golesVisita) : null;
  const penalesLocal = payload.penalesLocal !== undefined ? Number(payload.penalesLocal) : 0;
  const penalesVisita = payload.penalesVisita !== undefined ? Number(payload.penalesVisita) : 0;
  const estado = payload.estado ? payload.estado.toString().toUpperCase() : null; // PROGRAMADO, EN_VIVO, ENTRETIEMPO, FINALIZADO

  if (!partidoId) {
    return createJsonResponse({ success: false, error: 'partidoId es requerido' }, 400);
  }

  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja de partidos no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  if (data.length < 2) {
    return createJsonResponse({ success: false, error: 'No hay partidos registrados' }, 404);
  }

  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_partido');
  const colGolesLocal = headers.indexOf('goles_local');
  const colGolesVisita = headers.indexOf('goles_visita');
  const colPenalesLocal = headers.indexOf('penales_local');
  const colPenalesVisita = headers.indexOf('penales_visita');
  const colEstado = headers.indexOf('estado');
  const colFase = headers.indexOf('fase');
  const colLocal = headers.indexOf('local_id');
  const colVisita = headers.indexOf('visita_id');

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === partidoId.toString()) {
      rowIndex = i + 1; // 1-indexed para Sheets
      break;
    }
  }

  if (rowIndex === -1) {
    return createJsonResponse({ success: false, error: 'Partido no encontrado con ID: ' + partidoId }, 404);
  }

  // Actualizar valores en la fila
  if (golesLocal !== null && colGolesLocal !== -1) {
    sheet.getRange(rowIndex, colGolesLocal + 1).setValue(golesLocal);
  }
  if (golesVisita !== null && colGolesVisita !== -1) {
    sheet.getRange(rowIndex, colGolesVisita + 1).setValue(golesVisita);
  }
  if (penalesLocal !== null && colPenalesLocal !== -1) {
    sheet.getRange(rowIndex, colPenalesLocal + 1).setValue(penalesLocal);
  }
  if (penalesVisita !== null && colPenalesVisita !== -1) {
    sheet.getRange(rowIndex, colPenalesVisita + 1).setValue(penalesVisita);
  }
  if (estado && colEstado !== -1) {
    sheet.getRange(rowIndex, colEstado + 1).setValue(estado);
  }

  SpreadsheetApp.flush();

  // Recalcular posiciones de fase de grupos
  recalculateStandings(ss);

  // Si el partido finalizó y pertenece a fase eliminatoria, avanzar bracket
  const matchRow = sheet.getRange(rowIndex, 1, 1, headers.length).getValues()[0];
  const fase = colFase !== -1 ? matchRow[colFase] : '';
  const finalState = colEstado !== -1 ? matchRow[colEstado] : estado;

  if (finalState === 'FINALIZADO') {
    updatePlayoffBracketAdvancement(ss, {
      partidoId: partidoId,
      fase: fase,
      localId: colLocal !== -1 ? matchRow[colLocal] : null,
      visitaId: colVisita !== -1 ? matchRow[colVisita] : null,
      golesLocal: colGolesLocal !== -1 ? matchRow[colGolesLocal] : golesLocal,
      golesVisita: colGolesVisita !== -1 ? matchRow[colGolesVisita] : golesVisita,
      penalesLocal: colPenalesLocal !== -1 ? matchRow[colPenalesLocal] : penalesLocal,
      penalesVisita: colPenalesVisita !== -1 ? matchRow[colPenalesVisita] : penalesVisita
    });
  }

  // Invalidar caché pública para que el portal web refleje el cambio de inmediato
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Marcador y estadísticas actualizadas exitosamente',
    partidoId: partidoId
  });
}

/**
 * POST action=saveTournamentConfig
 * Configura parámetros del torneo y sincroniza el reloj de cuenta regresiva
 */
function handleSaveTournamentConfig(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const config = payload.config || {};
  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.CONFIG);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja CONFIG_EVENTO no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const allowedKeys = [
    'nombre_evento',
    'disciplina',
    'countdown_target',
    'countdown_title',
    'fase_actual',
    'clasificados_por_grupo',
    'organizador_nombre',
    'organizador_logo_url',
    'banner_bg_url'
  ];

  // Mapear filas existentes por parámetro
  const keyToRow = {};
  for (let i = 1; i < data.length; i++) {
    const key = data[i][0] ? data[i][0].toString().trim() : '';
    if (key) {
      keyToRow[key] = i + 1;
    }
  }

  // Claves a procesar: allowedKeys + todas las claves enviadas en config
  const keysToProcess = [];
  allowedKeys.forEach(k => { if (keysToProcess.indexOf(k) === -1) keysToProcess.push(k); });
  Object.keys(config).forEach(k => { if (keysToProcess.indexOf(k) === -1) keysToProcess.push(k); });

  keysToProcess.forEach(key => {
    if (config[key] !== undefined && typeof config[key] !== 'object') {
      const val = config[key];
      if (keyToRow[key]) {
        sheet.getRange(keyToRow[key], 2).setValue(val);
      } else {
        sheet.appendRow([key, val, 'Configuración de ' + key]);
      }
    }
  });

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Configuración guardada exitosamente'
  });
}

/**
 * POST action=saveTeam
 * Registra o actualiza un equipo
 */
function handleSaveTeam(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const team = payload.team || {};
  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.TEAMS);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja EQUIPOS_FUTBOL no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_equipo');

  let rowIndex = -1;
  const idEquipo = team.id_equipo || ('EQP-' + ('0' + data.length).slice(-2));

  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === idEquipo.toString()) {
      rowIndex = i + 1;
      break;
    }
  }

  if (rowIndex !== -1) {
    // Actualizar equipo existente
    if (team.nombre) sheet.getRange(rowIndex, headers.indexOf('nombre') + 1).setValue(team.nombre);
    if (team.grupo) sheet.getRange(rowIndex, headers.indexOf('grupo') + 1).setValue(team.grupo.toUpperCase());
    if (team.color_hex) sheet.getRange(rowIndex, headers.indexOf('color_hex') + 1).setValue(team.color_hex);
    if (team.logo_url !== undefined) {
      let colLogo = headers.indexOf('logo_url');
      if (colLogo === -1) {
        colLogo = headers.length;
        sheet.getRange(1, colLogo + 1).setValue('logo_url');
      }
      sheet.getRange(rowIndex, colLogo + 1).setValue(team.logo_url);
    }
  } else {
    // Insertar nuevo equipo con fórmulas de DG y Puntos
    const targetRow = data.length + 1;
    const colLogo = headers.indexOf('logo_url');
    if (colLogo !== -1) {
      // Formato con columna logo_url: id_equipo, nombre, grupo, color_hex, logo_url, pj, pg, pe, pp, gf, gc, dg, puntos
      const formulaDg = '=J' + targetRow + '-K' + targetRow;
      const formulaPuntos = '=(G' + targetRow + '*3)+(H' + targetRow + '*1)';
      sheet.appendRow([
        idEquipo,
        team.nombre || 'Nuevo Equipo',
        (team.grupo || 'A').toUpperCase(),
        team.color_hex || '#3B82F6',
        team.logo_url || '',
        0, 0, 0, 0, 0, 0,
        formulaDg,
        formulaPuntos
      ]);
    } else {
      const formulaDg = '=I' + targetRow + '-J' + targetRow;
      const formulaPuntos = '=(F' + targetRow + '*3)+(G' + targetRow + '*1)';
      sheet.appendRow([
        idEquipo,
        team.nombre || 'Nuevo Equipo',
        (team.grupo || 'A').toUpperCase(),
        team.color_hex || '#3B82F6',
        0, 0, 0, 0, 0, 0,
        formulaDg,
        formulaPuntos
      ]);
    }
  }

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Equipo guardado correctamente',
    id_equipo: idEquipo
  });
}

/**
 * Obtiene o crea la carpeta 'Logos_Equipos' en la misma ubicación que el Spreadsheet
 */
function getOrCreateLogosFolder(sheetId) {
  try {
    const sheetFile = DriveApp.getFileById(sheetId);
    const parents = sheetFile.getParents();
    const parentFolder = parents.hasNext() ? parents.next() : DriveApp.getRootFolder();

    const folderName = 'Logos_Equipos';
    const existing = parentFolder.getFoldersByName(folderName);
    if (existing.hasNext()) {
      return existing.next();
    } else {
      const newFolder = parentFolder.createFolder(folderName);
      newFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
      return newFolder;
    }
  } catch (err) {
    Logger.log('Error accediendo a carpeta padre: ' + err.toString());
    const folderName = 'Logos_Equipos';
    const rootExisting = DriveApp.getFoldersByName(folderName);
    if (rootExisting.hasNext()) {
      return rootExisting.next();
    }
    const created = DriveApp.createFolder(folderName);
    created.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return created;
  }
}

/**
 * POST action=uploadTeamLogo
 * Recibe imagen en Base64, la guarda en Google Drive en la carpeta junto al Sheet
 * y actualiza la columna logo_url del equipo en EQUIPOS_FUTBOL.
 */
function handleUploadTeamLogo(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const idEquipo = payload.id_equipo;
  const imageBase64 = payload.imageBase64;
  const mimeType = payload.mimeType || 'image/png';
  const extension = mimeType.includes('jpeg') || mimeType.includes('jpg') ? '.jpg' : '.png';
  const fileName = (payload.fileName || (idEquipo + '_logo')) + extension;

  if (!idEquipo || !imageBase64) {
    return createJsonResponse({
      success: false,
      error: 'id_equipo e imageBase64 son requeridos'
    }, 400);
  }

  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.TEAMS);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja EQUIPOS_FUTBOL no encontrada' }, 404);
  }

  // 1. Obtener o crear carpeta Logos_Equipos en la misma ubicación que el Sheet
  const folder = getOrCreateLogosFolder(sheetId);

  // 2. Decodificar Base64 y crear archivo en Google Drive
  const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
  const decodedBytes = Utilities.base64Decode(cleanBase64);
  const blob = Utilities.newBlob(decodedBytes, mimeType, fileName);
  const file = folder.createFile(blob);

  // 3. Compartir archivo para visualización pública mediante enlace
  file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  const fileId = file.getId();

  // Enlace directo de CDN de Google (carga rápida en app y web sin bloqueo de cookies)
  const logoUrl = 'https://lh3.googleusercontent.com/d/' + fileId;

  // 4. Actualizar columna logo_url en EQUIPOS_FUTBOL
  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_equipo');
  let colLogo = headers.indexOf('logo_url');

  if (colLogo === -1) {
    colLogo = headers.length;
    sheet.getRange(1, colLogo + 1).setValue('logo_url');
  }

  let updated = false;
  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === idEquipo.toString()) {
      sheet.getRange(i + 1, colLogo + 1).setValue(logoUrl);
      updated = true;
      break;
    }
  }

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Logo del equipo subido exitosamente a Google Drive',
    id_equipo: idEquipo,
    logo_url: logoUrl,
    file_id: fileId
  });
}

/**
 * POST action=saveMatch
 * Programa o actualiza un partido del fixture
 */
function handleSaveMatch(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const match = payload.match || {};
  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja PARTIDOS_FUTBOL no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_partido');

  const idPartido = match.id_partido || ('MAT-' + ('0' + data.length).slice(-2));
  let rowIndex = -1;

  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === idPartido.toString()) {
      rowIndex = i + 1;
      break;
    }
  }

  if (rowIndex !== -1) {
    if (match.fase) sheet.getRange(rowIndex, headers.indexOf('fase') + 1).setValue(match.fase);
    if (match.fecha_hora) sheet.getRange(rowIndex, headers.indexOf('fecha_hora') + 1).setValue(match.fecha_hora);
    if (match.cancha) sheet.getRange(rowIndex, headers.indexOf('cancha') + 1).setValue(match.cancha);
    if (match.local_id) sheet.getRange(rowIndex, headers.indexOf('local_id') + 1).setValue(match.local_id);
    if (match.visita_id) sheet.getRange(rowIndex, headers.indexOf('visita_id') + 1).setValue(match.visita_id);
    if (match.estado) sheet.getRange(rowIndex, headers.indexOf('estado') + 1).setValue(match.estado);
    if (match.arbitro_asignado) sheet.getRange(rowIndex, headers.indexOf('arbitro_asignado') + 1).setValue(match.arbitro_asignado);
  } else {
    // Validar duplicado para partido nuevo en la misma fase
    const colFase = headers.indexOf('fase');
    const colLocal = headers.indexOf('local_id');
    const colVisita = headers.indexOf('visita_id');
    const targetFase = (match.fase || '').toString().trim().toUpperCase();
    const targetLoc = (match.local_id || '').toString().trim();
    const targetVis = (match.visita_id || '').toString().trim();

    if (targetLoc && targetVis) {
      for (let i = 1; i < data.length; i++) {
        const f = (data[i][colFase] || '').toString().trim().toUpperCase();
        const loc = (data[i][colLocal] || '').toString().trim();
        const vis = (data[i][colVisita] || '').toString().trim();
        if (f === targetFase && loc === targetLoc && vis === targetVis) {
          return createJsonResponse({
            success: false,
            error: `Ya existe un partido programado entre ${targetLoc} y ${targetVis} en la fase ${match.fase}.`
          }, 400);
        }
      }
    }

    sheet.appendRow([
      idPartido,
      match.fase || 'Grupo A',
      match.fecha_hora || new Date().toISOString(),
      match.cancha || 'Cancha 1',
      match.local_id || '',
      match.visita_id || '',
      0, 0, 0, 0,
      match.estado || 'PROGRAMADO',
      match.arbitro_asignado || 'Por designar'
    ]);
  }

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Partido programado exitosamente',
    id_partido: idPartido
  });
}

/**
 * POST action=batchSaveMatches
 * Registra en lote múltiples partidos generados por sorteo / fixture
 * con estricto control de no duplicación.
 */
function handleBatchSaveMatches(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const matches = payload.matches || [];
  if (!Array.isArray(matches) || matches.length === 0) {
    return createJsonResponse({ success: false, error: 'Lista de partidos vacía' }, 400);
  }

  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja PARTIDOS_FUTBOL no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colFase = headers.indexOf('fase');
  const colLocal = headers.indexOf('local_id');
  const colVisita = headers.indexOf('visita_id');

  // Mapear partidos existentes para evitar duplicados estrictos
  const existingSet = new Set();
  for (let i = 1; i < data.length; i++) {
    const f = (data[i][colFase] || '').toString().trim().toUpperCase();
    const loc = (data[i][colLocal] || '').toString().trim();
    const vis = (data[i][colVisita] || '').toString().trim();
    if (loc && vis) {
      existingSet.add(`${f}__${loc}__${vis}`);
    }
  }

  let countAdded = 0;
  let skippedDuplicates = 0;
  let nextSeq = data.length;
  const rowsToAppend = [];

  for (let k = 0; k < matches.length; k++) {
    const m = matches[k];
    const f = (m.fase || 'Grupo A').toString().trim().toUpperCase();
    const loc = (m.local_id || '').toString().trim();
    const vis = (m.visita_id || '').toString().trim();

    if (!loc || !vis || loc === vis) {
      continue;
    }

    const key = `${f}__${loc}__${vis}`;
    if (existingSet.has(key)) {
      skippedDuplicates++;
      continue;
    }

    existingSet.add(key);
    const idPartido = m.id_partido || ('MAT-' + ('0' + nextSeq).slice(-2));
    nextSeq++;

    rowsToAppend.push([
      idPartido,
      m.fase || 'Grupo A',
      m.fecha_hora || new Date().toISOString(),
      m.cancha || 'Cancha 1',
      loc,
      vis,
      0, 0, 0, 0,
      m.estado || 'PROGRAMADO',
      m.arbitro_asignado || 'Por designar'
    ]);
    countAdded++;
  }

  if (rowsToAppend.length > 0) {
    const startRow = sheet.getLastRow() + 1;
    sheet.getRange(startRow, 1, rowsToAppend.length, rowsToAppend[0].length).setValues(rowsToAppend);
  }

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: `Se registraron ${countAdded} partidos nuevos` + (skippedDuplicates > 0 ? ` (${skippedDuplicates} omitidos por ya existir).` : '.'),
    added: countAdded,
    skipped: skippedDuplicates
  });
}


/**
 * POST action=deleteTeam
 * Elimina permanentemente un equipo del Sheet por su id_equipo
 * Solo SUPER_ADMIN puede ejecutar esta acción.
 */
function handleDeleteTeam(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const idEquipo = payload.id_equipo;
  if (!idEquipo) {
    return createJsonResponse({ success: false, error: 'id_equipo es requerido' }, 400);
  }

  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.TEAMS);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja EQUIPOS_FUTBOL no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_equipo');

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === idEquipo.toString()) {
      rowIndex = i + 1;
      break;
    }
  }

  if (rowIndex === -1) {
    return createJsonResponse({ success: false, error: 'Equipo no encontrado: ' + idEquipo }, 404);
  }

  sheet.deleteRow(rowIndex);
  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Equipo eliminado correctamente',
    id_equipo: idEquipo
  });
}

/**
 * POST action=deleteMatch
 * Elimina permanentemente un partido del Sheet por su id_partido
 * Bloquea eliminación si el partido está EN_VIVO o ENTRETIEMPO.
 * Solo SUPER_ADMIN puede ejecutar esta acción.
 */
function handleDeleteMatch(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid) {
    return createJsonResponse({ success: false, error: auth.error }, 403);
  }

  const idPartido = payload.id_partido;
  if (!idPartido) {
    return createJsonResponse({ success: false, error: 'id_partido es requerido' }, 400);
  }

  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheet) {
    return createJsonResponse({ success: false, error: 'Hoja PARTIDOS_FUTBOL no encontrada' }, 404);
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => h.toString().trim());
  const colId = headers.indexOf('id_partido');
  const colEstado = headers.indexOf('estado');

  let rowIndex = -1;
  let matchEstado = '';
  for (let i = 1; i < data.length; i++) {
    if (data[i][colId] && data[i][colId].toString() === idPartido.toString()) {
      rowIndex = i + 1;
      matchEstado = data[i][colEstado] ? data[i][colEstado].toString().toUpperCase() : '';
      break;
    }
  }

  if (rowIndex === -1) {
    return createJsonResponse({ success: false, error: 'Partido no encontrado: ' + idPartido }, 404);
  }

  // Bloquear eliminación de partidos activos para evitar accidentes durante el juego
  if (matchEstado === 'EN_VIVO' || matchEstado === 'ENTRETIEMPO') {
    return createJsonResponse({
      success: false,
      error: 'No se puede eliminar un partido que está EN VIVO o en ENTRETIEMPO. Primero finalícelo o cámbielo a PROGRAMADO.'
    }, 409);
  }

  sheet.deleteRow(rowIndex);
  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Partido eliminado correctamente',
    id_partido: idPartido
  });
}

/**
 * POST action=setupSheets
 * Inicializa automáticamente las 5 hojas si el spreadsheet está vacío
 */
function handleSetupSheets(ss, sheetId, payload) {
  const auth = verifyAuthToken(payload.token, 'SUPER_ADMIN');
  if (!auth.valid && payload.initialSetupKey !== 'MAGISTERIAL_INIT_2026') {
    return createJsonResponse({ success: false, error: 'No autorizado para inicializar hojas' }, 403);
  }

  // 1. USUARIOS_ADMIN
  let sheetUsers = ss.getSheetByName(CONFIG.SHEET_NAMES.USERS);
  if (!sheetUsers) {
    sheetUsers = ss.insertSheet(CONFIG.SHEET_NAMES.USERS);
    sheetUsers.appendRow(['id_usuario', 'nombre', 'usuario', 'pin_hash', 'rol', 'estado']);
    sheetUsers.appendRow([
      'USR-001',
      'Director de Torneo',
      'admin_magisterial',
      computeSHA256('1234'),
      'SUPER_ADMIN',
      'ACTIVO'
    ]);
    sheetUsers.appendRow([
      'USR-002',
      'Mesa de Control Principal',
      'mesa_cancha1',
      computeSHA256('0000'),
      'MESA_CONTROL',
      'ACTIVO'
    ]);
    formatHeaderRow(sheetUsers);
  }

  // 2. CONFIG_EVENTO
  let sheetConfig = ss.getSheetByName(CONFIG.SHEET_NAMES.CONFIG);
  if (!sheetConfig) {
    sheetConfig = ss.insertSheet(CONFIG.SHEET_NAMES.CONFIG);
    sheetConfig.appendRow(['parametro', 'valor', 'descripcion']);
    sheetConfig.appendRow(['nombre_evento', 'Juegos Magisteriales 2026', 'Nombre visual del torneo']);
    sheetConfig.appendRow(['disciplina', 'FUTBOL', 'Disciplina deportiva activa']);
    sheetConfig.appendRow(['countdown_target', '2026-10-15T09:00:00Z', 'Fecha/hora del próximo partido o inauguración']);
    sheetConfig.appendRow(['countdown_title', 'Inauguración y Partido Inicial', 'Título para el portal web']);
    sheetConfig.appendRow(['fase_actual', 'GRUPOS', 'Fase activa: GRUPOS, CUARTOS, SEMIFINAL, FINAL']);
    sheetConfig.appendRow(['clasificados_por_grupo', '2', 'Equipos que avanzan a eliminatorias']);
    sheetConfig.appendRow(['organizador_nombre', 'Comité Organizador Magisterial 2026', 'Nombre del organizador oficial']);
    sheetConfig.appendRow(['organizador_logo_url', '', 'URL del logo del organizador']);
    sheetConfig.appendRow(['banner_bg_url', '', 'URL de imagen de fondo del hero banner']);
    formatHeaderRow(sheetConfig);
  }

  // 3. EQUIPOS_FUTBOL
  let sheetTeams = ss.getSheetByName(CONFIG.SHEET_NAMES.TEAMS);
  if (!sheetTeams) {
    sheetTeams = ss.insertSheet(CONFIG.SHEET_NAMES.TEAMS);
    sheetTeams.appendRow(['id_equipo', 'nombre', 'grupo', 'color_hex', 'logo_url', 'pj', 'pg', 'pe', 'pp', 'gf', 'gc', 'dg', 'puntos']);
    const sampleTeams = [
      ['EQP-01', 'Magisterio Cusco', 'A', '#DC2626', ''],
      ['EQP-02', 'Docentes Arequipa', 'A', '#2563EB', ''],
      ['EQP-03', 'Educadores Puno', 'A', '#16A34A', ''],
      ['EQP-04', 'Colegio Abancay', 'A', '#CA8A04', ''],
      ['EQP-05', 'Pedagógico Lima', 'B', '#9333EA', ''],
      ['EQP-06', 'I.E. Trujillo Norte', 'B', '#0D9488', ''],
      ['EQP-07', 'Profesores Piura', 'B', '#EA580C', ''],
      ['EQP-08', 'Magisterio Huancayo', 'B', '#4F46E5', '']
    ];
    sampleTeams.forEach((t, idx) => {
      const r = idx + 2;
      sheetTeams.appendRow([...t, 0, 0, 0, 0, 0, 0, '=J' + r + '-K' + r, '=(G' + r + '*3)+(H' + r + '*1)']);
    });
    formatHeaderRow(sheetTeams);
  }

  // 4. PARTIDOS_FUTBOL
  let sheetMatches = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheetMatches) {
    sheetMatches = ss.insertSheet(CONFIG.SHEET_NAMES.MATCHES);
    sheetMatches.appendRow([
      'id_partido', 'fase', 'fecha_hora', 'cancha', 'local_id', 'visita_id',
      'goles_local', 'goles_visita', 'penales_local', 'penales_visita', 'estado', 'arbitro_asignado'
    ]);
    sheetMatches.appendRow(['MAT-01', 'Grupo A', '2026-10-15T09:00:00Z', 'Cancha 1', 'EQP-01', 'EQP-02', 0, 0, 0, 0, 'PROGRAMADO', 'Carlos Morales']);
    sheetMatches.appendRow(['MAT-02', 'Grupo A', '2026-10-15T10:30:00Z', 'Cancha 2', 'EQP-03', 'EQP-04', 0, 0, 0, 0, 'PROGRAMADO', 'Luis Rojas']);
    sheetMatches.appendRow(['MAT-03', 'Grupo B', '2026-10-15T12:00:00Z', 'Cancha 1', 'EQP-05', 'EQP-06', 0, 0, 0, 0, 'PROGRAMADO', 'Miguel Soto']);
    sheetMatches.appendRow(['MAT-04', 'Grupo B', '2026-10-15T13:30:00Z', 'Cancha 2', 'EQP-07', 'EQP-08', 0, 0, 0, 0, 'PROGRAMADO', 'Carlos Morales']);
    formatHeaderRow(sheetMatches);
  }

  // 5. BRACKET_FUTBOL
  let sheetBracket = ss.getSheetByName(CONFIG.SHEET_NAMES.BRACKET);
  if (!sheetBracket) {
    sheetBracket = ss.insertSheet(CONFIG.SHEET_NAMES.BRACKET);
    sheetBracket.appendRow(['cruce_id', 'ronda', 'equipo_1_id', 'equipo_2_id', 'ganador_id', 'siguiente_cruce_id']);
    sheetBracket.appendRow(['CRU-C1', 'Cuartos', 'EQP-01', 'EQP-06', '', 'CRU-S1']);
    sheetBracket.appendRow(['CRU-C2', 'Cuartos', 'EQP-05', 'EQP-02', '', 'CRU-S1']);
    sheetBracket.appendRow(['CRU-C3', 'Cuartos', 'EQP-03', 'EQP-08', '', 'CRU-S2']);
    sheetBracket.appendRow(['CRU-C4', 'Cuartos', 'EQP-07', 'EQP-04', '', 'CRU-S2']);
    sheetBracket.appendRow(['CRU-S1', 'Semifinal', '', '', '', 'CRU-FIN']);
    sheetBracket.appendRow(['CRU-S2', 'Semifinal', '', '', '', 'CRU-FIN']);
    sheetBracket.appendRow(['CRU-FIN', 'Final', '', '', '', '']);
    formatHeaderRow(sheetBracket);
  }

  SpreadsheetApp.flush();
  invalidateTournamentCache(sheetId);

  return createJsonResponse({
    success: true,
    message: 'Estructura de 5 hojas inicializada con éxito en el Google Spreadsheet'
  });
}

// ============================================================================
// LÓGICA DE NEGOCIO DE FÚTBOL (TABLA DE POSICIONES Y BRACKETS)
// ============================================================================

/**
 * Recalcula la tabla de posiciones en EQUIPOS_FUTBOL a partir de los partidos finalizados
 */
function recalculateStandings(ss) {
  const sheetTeams = ss.getSheetByName(CONFIG.SHEET_NAMES.TEAMS);
  const sheetMatches = ss.getSheetByName(CONFIG.SHEET_NAMES.MATCHES);
  if (!sheetTeams || !sheetMatches) return;

  const teamsData = sheetTeams.getDataRange().getValues();
  const matchesData = sheetMatches.getDataRange().getValues();

  if (teamsData.length < 2 || matchesData.length < 2) return;

  const teamHeaders = teamsData[0].map(h => h.toString().trim());
  const colTeamId = teamHeaders.indexOf('id_equipo');

  const matchHeaders = matchesData[0].map(h => h.toString().trim());
  const colFase = matchHeaders.indexOf('fase');
  const colLocal = matchHeaders.indexOf('local_id');
  const colVisita = matchHeaders.indexOf('visita_id');
  const colGolesLocal = matchHeaders.indexOf('goles_local');
  const colGolesVisita = matchHeaders.indexOf('goles_visita');
  const colEstado = matchHeaders.indexOf('estado');

  // Inicializar acumuladores por equipo
  const stats = {};
  for (let i = 1; i < teamsData.length; i++) {
    const id = teamsData[i][colTeamId];
    if (id) {
      stats[id] = { pj: 0, pg: 0, pe: 0, pp: 0, gf: 0, gc: 0 };
    }
  }

  // Acumular partidos de fase de grupos terminados
  for (let m = 1; m < matchesData.length; m++) {
    const row = matchesData[m];
    const estado = (row[colEstado] || '').toString().toUpperCase();
    const fase = (row[colFase] || '').toString().toUpperCase();

    // Solo computar partidos finalizados que pertenezcan a la fase regular o de grupos
    if (estado === 'FINALIZADO' && (fase.includes('GRUPO') || fase.includes('REGULAR'))) {
      const idLocal = row[colLocal];
      const idVisita = row[colVisita];
      const gl = Number(row[colGolesLocal]) || 0;
      const gv = Number(row[colGolesVisita]) || 0;

      if (stats[idLocal] && stats[idVisita]) {
        stats[idLocal].pj += 1;
        stats[idVisita].pj += 1;
        stats[idLocal].gf += gl;
        stats[idLocal].gc += gv;
        stats[idVisita].gf += gv;
        stats[idVisita].gc += gl;

        if (gl > gv) {
          stats[idLocal].pg += 1;
          stats[idVisita].pp += 1;
        } else if (gl < gv) {
          stats[idVisita].pg += 1;
          stats[idLocal].pp += 1;
        } else {
          stats[idLocal].pe += 1;
          stats[idVisita].pe += 1;
        }
      }
    }
  }

  // Escribir estadísticas en la hoja de equipos
  const colPj = teamHeaders.indexOf('pj');
  const colPg = teamHeaders.indexOf('pg');
  const colPe = teamHeaders.indexOf('pe');
  const colPp = teamHeaders.indexOf('pp');
  const colGf = teamHeaders.indexOf('gf');
  const colGc = teamHeaders.indexOf('gc');

  for (let i = 1; i < teamsData.length; i++) {
    const id = teamsData[i][colTeamId];
    if (id && stats[id]) {
      const rowIndex = i + 1;
      const s = stats[id];
      if (colPj !== -1) sheetTeams.getRange(rowIndex, colPj + 1).setValue(s.pj);
      if (colPg !== -1) sheetTeams.getRange(rowIndex, colPg + 1).setValue(s.pg);
      if (colPe !== -1) sheetTeams.getRange(rowIndex, colPe + 1).setValue(s.pe);
      if (colPp !== -1) sheetTeams.getRange(rowIndex, colPp + 1).setValue(s.pp);
      if (colGf !== -1) sheetTeams.getRange(rowIndex, colGf + 1).setValue(s.gf);
      if (colGc !== -1) sheetTeams.getRange(rowIndex, colGc + 1).setValue(s.gc);
    }
  }
}

/**
 * Si un partido de eliminación directa finaliza, avanza al ganador en BRACKET_FUTBOL
 */
function updatePlayoffBracketAdvancement(ss, match) {
  const sheetBracket = ss.getSheetByName(CONFIG.SHEET_NAMES.BRACKET);
  if (!sheetBracket) return;

  const data = sheetBracket.getDataRange().getValues();
  if (data.length < 2) return;

  const headers = data[0].map(h => h.toString().trim());
  const colCruceId = headers.indexOf('cruce_id');
  const colEq1 = headers.indexOf('equipo_1_id');
  const colEq2 = headers.indexOf('equipo_2_id');
  const colGanador = headers.indexOf('ganador_id');
  const colNext = headers.indexOf('siguiente_cruce_id');

  // Determinar ganador considerando goles y penales
  let winnerId = null;
  const gl = Number(match.golesLocal) || 0;
  const gv = Number(match.golesVisita) || 0;
  const pl = Number(match.penalesLocal) || 0;
  const pv = Number(match.penalesVisita) || 0;

  if (gl > gv) {
    winnerId = match.localId;
  } else if (gv > gl) {
    winnerId = match.visitaId;
  } else {
    // Definición por penales
    if (pl > pv) winnerId = match.localId;
    else if (pv > pl) winnerId = match.visitaId;
  }

  if (!winnerId) return;

  // Buscar el cruce donde participan estos equipos
  let matchedCruceRow = -1;
  let nextCruceId = null;

  for (let i = 1; i < data.length; i++) {
    const eq1 = data[i][colEq1];
    const eq2 = data[i][colEq2];

    const matchFound = (
      (eq1 === match.localId && eq2 === match.visitaId) ||
      (eq1 === match.visitaId && eq2 === match.localId)
    );

    if (matchFound) {
      matchedCruceRow = i + 1;
      nextCruceId = data[i][colNext];
      // Asignar ganador en este cruce
      sheetBracket.getRange(matchedCruceRow, colGanador + 1).setValue(winnerId);
      break;
    }
  }

  // Si existe siguiente cruce, colocar al ganador en la primera posición disponible
  if (nextCruceId) {
    for (let j = 1; j < data.length; j++) {
      if (data[j][colCruceId] === nextCruceId) {
        const nextRow = j + 1;
        const currentEq1 = data[j][colEq1];
        const currentEq2 = data[j][colEq2];

        if (!currentEq1 || currentEq1 === '') {
          sheetBracket.getRange(nextRow, colEq1 + 1).setValue(winnerId);
        } else if (!currentEq2 || currentEq2 === '') {
          sheetBracket.getRange(nextRow, colEq2 + 1).setValue(winnerId);
        }
        break;
      }
    }
  }
}

// ============================================================================
// FUNCIONES AUXILIARES (SEGURIDAD, TOKENS, EXTRACCIÓN DE DATOS)
// ============================================================================

/**
 * Calcula el hash SHA-256 de una cadena
 */
function computeSHA256(text) {
  const rawBytes = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    text.toString(),
    Utilities.Charset.UTF_8
  );
  let hexString = '';
  for (let i = 0; i < rawBytes.length; i++) {
    let byteVal = rawBytes[i];
    if (byteVal < 0) byteVal += 256;
    const byteHex = byteVal.toString(16);
    hexString += (byteHex.length === 1 ? '0' : '') + byteHex;
  }
  return hexString;
}

/**
 * Genera un token firmado con expiración
 */
function generateAuthToken(user) {
  const payload = {
    uid: user.id_usuario,
    usr: user.usuario,
    rol: user.rol,
    exp: Date.now() + (CONFIG.TOKEN_EXPIRY_HOURS * 60 * 60 * 1000)
  };
  const payloadStr = Utilities.base64EncodeWebSafe(JSON.stringify(payload));
  const signature = computeSHA256(payloadStr + CONFIG.SECRET_SALT);
  return payloadStr + '.' + signature;
}

/**
 * Valida el token recibido y su rol
 */
function verifyAuthToken(token, requiredRole) {
  if (!token || typeof token !== 'string') {
    return { valid: false, error: 'Token no proporcionado' };
  }

  const parts = token.split('.');
  if (parts.length !== 2) {
    return { valid: false, error: 'Formato de token inválido' };
  }

  const payloadStr = parts[0];
  const signature = parts[1];
  const expectedSignature = computeSHA256(payloadStr + CONFIG.SECRET_SALT);

  if (signature !== expectedSignature) {
    return { valid: false, error: 'Firma de token inválida' };
  }

  try {
    const decodedBytes = Utilities.base64DecodeWebSafe(payloadStr);
    const decodedStr = Utilities.newBlob(decodedBytes).getDataAsString();
    const payload = JSON.parse(decodedStr);

    if (Date.now() > payload.exp) {
      return { valid: false, error: 'El token ha expirado. Inicie sesión nuevamente.' };
    }

    if (requiredRole && payload.rol !== requiredRole && payload.rol !== 'SUPER_ADMIN') {
      return { valid: false, error: 'Permisos insuficientes. Rol requerido: ' + requiredRole };
    }

    return { valid: true, user: payload };
  } catch (err) {
    return { valid: false, error: 'Error decodificando token: ' + err.toString() };
  }
}

/**
 * Abre el Spreadsheet de forma segura
 */
function getSpreadsheet(sheetId) {
  try {
    return SpreadsheetApp.openById(sheetId);
  } catch (e) {
    return null;
  }
}

/**
 * Lee una hoja y la convierte en un arreglo de objetos JSON usando la primera fila como claves
 */
function readSheetAsObjects(ss, sheetName) {
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length < 2) return [];

  const headers = data[0].map(h => h.toString().trim());
  const rows = [];

  for (let r = 1; r < data.length; r++) {
    const row = data[r];
    // Ignorar filas totalmente vacías
    const hasData = row.some(cell => cell !== '' && cell !== null && cell !== undefined);
    if (!hasData) continue;

    const obj = {};
    for (let c = 0; c < headers.length; c++) {
      let val = row[c];
      if (val instanceof Date) {
        val = val.toISOString();
      }
      obj[headers[c]] = val;
    }
    rows.push(obj);
  }

  return rows;
}

/**
 * Lee la hoja CONFIG_EVENTO y la retorna como un diccionario clave-valor
 */
function readConfigSheet(ss) {
  const sheet = ss.getSheetByName(CONFIG.SHEET_NAMES.CONFIG);
  if (!sheet) return {};

  const data = sheet.getDataRange().getValues();
  if (data.length < 2) return {};

  const configObj = {};
  for (let i = 1; i < data.length; i++) {
    const key = data[i][0] ? data[i][0].toString().trim() : '';
    let val = data[i][1];
    if (val instanceof Date) val = val.toISOString();
    if (key) {
      configObj[key] = val;
    }
  }
  return configObj;
}

/**
 * Aplica estilos limpios a la fila de encabezados
 */
function formatHeaderRow(sheet) {
  const range = sheet.getRange(1, 1, 1, sheet.getLastColumn());
  range.setBackground('#0F172A')
       .setFontColor('#F8FAFC')
       .setFontWeight('bold')
       .setFontFamily('Roboto');
  sheet.setFrozenRows(1);
}

/**
 * Retorna salida HTTP con cabeceras CORS y tipo JSON
 */
function createJsonResponse(data, statusCode, isCached) {
  const output = ContentService.createTextOutput(JSON.stringify(data));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}

/**
 * ============================================================================
 * FUNCIÓN DE INICIALIZACIÓN RÁPIDA (EJECUCIÓN MANUAL EN APPS SCRIPT)
 * ============================================================================
 * Si abres Apps Script desde Extensiones > Apps Script en tu Google Sheet,
 * puedes seleccionar esta función y hacer clic en "Ejecutar" para crear
 * todas las hojas, encabezados, fórmulas y datos de prueba automáticamente.
 */
function INICIALIZAR_HOJAS_AUTOMATICAMENTE() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  if (!ss) {
    Logger.log('No se detectó una hoja activa. Abre el script desde Extensiones > Apps Script en tu Google Sheet.');
    return;
  }
  const sheetId = ss.getId();
  Logger.log('Iniciando configuración para el Spreadsheet ID: ' + sheetId);
  handleSetupSheets(ss, sheetId, { initialSetupKey: 'MAGISTERIAL_INIT_2026' });
  Logger.log('¡Todas las hojas, encabezados y fórmulas han sido creadas con éxito!');
}
