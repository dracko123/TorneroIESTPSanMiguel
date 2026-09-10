import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/tournament_config_model.dart';
import '../models/bracket_model.dart';
import '../models/user_model.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});
}

class TournamentFullData {
  final TournamentConfigModel config;
  final List<TeamModel> teams;
  final List<MatchModel> matches;
  final List<BracketNodeModel> bracket;

  TournamentFullData({
    required this.config,
    required this.teams,
    required this.matches,
    required this.bracket,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Método helper robusto para peticiones POST hacia Google Apps Script.
  /// Maneja automáticamente la redirección 302 hacia script.googleusercontent.com
  /// e incluye sheetId y action tanto en la URL como en el cuerpo JSON.
  Future<http.Response> _postAppsScript(Uri uri, Map<String, dynamic> bodyMap) async {
    final enrichedUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      if (bodyMap.containsKey('action')) 'action': bodyMap['action'].toString(),
      if (bodyMap.containsKey('sheetId')) 'sheetId': bodyMap['sheetId'].toString(),
    });

    final response = await http.post(
      enrichedUri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bodyMap),
    ).timeout(const Duration(seconds: 35));

    // Si Apps Script responde con redirección (302 Found, etc.), se debe seguir la URL de Location mediante GET
    if (response.statusCode >= 301 && response.statusCode <= 308) {
      final location = response.headers['location'];
      if (location != null && location.isNotEmpty) {
        return await http.get(Uri.parse(location)).timeout(const Duration(seconds: 35));
      }
    }

