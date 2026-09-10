import React, { useState } from 'react';
import { MessageCircle, X } from 'lucide-react';

export const WhatsAppFloatButton: React.FC = () => {
  const [showTooltip, setShowTooltip] = useState<boolean>(true);
  const whatsappNumber = '51931990036';
  const whatsappMessage = encodeURIComponent(
    'Hola Thedesigninyoureyes, vi la plataforma en el torneo y deseo consultar precios para contratar el sistema.'
  );
  const whatsappUrl = `https://wa.me/${whatsappNumber}?text=${whatsappMessage}`;

  return (
    <div className="fixed bottom-5 right-5 z-50 flex items-end gap-3 pointer-events-auto">
      {/* Tooltip comercial flotante */}
      {showTooltip && (
        <div className="hidden sm:flex items-center gap-2 bg-slate-900/95 border border-emerald-500/40 text-white px-4 py-2.5 rounded-2xl shadow-2xl backdrop-blur-md animate-fade-in text-xs max-w-xs">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-ping flex-shrink-0"></div>
          <div>
            <p className="font-bold text-emerald-400">¿Organizas un torneo?</p>
            <p className="text-[11px] text-slate-300">Contrata esta plataforma con <span className="font-semibold text-white">Thedesigninyoureyes</span></p>
          </div>
          <button
            onClick={() => setShowTooltip(false)}
            className="ml-2 text-slate-400 hover:text-white p-0.5 rounded-full hover:bg-white/10"
            title="Cerrar sugerencia"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Botón Circular Principal de WhatsApp */}
      <a
        href={whatsappUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="relative group flex items-center justify-center w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-gradient-to-tr from-emerald-600 via-emerald-500 to-teal-400 text-slate-950 shadow-2xl shadow-emerald-500/40 transform transition-all duration-300 hover:scale-110 active:scale-95 focus:outline-none"
        title="Contratar Sistema en WhatsApp: +51 931 990 036"
      >
        {/* Anillo de pulso exterior */}
        <span className="absolute -inset-1 rounded-full bg-emerald-400 opacity-40 group-hover:opacity-75 animate-ping pointer-events-none"></span>

        {/* Icono de WhatsApp */}
        <div className="relative z-10 flex items-center justify-center">
          <MessageCircle className="w-7 h-7 sm:w-8 sm:h-8 fill-current" />
        </div>

        {/* Badge flotante móvil */}
        <span className="absolute -top-1 -right-1 bg-amber-400 text-slate-950 font-black text-[9px] px-1.5 py-0.5 rounded-full shadow-md uppercase tracking-wider">
          B2B
        </span>
      </a>
    </div>
  );
};
