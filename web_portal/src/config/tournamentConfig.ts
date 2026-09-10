/**
 * ============================================================================
 * CONFIGURACIÓN INTERNA DEL TORNEO (NO VISIBLE AL PÚBLICO)
 * ============================================================================
 * Los parámetros de conexión hacia Google Apps Script y Google Sheets se configuran
 * aquí directamente en el código o mediante variables de entorno (.env).
 * 
 * Ningún usuario o espectador externo tiene acceso a editar, consultar o manipular
 * estos valores desde la interfaz web.
 * ============================================================================
 */

export const TOURNAMENT_CONFIG = {
  /**
   * URL de la Web App desplegada de Google Apps Script (backend/Code.js).
   */
  APPSCRIPT_URL: import.meta.env.VITE_APPSCRIPT_URL || 'https://script.google.com/macros/s/AKfycbwME8YfWEVRbynxhXcRhwUHDnJzdiuzCS7v80ZmeOWUX0Pn6MtQwJL7VL8eiUgQVfYU/exec',

  /**
   * ID del Google Spreadsheet del torneo.
   */
  SHEET_ID: import.meta.env.VITE_SHEET_ID || '1rci21UOupu2CS7G4RQLsIpFjQexwYDGGl9cJJpBXFGw',

  /**
   * Intervalo de sondeo automático en milisegundos (45 segundos por defecto para alta concurrencia).
   */
  POLLING_INTERVAL_MS: 45000
};