    return response;
  }

  /// GET ?action=getPublicData&sheetId={ID}
  /// Lee toda la información pública con soporte de caché de 20s en Apps Script
  Future<ApiResponse<TournamentFullData>> getPublicData() async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'getPublicData',
        'sheetId': sheetId,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        if (jsonMap['success'] == true) {
          final config = TournamentConfigModel.fromJson(jsonMap['config'] ?? {});
          final List teamsRaw = jsonMap['teams'] ?? [];
          final List matchesRaw = jsonMap['matches'] ?? [];
          final List bracketRaw = jsonMap['bracket'] ?? [];

          final teams = teamsRaw.map((t) => TeamModel.fromJson(t)).toList();
          final matches = matchesRaw.map((m) => MatchModel.fromJson(m)).toList();
          final bracket = bracketRaw.map((b) => BracketNodeModel.fromJson(b)).toList();

          return ApiResponse(
            success: true,
            data: TournamentFullData(
              config: config,
              teams: teams,
              matches: matches,
              bracket: bracket,
            ),
          );
        } else {
          return ApiResponse(success: false, error: jsonMap['error']?.toString() ?? 'Error desconocido');
        }
      } else {
        return ApiResponse(
          success: false,
          error: 'Error del servidor: Código ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Fallo de conexión: $e');
    }
  }

  /// POST ?action=login
  Future<Map<String, dynamic>> login(String usuario, String pin) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'login',
        'sheetId': sheetId,
        'usuario': usuario,
        'pin': pin,
      };

      final response = await _postAppsScript(uri, bodyMap);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'success': false, 'error': 'Error de conexión: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar con el servidor: $e'};
    }
  }

  /// POST ?action=updateScore
  /// Actualiza goles, penales y estado de partido, invalidando la caché pública
  Future<ApiResponse<String>> updateScore({
    required String token,
    required String partidoId,
    required int golesLocal,
    required int golesVisita,
    int penalesLocal = 0,
    int penalesVisita = 0,
    required String estado,
    String? walkover,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'updateScore',
        'sheetId': sheetId,
        'token': token,
        'partidoId': partidoId,
        'golesLocal': golesLocal,
        'golesVisita': golesVisita,
        'penalesLocal': penalesLocal,
        'penalesVisita': penalesVisita,
        'estado': estado,
        if (walkover != null && walkover.isNotEmpty) 'walkover': walkover,
      };

      final response = await _postAppsScript(uri, bodyMap);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Actualizado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al actualizar');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error en llamada: $e');
    }
  }

  /// POST ?action=saveTournamentConfig
  Future<ApiResponse<String>> saveTournamentConfig({
    required String token,
    required TournamentConfigModel config,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'saveTournamentConfig',
        'sheetId': sheetId,
        'token': token,
        'config': config.toJson(),
      };

      final response = await _postAppsScript(uri, bodyMap);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: 'Configuración guardada exitosamente');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error guardando configuración');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error en guardado: $e');
    }
  }

  /// POST ?action=saveTeam
  Future<ApiResponse<String>> saveTeam({
    required String token,
    required TeamModel team,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'saveTeam',
        'sheetId': sheetId,
        'token': token,
        'team': team.toJson(),
      };

      final response = await _postAppsScript(uri, bodyMap);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['id_equipo'] ?? 'Equipo guardado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error guardando equipo');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=saveMatch
  Future<ApiResponse<String>> saveMatch({
    required String token,
    required MatchModel match,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'saveMatch',
        'sheetId': sheetId,
        'token': token,
        'match': match.toJson(),
      };

      final response = await _postAppsScript(uri, bodyMap);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['id_partido'] ?? 'Partido guardado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error guardando partido');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=uploadTeamLogo
  /// Sube un logo/escudo en Base64 a Google Drive y lo asigna al equipo
  Future<ApiResponse<String>> uploadTeamLogo({
    required String token,
    required String idEquipo,
    required String imageBase64,
    String mimeType = 'image/png',
    String? fileName,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'uploadTeamLogo',
        'sheetId': sheetId,
        'token': token,
        'id_equipo': idEquipo,
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'fileName': fileName,
      };

      final response = await _postAppsScript(uri, bodyMap);

      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['logo_url']?.toString() ?? '');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al subir imagen a Drive');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red al subir logo: $e');
    }
  }

  /// POST ?action=deleteTeam

  /// Elimina un equipo del Google Sheet por id_equipo
  Future<ApiResponse<String>> deleteTeam({
    required String token,
    required String idEquipo,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'deleteTeam',
        'sheetId': sheetId,
        'token': token,
        'id_equipo': idEquipo,
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Equipo eliminado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al eliminar equipo');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=deleteMatch
  /// Elimina un partido del Google Sheet por id_partido
  /// El backend bloquea la eliminación si el partido está EN_VIVO o ENTRETIEMPO.
  Future<ApiResponse<String>> deleteMatch({
    required String token,
    required String idPartido,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'deleteMatch',
        'sheetId': sheetId,
        'token': token,
        'id_partido': idPartido,
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Partido eliminado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al eliminar partido');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=batchSaveMatches
  /// Guarda en lote múltiples partidos generados por sorteo / fixture
  /// con control estricto de duplicados en backend.
  Future<ApiResponse<String>> batchSaveMatches({
    required String token,
    required List<MatchModel> matches,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'batchSaveMatches',
        'sheetId': sheetId,
        'token': token,
        'matches': matches.map((m) => m.toJson()).toList(),
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Partidos guardados exitosamente');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al guardar partidos');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=getUsers
  /// Retorna lista de usuarios administradores y mesas de control
  Future<ApiResponse<List<UserModel>>> getUsers({required String token}) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'getUsers',
        'sheetId': sheetId,
        'token': token,
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final List listRaw = data['users'] ?? [];
        final users = listRaw.map((u) => UserModel.fromUserListJson(u)).toList();
        return ApiResponse(success: true, data: users);
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al obtener usuarios');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=saveUser
  /// Crea o actualiza un usuario de mesa de control o administrador
  Future<ApiResponse<String>> saveUser({
    required String token,
    String? idUsuario,
    required String nombre,
    required String usuario,
    String? pin,
    String rol = 'MESA_CONTROL',
    String estado = 'ACTIVO',
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'saveUser',
        'sheetId': sheetId,
        'token': token,
        if (idUsuario != null && idUsuario.isNotEmpty) 'id_usuario': idUsuario,
        'nombre': nombre,
        'usuario': usuario,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        'rol': rol,
        'estado': estado,
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Usuario guardado exitosamente');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al guardar usuario');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }

  /// POST ?action=deleteUser
  /// Elimina un usuario de la lista
  Future<ApiResponse<String>> deleteUser({
    required String token,
    required String idUsuario,
  }) async {
    try {
      final baseUrl = await ApiEndpoints.getApiUrl();
      final sheetId = await ApiEndpoints.getSheetId();

      final uri = Uri.parse(baseUrl);
      final bodyMap = {
        'action': 'deleteUser',
        'sheetId': sheetId,
        'token': token,
        'id_usuario': idUsuario,
      };

      final response = await _postAppsScript(uri, bodyMap);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        return ApiResponse(success: true, data: data['message'] ?? 'Usuario eliminado');
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de red: $e');
    }
  }
}

