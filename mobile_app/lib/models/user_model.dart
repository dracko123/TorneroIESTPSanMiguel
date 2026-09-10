class UserModel {
  final String idUsuario;
  final String nombre;
  final String usuario;
  final String rol; // SUPER_ADMIN o MESA_CONTROL
  final String token;
  final String estado; // ACTIVO o INACTIVO

  UserModel({
    required this.idUsuario,
    required this.nombre,
    required this.usuario,
    required this.rol,
    this.token = '',
    this.estado = 'ACTIVO',
  });

  bool get isSuperAdmin => rol == 'SUPER_ADMIN';
  bool get isMesaControl => rol == 'MESA_CONTROL';
  bool get isActivo => estado == 'ACTIVO';

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      idUsuario: json['id_usuario']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString().toUpperCase() ?? 'MESA_CONTROL',
      token: token,
      estado: json['estado']?.toString().toUpperCase() ?? 'ACTIVO',
    );
  }

  factory UserModel.fromUserListJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString().toUpperCase() ?? 'MESA_CONTROL',
      token: '',
      estado: json['estado']?.toString().toUpperCase() ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'usuario': usuario,
      'rol': rol,
      'token': token,
      'estado': estado,
    };
  }
}
