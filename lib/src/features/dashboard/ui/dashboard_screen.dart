import 'package:mocadb/src/core/utils/extension.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/constants/constants_index.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../core/utils/routes.dart';
import '../../../core/utils/shared_preference.dart';
import '../../widgets/custom_icon.dart';
import '../../widgets/custom_text.dart';
import '../../widgets/dotted_divider.dart';
import '../provider/dashboard_provider.dart';
import 'AllAirportsScreen.dart';
import 'IndiaMapWidget.dart';
import 'SavedAirportsScreen.dart';
import 'StateDetailScreen.dart';
import 'filter_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardProvider dashboardProvider;
  int _selectedIndex = 0; // Track selected tab
  late List<Widget> _screens; // Define without initialization

  @override
  void initState() {
    super.initState();
    dashboardProvider = Provider.of(context, listen: false);
    fetchData();
    // Initialize _screens inside initState where context is available
    _screens = [
      IndiaMapWidget(
        onStateSelected: (String state) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StateDetailScreen(stateName: state),
            ),
          );
        },
      ),
      const FilterScreen(), // Second tab - Filters Screen
    ];
  }
  Future<void> fetchData() async {
    EasyLoading.show(status: Constants.loading);
    await dashboardProvider.getAllAirportListApiCall();
    EasyLoading.dismiss();
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (BuildContext context, DashboardProvider provider, _) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: ThemeColors.primaryColor,
              iconTheme: const IconThemeData(color: ThemeColors.whiteColor),
              title: FittedBox(
                child: CustomText(
                  writtenText: Constants.appFullName,
                  textStyle: ThemeTextStyle.style(
                    color: ThemeColors.whiteColor,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.flight),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedAirportsScreen(),
                      ),
                    );
                  },
                ),
              ],

            ),
            drawer: Drawer(
              width: context.width * .6,
              backgroundColor: ThemeColors.whiteColor,
              child: ListView(
                children: <Widget>[
                  Image.asset(
                    Assets.appLogo,
                    fit: BoxFit.fill,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CustomText(
                        writtenText: LocalStorages.getMobileNumber(),
                        textStyle: ThemeTextStyle.style()),
                  ),
                  ListTile(
                    leading: const CustomIcon(icon: Icons.local_airport),
                    title: CustomText(
                        writtenText: Constants.airports,
                        textStyle: ThemeTextStyle.style()),
                    onTap: () async {
                      await NavigateRoutes.navigatePush(widget: const AllAirportsScreen(), context: context, );
                    },
                  ),
                  const DottedDivider(),
                  ListTile(
                    leading: const CustomIcon(icon: Icons.logout),
                    title: CustomText(
                        writtenText: Constants.logOut,
                        textStyle: ThemeTextStyle.style()),
                    onTap: () async {
                      await NavigateRoutes.navigateToLoginScreen(
                          isLogoutTap: true);
                    },
                  ),
                ],
              ),
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'India Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.filter_list),
                  label: 'Filters',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: ThemeColors.primaryColor,
              onTap: _onItemTapped,
            ),
          ),
        );
      },
    );
  }
}
