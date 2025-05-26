import 'package:mocadb/src/core/utils/extension.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constants_index.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/print.dart';
import '../../../core/utils/routes.dart';
import '../login_index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToNextScreen();
  }

  void navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 2), () {
      NavigateRoutes.navigateTo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Center(
        child: Image.asset(
          Assets.appLogo,
          height: context.width * .75,
          width: context.width * .75,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
