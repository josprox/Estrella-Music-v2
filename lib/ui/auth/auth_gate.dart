import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../home.dart';
import '../screens/Update/update_screen.dart';
import '../../services/update_service.dart';
import 'account_bootstrap_screen.dart';
import 'music_auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final isUpdateChecked = false.obs;
  final updateRequired = false.obs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check for updates first
    final hasUpdate = await UpdateService.checkForUpdate();
    updateRequired.value = hasUpdate;
    isUpdateChecked.value = true;

    if (!hasUpdate) {
      Get.find<AuthService>().restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    return Obx(() {
      if (isUpdateChecked.isFalse) {
        return const AccountBootstrapScreen(
          title: 'Estrella Music',
          message: 'Buscando actualizaciones...',
        );
      }

      if (updateRequired.isTrue) {
        return const UpdateScreen();
      }

      if (authService.isLoadingSession.isTrue) {
        return const AccountBootstrapScreen(
          title: 'Validando tu sesión',
          message: 'Un momento, estamos preparando Estrella Music.',
        );
      }

      if (authService.isAuthenticated.isFalse) {
        return const MusicAuthScreen();
      }

      if (authService.isAuthenticated.isTrue) {
        return const Home();
      }

      return const MusicAuthScreen();
    });
  }
}
