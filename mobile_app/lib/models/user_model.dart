class UserModel {
  final String idUsuario;
  final String nombre;
  final String usuario;
  final String rol; // SUPER_ADMIN o MESA_CONTROL
  final String token;

  UserModel({
    required this.idUsuario,
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.token,
  });

  bool get isSuperAdmin => rol == 'SUPER_ADMIN';
  bool get isMesaControl => rol == 'MESA_CONTROL';

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      idUsuario: json['id_usuario']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString().toUpperCase() ?? 'MESA_CONTROL',
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'usuario': usuario,
      'rol': rol,
      'token': token,
    };
  }
}
