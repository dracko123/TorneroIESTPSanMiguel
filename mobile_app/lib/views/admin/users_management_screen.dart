import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = _authService.getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesión expirada o no iniciada';
      });
      return;
    }

    final response = await _apiService.getUsers(token: token);
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _users = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.error ?? 'Error al cargar usuarios';
        _isLoading = false;
      });
    }
  }

  void _showUserFormDialog({UserModel? userToEdit}) {
    final isEditing = userToEdit != null;
    final nameCtrl = TextEditingController(text: userToEdit?.nombre ?? '');
    final userCtrl = TextEditingController(text: userToEdit?.usuario ?? '');
    final pinCtrl = TextEditingController();
    String selectedRole = userToEdit?.rol ?? 'MESA_CONTROL';
    String selectedStatus = userToEdit?.estado ?? 'ACTIVO';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
                    color: AppTheme.turfGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Editar Anotador / Mesa' : 'Nuevo Anotador / Mesa',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre completo:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ej: Carlos Gómez',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nombre de usuario (Login):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: userCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ej: mesa1 o cgomez',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEditing ? 'Nuevo PIN (dejar vacío si no cambia):' : 'PIN de acceso (4-6 dígitos):',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Opcional (mantener actual)' : 'Ej: 1234',
                        hintStyle: const TextStyle(color: Colors.white38),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Rol de usuario:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: const [
                            DropdownMenuItem(
                              value: 'MESA_CONTROL',
                              child: Row(
                                children: [
                                  Icon(Icons.sports_score, color: Colors.blueAccent, size: 18),
                                  SizedBox(width: 8),
                                  Text('Mesa de Control (Solo sus partidos)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'SUPER_ADMIN',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings, color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Text('Administrador Total (Super Admin)'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedRole = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Estado de la Cuenta', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ACTIVO')),
                            selected: selectedStatus == 'ACTIVO',
                            selectedColor: AppTheme.turfGreen.withAlpha(77),
                            labelStyle: TextStyle(
                              color: selectedStatus == 'ACTIVO' ? AppTheme.turfGreen : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                            onSelected: (_) => setDialogState(() => selectedStatus = 'ACTIVO'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('INACTIVO')),
                            selected: selectedStatus == 'INACTIVO',
                            selectedColor: Colors.redAccent.withAlpha(77),
                            labelStyle: TextStyle(
                              color: selectedStatus == 'INACTIVO' ? Colors.redAccent : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                            onSelected: (_) => setDialogState(() => selectedStatus = 'INACTIVO'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nombre = nameCtrl.text.trim();
                          final usuario = userCtrl.text.trim().toLowerCase();
                          final pin = pinCtrl.text.trim();

                          if (nombre.isEmpty || usuario.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nombre y usuario son obligatorios')),
                            );
                            return;
                          }

                          if (!isEditing && pin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('El PIN es obligatorio para crear el usuario')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final token = _authService.getToken();
                          if (token == null) {
                            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                            return;
                          }

                          final res = await _apiService.saveUser(
                            token: token,
                            idUsuario: userToEdit?.idUsuario,
                            nombre: nombre,
                            usuario: usuario,
                            pin: pin.isNotEmpty ? pin : null,
                            rol: selectedRole,
                            estado: selectedStatus,
                          );

                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                          if (!mounted) return;

                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.data ?? 'Usuario guardado'),
                                backgroundColor: AppTheme.turfGreen,
                              ),
                            );
                            _loadUsers();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.error ?? 'Error al guardar'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.turfGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(isEditing ? 'Guardar Cambios' : 'Crear Usuario', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Eliminar Acceso', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar el usuario "${user.nombre}" (@${user.usuario})? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = _authService.getToken();
    if (token == null) return;

    final res = await _apiService.deleteUser(token: token, idUsuario: user.idUsuario);
    if (!mounted) return;

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data ?? 'Usuario eliminado'), backgroundColor: Colors.redAccent),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Error al eliminar'), backgroundColor: Colors.amber),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.nombre.toLowerCase().contains(q) || u.usuario.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Mesas de Control y Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.turfGreen),
            tooltip: 'Recargar',
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserFormDialog(),
        backgroundColor: AppTheme.turfGreen,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Nueva Mesa',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Banner Informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E293B).withAlpha(153),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.turfGreen, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los usuarios de Mesa de Control solo podrán ver y anotar goles en los partidos que tengan asignados en el Fixture.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o usuario...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.turfGreen))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.turfGreen),
                              child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, color: Colors.white.withAlpha(77), size: 50),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty ? 'No hay usuarios registrados' : 'No se encontraron resultados',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final user = filteredUsers[idx];
                              final isSuper = user.isSuperAdmin;
                              final isActive = user.isActivo;

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSuper ? Colors.amber.withAlpha(102) : Colors.white10,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: CircleAvatar(
                                    backgroundColor: isSuper ? Colors.amber.withAlpha(51) : AppTheme.turfGreen.withAlpha(51),
                                    child: Icon(
                                      isSuper ? Icons.admin_panel_settings_rounded : Icons.sports_score_rounded,
                                      color: isSuper ? Colors.amber : AppTheme.turfGreen,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.nombre,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.withAlpha(51) : Colors.red.withAlpha(51),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          user.estado,
                                          style: TextStyle(
                                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          '@${user.usuario}',
                                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(20),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isSuper ? 'SUPER_ADMIN' : 'MESA_CONTROL',
                                            style: TextStyle(
                                              color: isSuper ? Colors.amber : Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 20),
                                        tooltip: 'Editar',
                                        onPressed: () => _showUserFormDialog(userToEdit: user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        tooltip: 'Eliminar',
                                        onPressed: () => _confirmDeleteUser(user),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
