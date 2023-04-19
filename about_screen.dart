import 'package:cubegon/Utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../Constants/assets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 124,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Us',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                      ),
                      child: const SelectableText.rich(
                        TextSpan(
                          text:
                              'Cubegon is India’s leading online learning platform that helps students to Learn and Earn at same time. The website has been designed to make education more fun, less-time consuming and rewarding, for students. Cubegon currently caters to classes 9th- 12th across all boards. ',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (context.isBigScreen)
                  const SizedBox(
                    width: 100,
                  ),

                /// Image from Undraw
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 300,
                  ),
                  child: SvgPicture.asset(
                    Assets.aboutUs1,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (context.isBigScreen)
                  const SizedBox(
                    width: 100,
                  ),

                /// Image from Undraw
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 300,
                  ),
                  child: Image.asset(
                    Assets.aboutUs2,
                  ),
                ),

                if (context.isBigScreen)
                  const SizedBox(
                    width: 100,
                  ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                      ),
                      child: const SelectableText.rich(
                        TextSpan(
                          text:
                              'The website has an option to Upload Notes And Get Paid within a few hours. Team Cubegon is constantly engaged in bringing more features and making online learning real fun. The team is dedicated to provide the best user experience to the student community and make education the new cool thing. For any queries feel free to reach out at ',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                          children: [
                            TextSpan(
                              text: 'support@cubegon.com',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
