import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/user_data_bootstrap_service.dart';
import '../home.dart';
import 'account_bootstrap_screen.dart';
import 'music_auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Get.find<AuthService>().restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final bootstrapService = Get.find<UserDataBootstrapService>();
    return Obx(() {
      if (authService.isLoadingSession.isTrue) {
        return const AccountBootstrapScreen(
          title: 'Validando tu sesion',
          message: 'Un momento, estamos preparando Estrella Music.',
        );
      }

      if (authService.isAuthenticated.isFalse) {
        bootstrapService.resetRuntimeState();
        return const MusicAuthScreen();
      }

      if (bootstrapService.needsBootstrapForCurrentUser) {
        Future.microtask(bootstrapService.prepareForAuthenticatedUser);
      }

      if (bootstrapService.isPreparing.isTrue) {
        return AccountBootstrapScreen(
          title: 'Sincronizando tu cuenta',
          message: bootstrapService.statusMessage.value,
          details: bootstrapService.lastError.value.isEmpty
              ? 'Estamos dejando lista tu cuenta para que entres con todos tus datos desde el primer momento.'
              : bootstrapService.lastError.value,
          willReplaceLocalData: bootstrapService.willReplaceLocalData.value,
        );
      }

      if (authService.isAuthenticated.isTrue) {
        return const Home();
      }

      return const MusicAuthScreen();
    });
  }
}
