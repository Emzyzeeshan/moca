import 'dart:io';

import 'package:hive_flutter/adapters.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:mocadb/src/core/utils/routes.dart';
import 'package:mocadb/src/core/utils/shared_preference.dart';
import 'package:mocadb/src/features/dashboard/provider/dashboard_provider.dart';
import 'package:mocadb/src/features/dashboard/provider/map_provider.dart';
import 'package:mocadb/src/features/dashboard/ui/dashboard_screen.dart';
import 'package:mocadb/src/features/login/login_index.dart';
import 'common_imports.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
Future<void> main() async {
  HttpOverrides.global = CustomHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  await LocalStorages.init();

  await Hive.initFlutter();
  var box = await Hive.openBox('moca');

  if(box.get('airports') == null) { // todo - remove || true
    await box.put('airports', []);
    await box.put('airportsImages', []);
    await box.delete('airports');
    await box.delete('airportsImages');

  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ignore: always_specify_types
        providers: [
          ChangeNotifierProvider<LoginProvider>(create: (_) => LoginProvider()),
          ChangeNotifierProvider<DashboardProvider>(
              create: (_) => DashboardProvider()),
          ChangeNotifierProvider<MapProvider>(
              create: (_) => MapProvider()),
          // ChangeNotifierProvider<FeasibilityProvider>(
          //     create: (_) => FeasibilityProvider()),
        ],
        child: SafeArea(
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: NavigateRoutes.navigatorKey,
                theme: ThemeData(
                    scaffoldBackgroundColor: ThemeColors.whiteColor,
                    popupMenuTheme: const PopupMenuThemeData(
                        color: ThemeColors.whiteColor,
                        textStyle: TextStyle(color: ThemeColors.blackColor)),
                    fontFamily: 'RadioCanada'),
                builder: EasyLoading.init(
                  builder: (BuildContext context, Widget? child) {
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: child!,
                    );
                  },
                ),
                 home: const SplashScreen()
            )));
  }
}
