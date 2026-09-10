class TournamentConfigModel {
  String nombreEvento;
  String disciplina;
  String countdownTarget;
  String countdownTitle;
  String faseActual;
  int clasificadosPorGrupo;
  String organizadorNombre;
  String organizadorLogoUrl;
  String bannerBgUrl;
  int puntosVictoria;
  int puntosEmpate;
  int puntosDerrota;
  int puntosVictoriaWo;
  int puntosDerrotaWo;
  int golesWoFavor;
  int golesWoContra;

  TournamentConfigModel({
    required this.nombreEvento,
    this.disciplina = 'FUTBOL',
    required this.countdownTarget,
    required this.countdownTitle,
    this.faseActual = 'GRUPOS',
    this.clasificadosPorGrupo = 2,
    this.organizadorNombre = '',
    this.organizadorLogoUrl = '',
    this.bannerBgUrl = '',
    this.puntosVictoria = 3,
    this.puntosEmpate = 1,
    this.puntosDerrota = 0,
    this.puntosVictoriaWo = 3,
    this.puntosDerrotaWo = -1,
    this.golesWoFavor = 3,
    this.golesWoContra = 0,
  });

  factory TournamentConfigModel.fromJson(Map<String, dynamic> json) {
    return TournamentConfigModel(
      nombreEvento: json['nombre_evento']?.toString() ?? 'Torneo Deportivo',
      disciplina: json['disciplina']?.toString() ?? 'FUTBOL',
      countdownTarget: json['countdown_target']?.toString() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      countdownTitle: json['countdown_title']?.toString() ?? 'Próximo Encuentro',
      faseActual: json['fase_actual']?.toString().toUpperCase() ?? 'GRUPOS',
      clasificadosPorGrupo: int.tryParse(json['clasificados_por_grupo']?.toString() ?? '2') ?? 2,
      organizadorNombre: json['organizador_nombre']?.toString() ?? '',
      organizadorLogoUrl: json['organizador_logo_url']?.toString() ?? '',
      bannerBgUrl: json['banner_bg_url']?.toString() ?? '',
      puntosVictoria: int.tryParse(json['puntos_victoria']?.toString() ?? '3') ?? 3,
      puntosEmpate: int.tryParse(json['puntos_empate']?.toString() ?? '1') ?? 1,
      puntosDerrota: int.tryParse(json['puntos_derrota']?.toString() ?? '0') ?? 0,
      puntosVictoriaWo: int.tryParse(json['puntos_victoria_wo']?.toString() ?? '3') ?? 3,
      puntosDerrotaWo: int.tryParse(json['puntos_derrota_wo']?.toString() ?? '-1') ?? -1,
      golesWoFavor: int.tryParse(json['goles_wo_favor']?.toString() ?? '3') ?? 3,
      golesWoContra: int.tryParse(json['goles_wo_contra']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_evento': nombreEvento,
      'disciplina': disciplina,
      'countdown_target': countdownTarget,
      'countdown_title': countdownTitle,
      'fase_actual': faseActual,
      'clasificados_por_grupo': clasificadosPorGrupo,
      'organizador_nombre': organizadorNombre,
      'organizador_logo_url': organizadorLogoUrl,
      'banner_bg_url': bannerBgUrl,
      'puntos_victoria': puntosVictoria,
      'puntos_empate': puntosEmpate,
      'puntos_derrota': puntosDerrota,
      'puntos_victoria_wo': puntosVictoriaWo,
      'puntos_derrota_wo': puntosDerrotaWo,
      'goles_wo_favor': golesWoFavor,
      'goles_wo_contra': golesWoContra,
    };
  }
}
