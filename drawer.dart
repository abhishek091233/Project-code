import 'package:api_client/api_client.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cubegon/Auth/authentication.dart';
import 'package:cubegon/Router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LandingPageDrawer extends StatelessWidget {
  const LandingPageDrawer({
    Key? key,
    required this.scrollController,
    required this.tabKeys,
  }) : super(key: key);
  final ScrollController? scrollController;
  final List<GlobalKey> tabKeys;

  @override
  Widget build(BuildContext context) {
    final isAuthed = context.select(
      (AuthenticationBloc bloc) =>
          bloc.state.status == AuthenticationStatus.authenticated,
    );
    return Drawer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'CubeGon',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          /// Login
          if (!isAuthed)
            ListTile(
              onTap: () {
                context.router.push(const LogInScreenRoute());
              },
              leading: const Icon(Icons.login),
              title: const Text('Login'),
            ),

          /// Register
          if (!isAuthed)
            ListTile(
              onTap: () {
                context.router.push(const RegisterScreenRoute());
              },
              leading: const Icon(Icons.app_registration),
              title: const Text('Register'),
            ),

          /// DashBoard
          if (isAuthed)
            ListTile(
              onTap: () {
                context.router.push(DashBoardRoute());
              },
              leading: const Icon(Icons.dashboard),
              title: const Text('DashBoard'),
            ),

          ///
          ListTile(
            title: const Text('Contact'),
            leading: const Icon(Icons.contact_support),
            onTap: () {
              Navigator.of(context).pop();
              Scrollable.ensureVisible(
                tabKeys[8].currentContext!,
                duration: const Duration(milliseconds: 300),
              );
              // if (scrollController!.hasClients) {
              //   scrollController!.animateTo(
              //     (context.height * 8.2),
              //     duration: const Duration(milliseconds: 300),
              //     curve: Curves.easeInOut,
              //   );
              // } else {
              //   logger.e('ScrollController has no clients');
              // }
            },
          ),

          /// Logout
          if (isAuthed)
            ListTile(
              title: const Text('Logout'),
              leading: const Icon(Icons.logout),
              onTap: () {
                context.read<AuthenticationBloc>().add(
                      AuthenticationLogoutRequested(),
                    );
              },
            ),
        ],
      ),
    );
  }
}
