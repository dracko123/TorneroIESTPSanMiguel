/**
 * Utilidad para normalizar y transformar URLs de imágenes provenientes de servicios
 * en la nube como Google Drive, Dropbox, OneDrive, etc., para que puedan cargarse
 * directamente dentro de etiquetas <img> del navegador web.
 */
export function normalizeImageUrl(url?: string | null): string {
  if (!url || typeof url !== 'string') return '';
  const cleanUrl = url.trim();
  if (!cleanUrl) return '';

  // 1. Google Drive: Detectar enlaces de compartir /file/d/ID/view o ?id=ID
  const driveRegex = /(?:drive\.google\.com\/(?:file\/d\/|open\?id=|uc\?(?:export=[a-zA-Z]+&)?id=)|docs\.google\.com\/[a-zA-Z0-9_?&=]*id=)([a-zA-Z0-9_-]{20,})/;
  const driveMatch = cleanUrl.match(driveRegex);
  if (driveMatch && driveMatch[1]) {
    const fileId = driveMatch[1];
    // El endpoint directo de Google UserContent entrega el archivo de imagen directamente en alta resolución y con soporte CORS
    return `https://lh3.googleusercontent.com/d/${fileId}=w1600`;
  }

  // 2. Dropbox: transformar a enlace directo sin página intermedia
  if (cleanUrl.includes('dropbox.com')) {
    return cleanUrl
      .replace('www.dropbox.com', 'dl.dropboxusercontent.com')
      .replace(/[?&]dl=0/, '?raw=1');
  }

  // 3. OneDrive: soporte para enlaces de incrustación directa
  if (cleanUrl.includes('1drv.ms') || cleanUrl.includes('onedrive.live.com')) {
    if (!cleanUrl.includes('download=1')) {
      const separator = cleanUrl.includes('?') ? '&' : '?';
      return `${cleanUrl}${separator}download=1`;
    }
  }

  // 4. Limpieza de parámetros innecesarios de sesión (ej: authuser)
  if (cleanUrl.includes('photos.fife.usercontent.google.com') || cleanUrl.includes('googleusercontent.com')) {
    try {
      const parsed = new URL(cleanUrl);
      parsed.searchParams.delete('authuser');
      return parsed.toString();
    } catch {
      return cleanUrl;
    }
  }

  return cleanUrl;
}
