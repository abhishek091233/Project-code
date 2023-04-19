import 'package:authentication_repository/authentication_repository.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cubegon/Router/router.dart';
import 'package:cubegon/Utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Auth/bloc/authentication_bloc.dart';
import '../Constants/constants.dart';
import '../Utils/extensions.dart';

class LandingNavBar extends StatefulWidget {
  const LandingNavBar({
    Key? key,
    this.scrollController,
    this.onTabSelected,
    this.tabKeys,
  }) : super(key: key);

  final ScrollController? scrollController;
  final ValueChanged<int>? onTabSelected;
  final List<GlobalKey>? tabKeys;

  @override
  State<LandingNavBar> createState() => _LandingNavBarState();
}

class _LandingNavBarState extends State<LandingNavBar>
    with TickerProviderStateMixin {
  void handleScroll() async {
    widget.onTabSelected?.call(tabController.index);

    if (context.router.current.name != WebLandingPageRoute.name) {
      context.router.push(const WebLandingPageRoute());
      return;
    }

    if (widget.scrollController != null) {
      switch (tabController.index) {
        case 0:
          Scrollable.ensureVisible(
            widget.tabKeys![0].currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // widget.scrollController!.animateTo(
          //   0,
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          break;
        case 1:
          Scrollable.ensureVisible(
            widget.tabKeys![1].currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // widget.scrollController!.animateTo(
          //   (context.height * 1) -
          //       context.mq.padding.top -
          //       context.mq.padding.bottom -
          //       100,
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          break;
        case 2:
          Scrollable.ensureVisible(
            widget.tabKeys![3].currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // widget.scrollController!.animateTo(
          //   (context.height * 2.6),
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          break;
        case 3:
          // await widget.scrollController!.animateTo(
          //   0,
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          tabController.animateTo(3);
          // showDialog(
          //   builder: (context) {
          //     return const Dialog(
          //       child: AboutScreen(),
          //     );
          //   },
          //   context: context,
          // );
          // context.router.pushNamed('/about');

          break;

        case 4:
          Scrollable.ensureVisible(
            widget.tabKeys![8].currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // widget.scrollController!.animateTo(
          //   (context.height * 7),
          //   duration: const Duration(milliseconds: 300),
          //   curve: Curves.easeInOut,
          // );
          break;
        default:
      }
    }
  }

  @override
  void initState() {
    tabController.addListener(handleScroll);
    super.initState();
  }

  @override
  dispose() {
    tabController.removeListener(handleScroll);
    super.dispose();
  }

  final tabs = [
    const Tab(
      text: 'Home',
    ),
    const Tab(
      text: 'Features',
    ),
    const Tab(
      text: 'Notes',
    ),
    const Tab(
      text: 'About',
    ),
    const Tab(
      text: 'Contact',
    ),
  ];

  late final TabController tabController = TabController(
    length: tabs.length,
    vsync: this,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1920, maxHeight: 100),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.isMediumScreen ? 120 : 240,
          ),

          ///Logo
          InkWell(
            onTap: () {
              widget.onTabSelected?.call(0);
              if (widget.scrollController != null) {
                widget.scrollController!.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              context.router.replaceAll([const WebLandingPageRoute()]);
              tabController.animateTo(0);
            },
            child: Image.asset(
              Assets.logoWithText,
              height: 120,
            ),
          ),
          const Spacer(),

          ///Navigation
          SizedBox(
            width: context.width * 0.4,
            child: TabBar(
              tabs: tabs,
              controller: tabController,
              // onTap: (_) => handleScroll(),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              indicatorColor: CGColours.primary,
              labelColor: Colors.black,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),

          if (context.watch<AuthenticationBloc>().state.status ==
              AuthenticationStatus.authenticated)
            Row(
              children: [
                IconButton(
                  tooltip: 'Dashboard',
                  icon: const Icon(Icons.space_dashboard_outlined),
                  onPressed: () {
                    logger.i('Dashboard Button Pressed');
                    context.router.replace(
                      DashBoardRoute(
                        intialNavIndex: 1,
                      ),
                    );
                    // context.router.replace(const LogInScreenRoute());
                  },
                ),
                IconButton(
                  tooltip: 'Log Out',
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    logger.i('Logout Button Pressed');
                    context.read<AuthenticationBloc>().add(
                          AuthenticationLogoutRequested(),
                        );
                    // context.router.replace(const WebLandingPageRoute());
                  },
                ),
              ],
            ),

          if (context.read<AuthenticationBloc>().state.status !=
              AuthenticationStatus.authenticated)

            /// Login Anden Register Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    context.router.push(const LogInScreenRoute());
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    context.router.push(const RegisterScreenRoute());
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(
                      CGColours.primary,
                    ),
                    side: MaterialStateProperty.all(
                      const BorderSide(
                        color: CGColours.primary,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      // color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(
            width: 24,
          ),
        ],
      ),
    );
  }
}
