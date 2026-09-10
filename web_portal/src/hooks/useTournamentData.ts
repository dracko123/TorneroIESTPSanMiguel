import { useState, useEffect, useCallback, useRef } from 'react';
import type { TournamentData } from '../types/tournament';
import { sampleTournamentData } from '../data/sampleTournamentData';
import { TOURNAMENT_CONFIG } from '../config/tournamentConfig';

const CACHE_KEY = 'antigravity_tournament_data_cache';

// Obtiene datos previos en caché para carga inmediata (0 ms)
function getInitialData(): TournamentData {
  try {
    const cached = localStorage.getItem(CACHE_KEY);
    if (cached) {
      const parsed = JSON.parse(cached);
      if (parsed && parsed.success && parsed.teams && parsed.matches) {
        return parsed;
      }
    }
  } catch (e) {
    // Si falla el parseo de localStorage, continuar con muestra
  }
  return sampleTournamentData;
}

export function useTournamentData() {
  const [data, setData] = useState<TournamentData>(getInitialData);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [isLiveSync, setIsLiveSync] = useState<boolean>(() => {
    // Si ya teníamos caché de una sesión previa válida, marcar como sincronizado
    return localStorage.getItem(CACHE_KEY) !== null;
  });

  const consecutiveErrorsRef = useRef<number>(0);
  const fetchRef = useRef<() => Promise<void>>(async () => {});

  const fetchData = useCallback(async () => {
    const url = TOURNAMENT_CONFIG.APPSCRIPT_URL.trim();
    const sheetId = TOURNAMENT_CONFIG.SHEET_ID.trim();

    // Si aún no se ha configurado la URL o el ID, usar datos muestra
    if (!url || !sheetId) {
      setData(sampleTournamentData);
      setIsLiveSync(false);
      setError(null);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const separator = url.includes('?') ? '&' : '?';
      const endpoint = `${url}${separator}action=getPublicData&sheetId=${encodeURIComponent(sheetId)}`;

      const response = await fetch(endpoint, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const json = await response.json();

      if (!json || !json.success) {
        throw new Error(json?.error || 'Error al obtener datos del torneo');
      }

      setData(json);
      setIsLiveSync(true);
      setLastUpdated(new Date());
      consecutiveErrorsRef.current = 0;

      // Guardar en caché local para próximas cargas ultra-rápidas
      try {
        localStorage.setItem(CACHE_KEY, JSON.stringify(json));
      } catch (storageErr) {
        console.warn('No se pudo persistir en localStorage:', storageErr);
      }
    } catch (err: any) {
      consecutiveErrorsRef.current += 1;
      console.warn(`Sincronización en segundo plano falló (intento ${consecutiveErrorsRef.current}), manteniendo datos en caché:`, err);
      setError(err.message || 'Error de conexión');
    } finally {
      setLoading(false);
    }
  }, []);

  fetchRef.current = fetchData;

  // Carga inicial y Smart Polling adaptativo
  useEffect(() => {
    // 1. Fetch inicial al cargar la página
    fetchData();

    let timer: ReturnType<typeof setTimeout> | null = null;
    const baseInterval = TOURNAMENT_CONFIG.POLLING_INTERVAL_MS || 45000; // 45 segundos para cuidar cuota

    const scheduleNextPoll = () => {
      if (timer) clearTimeout(timer);

      // Si la pestaña está oculta o el dispositivo está suspendido, NO sondear
      if (document.hidden) {
        return;
      }

      // Backoff exponencial ante fallas sucesivas (45s -> 60s -> 90s -> max 120s)
      const errorFactor = Math.min(consecutiveErrorsRef.current, 3);
      const delay = baseInterval + (errorFactor * 25000);

      timer = setTimeout(async () => {
        if (!document.hidden) {
          await fetchRef.current();
        }
        scheduleNextPoll();
      }, delay);
    };

    scheduleNextPoll();

    // 2. Control de visibilidad de la pestaña (Smart Polling)
    const handleVisibilityChange = () => {
      if (!document.hidden) {
        // El usuario volvió a la pestaña: actualizar de inmediato y reiniciar ciclo
        fetchRef.current();
        scheduleNextPoll();
      } else {
        // El usuario minimizó o cambió de app: cancelar timer para no gastar cuota de Apps Script
        if (timer) clearTimeout(timer);
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      if (timer) clearTimeout(timer);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [fetchData]);

  return {
    data,
    loading,
    error,
    lastUpdated,
    isLiveSync,
    refreshNow: () => fetchData()
  };
}
