import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_endpoints.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController(text: 'admin_magisterial');
  final _pinController = TextEditingController(text: '1234');
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    final user = _userController.text.trim();
    final pin = _pinController.text.trim();

    if (user.isEmpty || pin.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu usuario y PIN';
      });
      return;
    }

    try {
      final success = await AuthService().login(user, pin);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _showConfigDialog() async {
    final currentUrl = await ApiEndpoints.getApiUrl();
    final currentSheetId = await ApiEndpoints.getSheetId();

    final urlCtrl = TextEditingController(text: currentUrl);
    final sheetCtrl = TextEditingController(text: currentSheetId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.stadiumCardBg,
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppTheme.trophyGold),
            SizedBox(width: 8),
            Text('Ajustes de Conexión', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configura la URL de tu Web App de Google Apps Script y el ID del Google Spreadsheet:',
                style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'URL Apps Script Web App',
                  prefixIcon: Icon(Icons.link, color: AppTheme.turfGreenLight),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sheetCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Google Sheet ID',
                  prefixIcon: Icon(Icons.table_chart, color: AppTheme.turfGreenLight),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.slateTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiEndpoints.setApiUrl(urlCtrl.text);
              await ApiEndpoints.setSheetId(sheetCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración de conexión guardada'),
                    backgroundColor: AppTheme.turfGreen,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0A0F1D),
              Color(0xFF050811),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de configuración rápida en esquina
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: AppTheme.slateTextSecondary),
                      tooltip: 'Configurar Servidor y Sheet ID',
                      onPressed: _showConfigDialog,
                    ),
                  ),

                  // Escudo / Logo deportivo
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [AppTheme.turfGreen, Color(0xFF065F46)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.turfGreen.withAlpha(80),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Título
                  Text(
                    'TORNEO DEPORTIVO',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 1.5,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.trophyGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.trophyGold.withAlpha(80)),
                    ),
                    child: const Text(
                      'SISTEMA DE CONTROL & ARBITRAJE',
                      style: TextStyle(
                        color: AppTheme.trophyGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta de Formulario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ingrese sus credenciales autorizadas',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.slateTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Usuario
                          TextField(
                            controller: _userController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person, color: AppTheme.turfGreenLight),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PIN numérico
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 4,
                            ),
                            decoration: InputDecoration(
                              labelText: 'PIN de Seguridad',
                              prefixIcon: const Icon(Icons.lock, color: AppTheme.turfGreenLight),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.slateTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePin = !_obscurePin;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.liveRed.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.liveRed.withAlpha(100)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.liveRed, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppTheme.liveRed, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Botón de Ingreso
                          AnimatedBuilder(
                            animation: auth,
                            builder: (context, _) {
                              return ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login, size: 20),
                                          SizedBox(width: 8),
                                          Text('INGRESAR AL PANEL'),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Accesos rápidos para evaluación/demo
                  const Text(
                    'Credenciales de prueba rápida:',
                    style: TextStyle(color: AppTheme.slateTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.admin_panel_settings, size: 16, color: AppTheme.trophyGold),
                        label: const Text('Super Admin (1234)', style: TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: AppTheme.stadiumCardBg,
                        side: BorderSide(color: AppTheme.trophyGold.withAlpha(80)),
                        onPressed: () {
                          setState(() {
                            _userController.text = 'admin_magisterial';
                            _pinController.text = '1234';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.sports, size: 16, color: AppTheme.turfGreenLight),
                        label: const Text('Mesa Control (0000)', style: TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: AppTheme.stadiumCardBg,
                        side: BorderSide(color: AppTheme.turfGreenLight.withAlpha(80)),
                        onPressed: () {
                          setState(() {
                            _userController.text = 'mesa_cancha1';
                            _pinController.text = '0000';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
