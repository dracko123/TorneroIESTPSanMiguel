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
    };
  }
}
