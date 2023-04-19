import 'package:auto_route/auto_route.dart';
import 'package:cubegon/Router/router.dart';
import 'package:cubegon/Utils/extensions.dart';
import 'package:cubegon/Widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Constants/assets.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      height: context.height,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Image.asset(
                  Assets.notFoundBgImg,
                  fit: BoxFit.cover,
                ),
                Center(
                  child: Image.asset(
                    Assets.notFoundFgImg,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Go to Homepage button
                SizedBox(
                  width: context.width * 0.2,
                  child: FilledBtn(
                    text: 'Go to Homepage',
                    onPressed: () {
                      if (kIsWeb) {
                        context.router
                            .replaceAll([const WebLandingPageRoute()]);
                      } else {
                        context.router.popUntilRoot();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 24),

                /// Contact Us button
                SizedBox(
                  width: context.width * 0.2,
                  height: 50,
                  child: OutlinedButton(
                    // style: ,
                    child: const Text('Contact Us'),
                    onPressed: () {
                      // TODO: Open contact us page
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
