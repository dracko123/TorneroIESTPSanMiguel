import { useTournamentData } from './hooks/useTournamentData';
import { Navbar } from './components/Navbar';
import { SportsHeroBanner } from './components/SportsHeroBanner';
import { LiveMatches } from './components/LiveMatches';
import { GroupStandings } from './components/GroupStandings';
import { PlayoffsBracket } from './components/PlayoffsBracket';
import { CommercialFooter } from './components/CommercialFooter';
import { WhatsAppFloatButton } from './components/WhatsAppFloatButton';

export function App() {
  const {
    data,
    loading,
    lastUpdated,
    isLiveSync
  } = useTournamentData();

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 relative overflow-hidden flex flex-col justify-between selection:bg-emerald-500 selection:text-black">
      {/* Luces atmosféricas de estadio (Estética Dark Stadium) */}
      <div className="stadium-light bg-emerald-600 top-10 left-1/4 opacity-15"></div>
      <div className="stadium-light bg-indigo-600 top-96 right-10 opacity-20"></div>
      <div className="stadium-light bg-amber-500 bottom-20 left-10 opacity-10"></div>

      {/* Barra de navegación superior (pública) con branding comercial */}
      <Navbar
        config={data.config}
        isLiveSync={isLiveSync}
        loading={loading}
        lastUpdated={lastUpdated}
      />

      {/* Contenido Principal para espectadores */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full relative z-10 flex-1">
        {/* Banner Deportivo Panorámico con Logo del Organizador y Cuenta Regresiva */}
        <SportsHeroBanner config={data.config} />

        {/* Sección de Partidos y Marcadores en Vivo */}
        <LiveMatches
          matches={data.matches || []}
          teams={data.teams || []}
        />

        {/* Sección de Tabla de Posiciones por Grupos */}
        <GroupStandings
          teams={data.teams || []}
          qualifiersPerGroup={
            data.config?.clasificados_por_grupo !== undefined &&
            data.config?.clasificados_por_grupo !== null &&
            String(data.config?.clasificados_por_grupo).trim() !== ''
              ? Math.max(0, Number(data.config.clasificados_por_grupo))
              : 2
          }
        />

        {/* Sección de Llaves de Playoffs */}
        <PlayoffsBracket
          bracket={data.bracket || []}
          teams={data.teams || []}
          matches={data.matches || []}
          config={data.config}
        />
      </main>

      {/* Pie de Página Comercial Thedesigninyoureyes con WhatsApp 931990036 */}
      <CommercialFooter config={data.config} />

      {/* Botón Flotante Directo de WhatsApp para Contrataciones */}
      <WhatsAppFloatButton />
    </div>
  );
}

export default App;
