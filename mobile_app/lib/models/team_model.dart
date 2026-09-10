class TeamModel {
  final String idEquipo;
  final String nombre;
  final String grupo;
  final String colorHex;
  final String logoUrl;
  final int pj;
  final int pg;
  final int pe;
  final int pp;
  final int gf;
  final int gc;
  final int dg;
  final int puntos;

  TeamModel({
    required this.idEquipo,
    required this.nombre,
    required this.grupo,
    required this.colorHex,
    this.logoUrl = '',
    this.pj = 0,
    this.pg = 0,
    this.pe = 0,
    this.pp = 0,
    this.gf = 0,
    this.gc = 0,
    this.dg = 0,
    this.puntos = 0,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      idEquipo: json['id_equipo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin Nombre',
      grupo: (json['grupo']?.toString() ?? 'A').toUpperCase(),
      colorHex: json['color_hex']?.toString() ?? '#3B82F6',
      logoUrl: json['logo_url']?.toString() ?? '',
      pj: int.tryParse(json['pj']?.toString() ?? '0') ?? 0,
      pg: int.tryParse(json['pg']?.toString() ?? '0') ?? 0,
      pe: int.tryParse(json['pe']?.toString() ?? '0') ?? 0,
      pp: int.tryParse(json['pp']?.toString() ?? '0') ?? 0,
      gf: int.tryParse(json['gf']?.toString() ?? '0') ?? 0,
      gc: int.tryParse(json['gc']?.toString() ?? '0') ?? 0,
      dg: int.tryParse(json['dg']?.toString() ?? '0') ?? 0,
      puntos: int.tryParse(json['puntos']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_equipo': idEquipo,
      'nombre': nombre,
      'grupo': grupo,
      'color_hex': colorHex,
      'logo_url': logoUrl,
      'pj': pj,
      'pg': pg,
      'pe': pe,
      'pp': pp,
      'gf': gf,
      'gc': gc,
      'dg': dg,
      'puntos': puntos,
    };
  }
}
