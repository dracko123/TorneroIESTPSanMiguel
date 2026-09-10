class BracketNodeModel {
  final String cruceId;
  final String ronda; // Cuartos, Semifinal, Final
  final String equipo1Id;
  final String equipo2Id;
  final String ganadorId;
  final String siguienteCruceId;

  BracketNodeModel({
    required this.cruceId,
    required this.ronda,
    required this.equipo1Id,
    required this.equipo2Id,
    required this.ganadorId,
    required this.siguienteCruceId,
  });

  factory BracketNodeModel.fromJson(Map<String, dynamic> json) {
    return BracketNodeModel(
      cruceId: json['cruce_id']?.toString() ?? '',
      ronda: json['ronda']?.toString() ?? 'Ronda',
      equipo1Id: json['equipo_1_id']?.toString() ?? '',
      equipo2Id: json['equipo_2_id']?.toString() ?? '',
      ganadorId: json['ganador_id']?.toString() ?? '',
      siguienteCruceId: json['siguiente_cruce_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cruce_id': cruceId,
      'ronda': ronda,
      'equipo_1_id': equipo1Id,
      'equipo_2_id': equipo2Id,
      'ganador_id': ganadorId,
      'siguiente_cruce_id': siguienteCruceId,
    };
  }
}
