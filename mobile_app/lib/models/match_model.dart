class MatchModel {
  final String idPartido;
  final String fase;
  final String fechaHora;
  final String cancha;
  final String localId;
  final String visitaId;
  int golesLocal;
  int golesVisita;
  int penalesLocal;
  int penalesVisita;
  String estado; // PROGRAMADO, EN_VIVO, ENTRETIEMPO, FINALIZADO
  final String arbitroAsignado;

  MatchModel({
    required this.idPartido,
    required this.fase,
    required this.fechaHora,
    required this.cancha,
    required this.localId,
    required this.visitaId,
    this.golesLocal = 0,
    this.golesVisita = 0,
    this.penalesLocal = 0,
    this.penalesVisita = 0,
    required this.estado,
    this.arbitroAsignado = 'Por designar',
  });

  bool get isLive => estado == 'EN_VIVO' || estado == 'ENTRETIEMPO';
  bool get isFinished => estado == 'FINALIZADO';
  bool get isScheduled => estado == 'PROGRAMADO';
  bool get isPlayoff => !fase.toUpperCase().contains('GRUPO') && !fase.toUpperCase().contains('REGULAR');
  bool get isTie => golesLocal == golesVisita;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      idPartido: json['id_partido']?.toString() ?? '',
      fase: json['fase']?.toString() ?? 'Fase Regular',
      fechaHora: json['fecha_hora']?.toString() ?? DateTime.now().toIso8601String(),
      cancha: json['cancha']?.toString() ?? 'Cancha 1',
      localId: json['local_id']?.toString() ?? '',
      visitaId: json['visita_id']?.toString() ?? '',
      golesLocal: int.tryParse(json['goles_local']?.toString() ?? '0') ?? 0,
      golesVisita: int.tryParse(json['goles_visita']?.toString() ?? '0') ?? 0,
      penalesLocal: int.tryParse(json['penales_local']?.toString() ?? '0') ?? 0,
      penalesVisita: int.tryParse(json['penales_visita']?.toString() ?? '0') ?? 0,
      estado: json['estado']?.toString().toUpperCase() ?? 'PROGRAMADO',
      arbitroAsignado: json['arbitro_asignado']?.toString() ?? 'Por designar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_partido': idPartido,
      'fase': fase,
      'fecha_hora': fechaHora,
      'cancha': cancha,
      'local_id': localId,
      'visita_id': visitaId,
      'goles_local': golesLocal,
      'goles_visita': golesVisita,
      'penales_local': penalesLocal,
      'penales_visita': penalesVisita,
      'estado': estado,
      'arbitro_asignado': arbitroAsignado,
    };
  }
}
