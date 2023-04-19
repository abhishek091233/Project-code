import 'package:cubegon/Utils/extensions.dart';
import 'package:cubegon/WebLanding/about_page/about_screen.dart';
import 'package:cubegon/WebLanding/footer.dart';
import 'package:cubegon/WebLanding/landing7.dart';
import 'package:cubegon/WebLanding/landing9.dart';
import 'package:cubegon/WebLanding/landing_nav_bar.dart';
import 'package:cubegon/Widgets/widgets.dart';
import 'package:cubegon/responsive.dart';
// import 'package:cubegon/size_config.dart';
import 'package:flutter/material.dart';

import '../Constants/colors.dart';
import '../Utils/arrow_key_scroll_handler.dart';
import '../size_config.dart';
import 'landing1.dart';
import 'landing2.dart';
import 'landing3.dart';
import 'landing4.dart';
import 'landing5.dart';
import 'landing6.dart';
import 'landing8.dart';
import 'landing8_5.dart';
import 'widgets/drawer.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({Key? key}) : super(key: key);

  @override
  State<WebLandingPage> createState() => WebLandingPageState();
}

class WebLandingPageState extends State<WebLandingPage>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _controller = ScrollController(
    initialScrollOffset: 0,
    // initialScrollOffset: 7500,
  );

  bool isAboutPage = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final List<GlobalKey> tabs = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Scaffold(
        body: RawKeyboardListener(
          autofocus: true,
          focusNode: _focusNode,
          onKey: (event) {
            handleKeyEvent(event, _controller);
          },
          child: Responsive(
            onChange: () {
              SizeConfig().init(context);
            },
            bigScreen: Stack(
              children: [
                /// Main Content
                SingleChildScrollView(
                  controller: _controller,
                  // color: Colors.red,
                  child: (isAboutPage)
                      ? const AboutScreen()
                      : Column(
                          children: [
                            MainContentWrapper(
                              key: tabs[0],
                              top: true,
                              content: const LandingContent1(),
                            ),
                            MainContentWrapper(
                              key: tabs[1],
                              content: const LandingContent2(),
                            ),
                            MainContentWrapper(
                              key: tabs[2],
                              greyBg: true,
                              content: LandingContent3(),
                            ),
                            MainContentWrapper(
                              key: tabs[3],
                              content: const LandingContent4(),
                            ),
                            MainContentWrapper(
                              key: tabs[4],
                              content: const LandingContent5(),
                            ),
                            MainContentWrapper(
                              key: tabs[5],
                              content: const LandingContent6(),
                            ),
                            MainContentWrapper(
                              key: tabs[6],
                              content: const LandingContent7(),
                            ),
                            MainContentWrapper(
                              key: tabs[7],
                              content: LandingContent8(),
                            ),
                            MainContentWrapper(
                              key: tabs[8],
                              content: const LandingContent85(),
                            ),
                            MainContentWrapper(
                              key: tabs[9],
                              customBg: SizedBox(
                                height: context.height,
                                //  -
                                // context.mq.padding.top -
                                // context.mq.padding.bottom -
                                // 100,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 300,
                                      width: double.infinity,
                                      // margin: const EdgeInsets.only(top: 100),
                                      color: CGColours.primary.withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                              content: const LandingContent9(),
                            ),
                            LandingFooter(
                              tabKeys: tabs,
                              scrollController: _controller,
                            ),
                            Container(
                              height: context.mq.padding.top + 100,
                            )
                          ],
                        ),
                ),

                /// Header Navigation
                LandingNavBar(
                  scrollController: _controller,
                  tabKeys: tabs,
                  onTabSelected: (value) {
                    if (value == 3) {
                      setState(() {
                        isAboutPage = true;
                      });
                    } else {
                      setState(() {
                        isAboutPage = false;
                      });
                    }
                  },
                  // tabs: tabs,
                  // tabController: tabController,
                ),
              ],
            ),
            smallScreen: SingleChildScrollView(
              controller: _controller,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /// Header Navigation
                  const LogoAppBar(
                    showAppDrawer: true,
                  ),

                  /// Main Content
                  Column(
                    children: [
                      MainContentWrapper(
                        key: tabs[0],
                        top: false,
                        content: const LandingContent1(),
                      ),
                      // SizedBox(
                      //   height: context.mq.padding.top + 200,
                      // ),
                      MainContentWrapper(
                        key: tabs[1],
                        content: const LandingContent2(),
                      ),
                      MainContentWrapper(
                        key: tabs[2],
                        greyBg: true,
                        content: LandingContent3(),
                      ),
                      MainContentWrapper(
                        key: tabs[3],
                        content: const LandingContent4(),
                      ),
                      MainContentWrapper(
                        key: tabs[4],
                        content: const LandingContent5(),
                      ),
                      MainContentWrapper(
                        key: tabs[5],
                        content: const LandingContent6(),
                      ),
                      MainContentWrapper(
                        key: tabs[6],
                        content: const LandingContent7(),
                      ),
                      MainContentWrapper(
                        key: tabs[7],
                        content: LandingContent8(),
                      ),
                      MainContentWrapper(
                        key: tabs[8],
                        content: const LandingContent85(),
                      ),
                      MainContentWrapper(
                        key: tabs[9],
                        content: const LandingContent9(),
                      ),
                      LandingFooter(
                        tabKeys: tabs,
                        scrollController: _controller,
                      ),
                      Container(
                        height: context.mq.padding.top + 100,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: LandingPageDrawer(
          scrollController: _controller,
          tabKeys: tabs,
        ),
      ),
    );
  }
}

class MainContentWrapper extends StatelessWidget {
  const MainContentWrapper({
    Key? key,
    required this.content,
    this.top = true,
    this.greyBg = false,
    this.customBg,
  }) : super(key: key);

  final Widget content;
  final bool top;
  final bool greyBg;
  final Widget? customBg;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        customBg ?? Container(),
        Container(
          height: context.isSmallScreen
              ? null
              : context.height -
                  (context.isSmallScreen ? 0 : context.mq.padding.top) -
                  (context.isSmallScreen ? 0 : context.mq.padding.bottom) -
                  (context.isSmallScreen ? 0 : 100),
          color: greyBg ? CGColours.hex('FCFCFC') : null,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: top ? context.mq.padding.top + 100 : 0,
          ),
          child: content,
        ),
      ],
    );
  }
}
