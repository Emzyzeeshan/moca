import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:mocadb/src/core/utils/print.dart';
import 'package:mocadb/src/datamodel/AirportDetails/cargo_tonnage_model.dart';
import 'package:mocadb/src/datamodel/AirportDetails/departure_schedule_model.dart';
import 'package:mocadb/src/datamodel/groups_Model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/theme/style.dart';
import '../../../datamodel/AirportDetails/airport_details_model.dart';
import '../../../datamodel/AirportDetails/arrival_schedule_model.dart';
import '../../../datamodel/AirportDetails/movement_details_model.dart';
import '../../../datamodel/AirportDetails/passenger_footfall_model.dart';
import '../../../datamodel/airports_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/custom_text.dart';
import '../provider/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class AirportsViewTappedScreen extends StatefulWidget {
  const AirportsViewTappedScreen(
      {required this.data, this.isFromSavedScreen = false, super.key});
  final AllAirportsModel data;
  final bool isFromSavedScreen;

  @override
  _AirportsViewTappedScreenState createState() =>
      _AirportsViewTappedScreenState();
}

class _AirportsViewTappedScreenState extends State<AirportsViewTappedScreen> {
  late DashboardProvider dashboardProvider;
  List<String> imageUrls = [];
  List<GroupsModel> groupsList = [];
  List<bool> expansionStates = [];
  final GlobalKey movementTrendsChartKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<DashboardProvider>(context);

    if (expansionStates.length != provider.groupsList.length) {
      expansionStates = List.generate(
          provider.groupsList.length, (index) => false); // Start collapsed
    }
  }

  bool isOfflineLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

      final mocaBox = await Hive.openBox('moca');
      //final offlineBox = await Hive.openBox('offlineAirports'); // ✅ OPEN THIS FIRST

      final airportCd = widget.data.airportCd ?? '';

      await dashboardProvider.getWorkInProgressApiCall(airportCd: airportCd, box: mocaBox);
      await dashboardProvider.getWorkPlannedApiCall(airportCd: airportCd, box: mocaBox);
      await dashboardProvider.getCompletedWorksApiCall(airportCd: airportCd, box: mocaBox);

      dashboardProvider.airportCode = airportCd;

      fetchData();
      fetchGroupsData();
      fetchAirportDetails();
      setBoxForProvider();
    });
  }


  setBoxForProvider() async {
    var box = await Hive.openBox('moca');
    dashboardProvider.box = box;
  }

  List<Uint8List> imageMemoryList = [];

  Future<void> fetchData() async {
    if (widget.isFromSavedScreen) {
      var box = await Hive.openBox('moca');
      List<dynamic> airports = box.get('airports', defaultValue: []);
      final saved = airports.firstWhere(
          (entry) => entry[0] == widget.data.airportCd,
          orElse: () => null);

      if (saved != null) {
        List<dynamic> savedPaths = saved[1]['airportImagesPaths'] ?? [];

        setState(() {
          imageUrls = List<String>.from(savedPaths);
          imageMemoryList = []; // clear bytes
        });
      }
    } else {
      EasyLoading.show(status: Constants.loading);
      await dashboardProvider.getAllAirportsImagesListApiCall(
        airportCd: widget.data.airportCd.toString(),
      );
      EasyLoading.dismiss();

      setState(() {
        imageUrls = dashboardProvider.allAirportsImagesList;
      });
    }
  }

  Future<Directory> getAppImageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/airport_images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  Future<void> fetchGroupsData() async {
    List<Map<String, dynamic>>? response =
        await dashboardProvider.getGroupsListApiCall();

    if (response != null) {
      setState(() {
        groupsList = response.map((e) => GroupsModel.fromJson(e)).toList();
        groupsList.sort((a, b) => (a.slno ?? 0).compareTo(b.slno ?? 0));

        // Set expansion states based on collapseStatus
        expansionStates =
            groupsList.map((group) => group.collapseStatus == "Y").toList();
      });
    } else {
      print("⚠ Failed to fetch group data.");
    }
  }

  Future<void> fetchAirportDetails() async {
    EasyLoading.show(status: "Loading data..."); // Show loader

    try {
      String airportCode = widget.data.airportCd.toString();

      // Fetch all APIs concurrently
      await Future.wait([
        dashboardProvider.getAirportDetailsListApiCall(airportCd: airportCode),
        dashboardProvider.getPassengerPeakListApiCall(airportCd: airportCode),
        dashboardProvider.getPassengerFootFallListApiCall(
            airportCd: airportCode),
        dashboardProvider.getPassengerMppaListApiCall(airportCd: airportCode),
        dashboardProvider.getConnectivityListApiCall(airportCd: airportCode),
        dashboardProvider.getDestinationListApiCall(airportCd: airportCode),
        dashboardProvider.getRcsConnectivityListApiCall(airportCd: airportCode),
        dashboardProvider.getRCSRouteAndOperatorListApiCall(
            airportCd: airportCode),
        dashboardProvider.getPeakPeriodListApiCall(airportCd: airportCode),
        dashboardProvider.getAveragePerDayFootFallListApiCall(
            airportCd: airportCode),
        dashboardProvider.getCargoCapacityApiCall(airportCd: airportCode),
        dashboardProvider.getCargoOperatorApiCall(airportCd: airportCode),
        dashboardProvider.getApdDetailsApiCall(airportCd: airportCode),
        dashboardProvider.getMovementDetailsListApiCall(airportCd: airportCode),
        dashboardProvider.getCargoTonnageListApiCall(airportCd: airportCode),
        dashboardProvider.getWorkInProgressApiCall(airportCd: airportCode),
        dashboardProvider.getWorkPlannedApiCall(airportCd: airportCode),
        dashboardProvider.getCompletedWorksApiCall(airportCd: airportCode),
        dashboardProvider.getAssistanceRequiredApiCall(airportCd: airportCode),
        dashboardProvider.getGreenInitiativeApiCall(airportCd: airportCode),
        dashboardProvider.getTariffDetialsApiCall(airportCd: airportCode),
        dashboardProvider.getRatingApiCall(airportCd: airportCode),
        dashboardProvider.getTechInitiativeApiCall(airportCd: airportCode),
        dashboardProvider.getOtpArrivalApiCall(airportCd: airportCode),
        dashboardProvider.getOtpDepartureApiCall(airportCd: airportCode),
        dashboardProvider.getProjectInchargeApiCall(airportCd: airportCode),
        dashboardProvider.getArrivalSchedulesListApiCall(
            airportCd: airportCode),
        dashboardProvider.getDepartureSchedulesListApiCall(
            airportCd: airportCode),
      ]);
      setState(() {}); // Update UI after data fetching
    } catch (e) {
      print("❌ Error loading airport details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load airport details!")));
    } finally {
      EasyLoading.dismiss(); // Hide loader
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryColor,
        title: CustomText(
          writtenText: Constants.appFullName,
          textStyle: ThemeTextStyle.style(color: ThemeColors.whiteColor),
        ),
        iconTheme: const IconThemeData(color: ThemeColors.whiteColor),
        actions: widget.isFromSavedScreen
            ? [] // Hide icon if from SavedAirportsScreen
            : [
                IconButton(
                  icon: const Icon(Icons.flight),
                  onPressed: () async {
                    if (dashboardProvider.selectedAirportDetails != null) {
                      final isAlreadySaved = await addToBox(dashboardProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAlreadySaved
                                ? 'Airport is already saved!'
                                : 'Airport saved successfully!'),
                            backgroundColor:
                                isAlreadySaved ? Colors.orange : Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Airport data is still loading!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // Carousel Slider
                    imageUrls.isNotEmpty
                        ? CarouselSlider(
                            options: CarouselOptions(
                              height: 250,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: 16 / 9,
                              enableInfiniteScroll: true,
                              viewportFraction: 0.8,
                            ),
                            items: imageUrls.map((imageUrl) {
                              return buildNetworkImageCard(imageUrl);
                            }).toList(),
                          )
                        : imageMemoryList.isNotEmpty
                            ? CarouselSlider(
                                options: CarouselOptions(
                                    height: 250, autoPlay: true),
                                items: imageMemoryList.map((bytes) {
                                  return buildMemoryImageCard(bytes);
                                }).toList(),
                              )
                            : const Center(child: Text("No images available")),

                    const SizedBox(height: 20),

                    // Expansion Panel List
                    provider.groupsList.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ExpansionPanelList(
                              key: ValueKey(provider.groupsList.length),
                              expansionCallback: (index, isExpanded) {
                                setState(() {
                                  expansionStates[index] =
                                      !expansionStates[index];
                                });
                              },
                              expandedHeaderPadding: EdgeInsets.zero,
                              elevation: 1,
                              children: List.generate(
                                  provider.groupsList.length, (index) {
                                GroupsModel group = provider.groupsList[index];

                                return ExpansionPanel(
                                  backgroundColor: Colors.white,
                                  headerBuilder: (context, isExpanded) {
                                    return Container(
                                      color: ThemeColors.primaryColor,
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Group Heading
                                          Expanded(
                                            child: Text(
                                              group.groupHeading ?? "Unknown",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Last Updated On or Dynamic
                                          Text(
                                            group.lastUpdatedDate != null &&
                                                    group.lastUpdatedDate !=
                                                        "Not Updated"
                                                ? "Last Updated On: ${group.lastUpdatedDate}"
                                                : "Last Updated On: Dynamic",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  body: _buildPanelBody(group, provider),
                                  isExpanded: expansionStates[index],
                                );
                              }),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),

                    const SizedBox(height: 100), // Extra space for FAB
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildNetworkImageCard(String imageUrl) {
    final isLocal = imageUrl.startsWith('/');
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isLocal
            ? Image.file(File(imageUrl),
                fit: BoxFit.cover, width: double.infinity)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                      child: Icon(Icons.broken_image, size: 50));
                },
              ),
      ),
    );
  }

  Widget buildMemoryImageCard(Uint8List bytes) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Future<bool> addToBox(DashboardProvider dashboardProvider) async {
    try {
      EasyLoading.show(status: "Preparing to save...");
      print('📦 addToBox with file saving started');

      final box = await Hive.openBox('moca');
      final List<dynamic> airports = box.get('airports', defaultValue: []);
      final airportCode = widget.data.airportCd ?? '';
      final details = dashboardProvider.selectedAirportDetails!;

      final alreadyExists = airports.any((entry) =>
          entry is List && entry.length > 0 && entry[0] == airportCode);

      if (alreadyExists) {
        print('✅ $airportCode already exists');
        EasyLoading.dismiss();
        return true;
      }

      final imageUrls = dashboardProvider.allAirportsImagesList;
      final List<String> localImagePaths = [];

      for (int i = 0; i < imageUrls.length; i++) {
        final path = await _downloadAndSaveImage(imageUrls[i], airportCode, i);
        if (path != null) localImagePaths.add(path);

        double progress = (i + 1) / imageUrls.length;
        EasyLoading.showProgress(progress,
            status: 'Saving ${((progress) * 100).toInt()}%');
      }

      // 📦 Save airport details and image paths
      final airportDetails = {
        'Airport Details': details.toJson(),
        "Passenger Handling Capacity (Peak Hour)":
            dashboardProvider.selectedPassengerPeak,
        "Passenger Footfall": dashboardProvider.selectedPassengerPeak,
        "Movement Details": dashboardProvider.selectedMovementDetails?.toJson(),
        "Passenger Trends":
            dashboardProvider.selectedPassengerFootfall?.toJson(),
        "Movement Trends": dashboardProvider.selectedMovementDetails?.toJson(),
        "Cargo Tonnage(MT)": dashboardProvider.selectedCargoTonnage?.toJson(),
        "Cargo Trends": dashboardProvider.selectedCargoTonnage?.toJson(),
        "Total Handling Capacity (MPPA)":
            dashboardProvider.selectedPassengerMppa,
        "Connectivity": dashboardProvider.selectedConnectivity,
        "Destinations": dashboardProvider.selectedDestinations,
        "RCS Connectivity": dashboardProvider.selectedRcsConnectivity,
        "RCS Route And Operator": dashboardProvider.selectedRCSRouteAndOperator,
        "Arrival Flight Schedules": dashboardProvider.selectedArrivalSchedules?.toJson(),
        "Departure Flight Schedules": dashboardProvider.selectedDepartureSchedules?.toJson(),
        "Peak Period": dashboardProvider.selectedPeakPeriod,
        "Average Per Day Footfall":
            dashboardProvider.selectedAveragePerDayFootFall,
        "Cargo - Capacity (MTPA)": dashboardProvider.selectedCargoCapacity,
        "Cargo Operator": dashboardProvider.selectedCargoOperator,
        "APD Details": dashboardProvider.selectedApdDetails,
        "Work In Progress": dashboardProvider.workInProgressList,
        "Works Planned": dashboardProvider.workPlannedList,
        "Major Works Completed during Last 5 Years ":
            dashboardProvider.completedWorksList,
        "Assistance Required": dashboardProvider.assistanceRequiredList,
        "Green Initiative": dashboardProvider.selectedGreenInitiative,
        "Tariff Details": dashboardProvider.selectedTariff,
        "Rating": dashboardProvider.selectedRating,
        "Technology Initiative": dashboardProvider.selectedTechInitiative,
        "OTP": dashboardProvider.selectedOtp,
        "Project Incharge": dashboardProvider.selectedProjectIncharge,
        'groupsList':
            dashboardProvider.groupsList.map((g) => g.toJson()).toList(),
        // 'airportImagesPaths': localImagePaths,
      };

      airports.add([airportCode, airportDetails]);
      await box.put('airports', airports);

      EasyLoading.showSuccess("Saved successfully!");
      return false;
    } catch (e, stack) {
      print('❌ Error: $e');
      print(stack);
      EasyLoading.showError("Failed to save offline data.");
      return false;
    }
  }

  Future<String?> _downloadAndSaveImage(
      String imageUrl, String airportCode, int index) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final dir = await getAppImageDirectory();
        final fileName = '$airportCode-$index.jpg';
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
    return null;
  }

  ///Normal U.I  in code
  Widget _buildPanelBody(GroupsModel group, DashboardProvider provider) {
    /*
    box; airports = box.get('airports'); // Array<AirportDetails>;
    newAirportDetails = {
      "Airport Details": provider.selectedAirportDetails.toJson(),
      "Passenger Handling Capacity (Peak Hour)": provider.selectedPassengerPeak.toJson()
     }
     airports.add(newAirportDetails);
     box.put('airports', airports);
     */
    switch (group.groupHeading) {
      case "Airport Details":
        return provider.selectedAirportDetails != null
            ? airportDetailsWidget(provider.selectedAirportDetails!)
            : Container(
                color: ThemeColors.whiteColor,
                child:
                    const Center(child: Text("No airport details available.")));
      case "Passenger Handling Capacity (Peak Hour)":
        return provider.selectedPassengerPeak != null
            ? passengerPeakWidget(provider.selectedPassengerPeak!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No passenger capacity data available.")));
      case "Passenger Footfall":
        return provider.selectedPassengerFootfall != null
            ? passengerFootFallWidget(
                provider.selectedPassengerFootfall!, context)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No passenger footfall data available.")));
      case "Movement Details":
        return provider.selectedMovementDetails != null
            ? movementDetailsWidget(provider.selectedMovementDetails!, context)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Movement Details data available.")));
      case "Passenger Trends":
        return provider.selectedPassengerFootfall != null
            ? passengerTrendsChart(provider.selectedPassengerFootfall!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No passenger Trends data available.")));
      case "Movement Trends":
        return provider.selectedMovementDetails != null
            ? movementTrendsChart(provider.selectedMovementDetails!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No movement Trends data available.")));
      case "Cargo Tonnage(MT)":
        return provider.selectedCargoTonnage != null
            ? cargoTonnageWidget(provider.selectedCargoTonnage!, context)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Cargo Tonnage(MT) data available.")));
      case "Cargo Trends":
        return provider.selectedCargoTonnage != null
            ? cargoTrendsChart(provider.selectedCargoTonnage!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Cargo Trends data available.")));
      case "Total Handling Capacity (MPPA)":
        return provider.selectedPassengerMppa != null
            ? totalHandlingCapacityWidget(provider.selectedPassengerMppa!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Total Handling capacity data available.")));
      case "Connectivity":
        return provider.selectedConnectivity != null
            ? _connectivityWidget(provider.selectedConnectivity!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No connectivity data available.")));
      case "Destinations":
        return provider.selectedDestinations != null
            ? _destinationWidget(provider.selectedDestinations!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No destination data available.")));
      case "RCS Connectivity":
        return provider.selectedRcsConnectivity != null
            ? _rcsConnectivityWidget(provider.selectedRcsConnectivity!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No RCS Connectivity data available.")));
      case "RCS Route And Operator":
        return provider.selectedRCSRouteAndOperator != null
            ? _rcsRouteAndoperatorWidget(provider.selectedRCSRouteAndOperator!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No RCS Route And Operator data available.")));
      case "Arrival Flight Schedules":
        final model = provider.selectedArrivalSchedules;

        if (model == null ||
            model.arrivalSchedules == null ||
            model.arrivalSchedules!.isEmpty) {
          return Container(
            color: ThemeColors.whiteColor,
            child: const Center(
              child: Text("No Arrival Flight Schedules data available."),
            ),
          );
        }

        return _arrivalScheduleWidget(model.arrivalSchedules!);
      case "Departure Flight Schedules":
        final model = provider.selectedDepartureSchedules;

        if (model == null ||
            model.departureSchedules == null ||
            model.departureSchedules!.isEmpty) {
          return Container(
            color: ThemeColors.whiteColor,
            child: const Center(
              child: Text("No Departure Flight Schedules data available."),
            ),
          );
        }

        return _departureScheduleWidget(model.departureSchedules!);

      case "Peak Period":
        return provider.selectedPeakPeriod != null
            ? _peakPeriodWidget(provider.selectedPeakPeriod!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Peak Period data available.")));
      case "Average Per Day Footfall":
        return provider.selectedAveragePerDayFootFall != null
            ? _averagePerDayFootfallWidget(
                provider.selectedAveragePerDayFootFall!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child:
                        Text("No Average Per Day Footfall data available.")));
      case "Cargo - Capacity (MTPA)":
        return provider.selectedCargoCapacity != null
            ? _cargoCapacityWidget(provider.selectedCargoCapacity!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Cargo - Capacity (MTPA) data available.")));
      case "Cargo Operator":
        return provider.selectedCargoOperator != null
            ? _cargoOperatorWidget(provider.selectedCargoOperator!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Cargo Operator data available.")));
      case "APD Details":
        return provider.selectedApdDetails != null
            ? _apdDetailsWidget(provider.selectedApdDetails!)
            : Container(
          color: ThemeColors.whiteColor,
          child: const Center(child: Text("No APD Details data available.")),
        );

      case "Work In Progress":
        return provider.workPlannedList.isNotEmpty
            ? _workInProgressWidget(provider.workInProgressList)
            : Container(
          color: ThemeColors.whiteColor,
          child: const Center(child: Text("No work in progress data available.")),
        );

      case "Works Planned":
        return provider.workPlannedList.isNotEmpty
            ? _workPlannedWidget(provider.workPlannedList)
            : Container(
          color: ThemeColors.whiteColor,
          child: const Center(child: Text("No work planned data available.")),
        );

      case "Major Works Completed during Last 5 Years ":
        return provider.completedWorksList.isNotEmpty
            ? _completedWorksWidget(provider.completedWorksList)
            : Container(
          color: ThemeColors.whiteColor,
          child: const Center(child: Text("No completed works data available.")),
        );

      case "Assistance Required":
        return provider.assistanceRequiredList.isNotEmpty
            ? _assistanceRequiredWidget(provider.assistanceRequiredList)
            : Container(
          color: ThemeColors.whiteColor,
          child: const Center(child: Text("No assistance required data available.")),
        );


      case "Green Initiative":
        // Check if the provider.selectedGreenInitiative is null
        if (provider.selectedGreenInitiative == null) {
          // If data is not available, show a loading indicator or a message
          return Center(
              child:
                  CircularProgressIndicator()); // Show a loading indicator while data is being fetched
        }
        // If data is available, pass it to the _greenInitiativeWidget
        return provider.selectedGreenInitiative!.isEmpty
            ? Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                  child: Text("No Green Initiative data available."),
                ),
              )
            : _greenInitiativeWidget(provider.selectedGreenInitiative!);
      case "Tariff Details":
        if (provider.selectedTariff == null) {
          return Center(child: CircularProgressIndicator());
        }
        return provider.selectedTariff!.isEmpty
            ? Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                  child: Text("No Green Initiative data available."),
                ),
              )
            : _tariffDetailsWidget(provider.selectedTariff!);
      case "Rating":
        if (provider.selectedRating == null) {
          return Center(child: CircularProgressIndicator());
        }
        return provider.selectedRating!.isEmpty
            ? Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                  child: Text("No Rating data available."),
                ),
              )
            : _ratingWidget(provider.selectedRating!);
      case "Technology Initiative":
        if (provider.selectedTechInitiative == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.selectedTechInitiative!.isEmpty) {
          return Container(
            color: ThemeColors.whiteColor,
            child: const Center(
              child: Text("No Technology Initiative data available."),
            ),
          );
        }

        return _technologyInitiativeWidget(provider.selectedTechInitiative!
                .cast<Map<String, dynamic>>() // 🔁 Cast explicitly if needed
            );

      case "OTP":
        final arrivalOtp = provider.combinedOtp?['arrival'] ?? {};
        final departureOtp = provider.combinedOtp?['departure'] ?? {};

        final arrivalData = arrivalOtp['OneTimePerformance'];
        final departureData = departureOtp['OneTimePerformance'];

        final hasArrivalData =
            arrivalData is List && arrivalData.isNotEmpty;
        final hasDepartureData =
            departureData is List && departureData.isNotEmpty;

        if (!hasArrivalData && !hasDepartureData) {
          return Container(
            color: ThemeColors.whiteColor,
            child: const Center(child: Text("No OTP data available.")),
          );
        }

        return otpWidget(arrivalOtp, departureOtp);



      case "Project Incharge":
        return provider.selectedProjectIncharge != null
            ? _projectInchargeWidget(provider.selectedProjectIncharge!)
            : Container(
                color: ThemeColors.whiteColor,
                child: const Center(
                    child: Text("No Project Incharge data available.")));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget airportDetailsWidget(AirportDetailsModel details) {
    List<List<String?>> detailsList = [
      ["Airport Name", details.airportName],
      ["Operated By", details.operatedBy],
      ["Airport Type", details.airportType],
      ["Existing Land (In Acres)", details.existingLandInAcres],
      ["Digi Yatra", details.digiYatra],
      ["MRO", details.mRO],
      ["Intitial Inauguration Date", details.intitialInaugurationDate],
      ["Palanned Inauguration Date", details.palannedInaugurationDate],
      ["Airport Owned By", details.airportOwnedBy],
      ["Watch Hours", details.watchHours],
      ["Night Landing", details.nightLanding],
      [
        "Passenger Terminal Building (Area)",
        details.passengerTerminalBuildingAreaInSqm
      ],
      ["Field Type", details.fieldType],
    ];

    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(
              (detailsList.length / 2).ceil(),
              (index) {
                int leftIndex = index * 2;
                int rightIndex = leftIndex + 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailRow(detailsList[leftIndex][0]!,
                          detailsList[leftIndex][1]),
                    ),
                    if (rightIndex < detailsList.length)
                      Expanded(
                        child: _buildDetailRow(detailsList[rightIndex][0]!,
                            detailsList[rightIndex][1]),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            if (details.runways != null && details.runways!.isNotEmpty) ...[
              const Text(
                "Runways:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.runways!
                    .map((runway) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("- $runway"),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _apdDetailsWidget(Map<String, dynamic> apdDetails) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: apdDetails.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _connectivityWidget(Map<String, dynamic> connectivity) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: connectivity.entries.map((entry) {
            return Row(
              children: [
                Expanded(
                    child: _buildDetailRow(
                        entry.key, entry.value?.toString() ?? " ")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _destinationWidget(Map<String, dynamic> destinations) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: destinations.entries.map((entry) {
            return Row(
              children: [
                Expanded(
                    child: _buildDetailRow(
                        entry.key, entry.value?.toString() ?? " ")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _rcsConnectivityWidget(Map<String, dynamic> rcsConnectivity) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rcsConnectivity.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow(entry.key, entry.value?.toString() ?? " ")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _rcsRouteAndoperatorWidget(Map<String, dynamic> rcsRouteAndOperator) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rcsRouteAndOperator.entries.map((entry) {
            return Row(
              children: [
                Expanded(
                    child: _buildDetailRow(
                        entry.key, entry.value?.toString() ?? " ")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _arrivalScheduleWidget(List<ArrivalSchedules> schedules) {
    final List<PlutoColumn> columns = [
      PlutoColumn(
        title: 'Flight No',
        field: 'flightNumber',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Operator Name',
        field: 'operatorName',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Nature',
        field: 'nature',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Location',
        field: 'location',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
    ];

    final List<PlutoRow> rows = schedules.map((item) {
      return PlutoRow(cells: {
        'flightNumber': PlutoCell(value: item.flightNumber ?? ''),
        'operatorName': PlutoCell(value: item.operatorName ?? ''),
        'nature': PlutoCell(value: item.nature ?? ''),
        'location': PlutoCell(value: item.location ?? ''),
      });
    }).toList();

    return Container(
      color: ThemeColors.whiteColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            key: ValueKey(schedules.hashCode),
            height: 320, // or any height that fits your layout
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              mode: PlutoGridMode.readOnly,
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  columnTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  gridBorderColor: Colors.blue.shade100,
                  enableGridBorderShadow: false,
                ),
              ),
              createFooter: (stateManager) {
                stateManager.setPageSize(5, notify: false);
                return PlutoPagination(stateManager);
              },
              onLoaded: (event) {
                event.stateManager.setPageSize(5, notify: false);
                event.stateManager.setPage(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _departureScheduleWidget(List<DepartureSchedules> schedules) {
    final List<PlutoColumn> columns = [
      PlutoColumn(
        title: 'Flight No',
        field: 'flightNumber',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Operator Name',
        field: 'operatorName',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Nature',
        field: 'nature',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
      PlutoColumn(
        title: 'Location',
        field: 'location',
        type: PlutoColumnType.text(),
        readOnly: true,
      ),
    ];

    final List<PlutoRow> rows = schedules.map((item) {
      return PlutoRow(cells: {
        'flightNumber': PlutoCell(value: item.flightNumber ?? ''),
        'operatorName': PlutoCell(value: item.operatorName ?? ''),
        'nature': PlutoCell(value: item.nature ?? ''),
        'location': PlutoCell(value: item.location ?? ''),
      });
    }).toList();

    return Container(
      color: ThemeColors.whiteColor,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            key: ValueKey(schedules.hashCode),
            height: 320, // or any height that fits your layout
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              mode: PlutoGridMode.readOnly,
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  columnTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  gridBorderColor: Colors.blue.shade100,
                  enableGridBorderShadow: false,
                ),
              ),
              createFooter: (stateManager) {
                stateManager.setPageSize(5, notify: false);
                return PlutoPagination(stateManager);
              },
              onLoaded: (event) {
                event.stateManager.setPageSize(5, notify: false);
                event.stateManager.setPage(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _peakPeriodWidget(Map<String, dynamic> peakPeriod) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: peakPeriod.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _averagePerDayFootfallWidget(
      Map<String, dynamic> averagePerDayFootfall) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: averagePerDayFootfall.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _cargoCapacityWidget(Map<String, dynamic> cargoCapacity) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cargoCapacity.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _workInProgressWidget(List<Map<String, dynamic>> works) {
    if (works.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text("No work items available")),
      );
    }

    String getField(Map<String, dynamic> map, String key) {
      return map.containsKey(key) ? map[key]?.toString() ?? 'N/A' : 'N/A';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            // height: 400,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.blue.shade100),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(400),
                    2: FixedColumnWidth(120),
                    3: FixedColumnWidth(150),
                    4: FixedColumnWidth(150),
                    5: FixedColumnWidth(300),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFB3D9FF)),
                      children: [
                        _tableHeader('S.No'),
                        _tableHeader('Name of Work'),
                        _tableHeader('Cost (Cr)'),
                        _tableHeader('Start Date'),
                        _tableHeader('End Date (PDC)'),
                        _tableHeader('Remarks/Concerns'),
                      ],
                    ),
                    ...works.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final work = entry.value;

                      return TableRow(
                        children: [
                          _tableCell('$index'),
                          _tableCell(getField(work, 'Name of Work')),
                          _tableCell(getField(work, 'Cost (in Cr.)')),
                          _tableCell(getField(work, 'Start Date')),
                          _tableCell(getField(work, 'End Date (PDC)')),
                          _tableCell(getField(work, 'Remarks/Concerns')),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _workPlannedWidget(List<Map<String, dynamic>> workPlanned) {
    if (workPlanned.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text("No work planned items available")),
      );
    }

    String getField(Map<String, dynamic> map, String key) {
      return map.containsKey(key) ? map[key]?.toString() ?? 'N/A' : 'N/A';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.blue.shade100),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(400),
                    2: FixedColumnWidth(120),
                    3: FixedColumnWidth(150),
                    4: FixedColumnWidth(150),
                    5: FixedColumnWidth(300),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFB3D9FF)),
                      children: [
                        _tableHeader('S.No'),
                        _tableHeader('Name of Work'),
                        _tableHeader('Cost (Cr)'),
                        _tableHeader('Start Date'),
                        _tableHeader('End Date (PDC)'),
                        _tableHeader('Remarks/Concerns'),
                      ],
                    ),
                    ...workPlanned.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final workPlanned = entry.value;

                      return TableRow(
                        children: [
                          _tableCell('$index'),
                          _tableCell(getField(workPlanned, 'Name of Work')),
                          _tableCell(getField(workPlanned, 'Cost (in Cr.)')),
                          _tableCell(getField(workPlanned, 'Start Date')),
                          _tableCell(getField(workPlanned, 'End Date (PDC)')),
                          _tableCell(getField(workPlanned, 'Remarks/Concerns')),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _completedWorksWidget(List<Map<String, dynamic>> works) {
    if (works.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text("No completed work items available")),
      );
    }

    String getField(Map<String, dynamic> map, String key) {
      return map.containsKey(key) ? map[key]?.toString() ?? 'N/A' : 'N/A';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.blue.shade100),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(400),
                    2: FixedColumnWidth(120),
                    3: FixedColumnWidth(150),
                    4: FixedColumnWidth(150),
                    5: FixedColumnWidth(300),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFB3D9FF)),
                      children: [
                        _tableHeader('S.No'),
                        _tableHeader('Name of Work'),
                        _tableHeader('Cost (Cr)'),
                        _tableHeader('Start Date'),
                        _tableHeader('End Date'),
                        _tableHeader('Remarks'),
                      ],
                    ),
                    ...works.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final work = entry.value;

                      return TableRow(
                        children: [
                          _tableCell('$index'),
                          _tableCell(getField(work, 'Name of Work')),
                          _tableCell(getField(work, 'Cost (in Cr.)')),
                          _tableCell(getField(work, 'Start Date')),
                          _tableCell(getField(work, 'End Date (PDC)')), // If your data uses different key, change here
                          _tableCell(getField(work, 'Remarks/Concerns')),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _assistanceRequiredWidget(List<Map<String, dynamic>> assistanceList) {
    if (assistanceList.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text("No assistance required items available")),
      );
    }

    String getField(Map<String, dynamic> map, String key) {
      return map.containsKey(key) ? map[key]?.toString() ?? 'N/A' : 'N/A';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.blue.shade100),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(60),     // S.No
                    1: FixedColumnWidth(200),    // PMG
                    2: FixedColumnWidth(350),    // Assistance Required
                    3: FixedColumnWidth(450),    // Assistance Required From
                    4: FixedColumnWidth(450),    // Remarks
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFB3D9FF)),
                      children: [
                        _tableHeader('S.No'),
                        _tableHeader('Assistance Required'),
                        _tableHeader('From'),
                        _tableHeader('Remarks'),
                        _tableHeader('PMG (Y/N)'),
                      ],
                    ),
                    // Data Rows
                    ...assistanceList.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final row = entry.value;

                      return TableRow(
                        children: [
                          _tableCell('$index'),
                          _tableCell(getField(row, 'Assistance Required')),
                          _tableCell(getField(row, 'Assistance Required from')),
                          _tableCell(getField(row, 'Remarks')),
                          _tableCell(getField(row, 'Issue marked in PMG (Y/N)')),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _greenInitiativeWidget(Map<String, dynamic>? greenInitiative) {
    const defaultPlaceholder = "-";

    String getValue(String section, String key) {
      // Print the entire greenInitiative map to see its structure

      final sectionMap = greenInitiative?[section];

      // Print the keys in greenInitiative to check if the section exists

      if (sectionMap == null) {
        return defaultPlaceholder;
      }

      // Print the section map to check its content

      if (sectionMap is Map<String, dynamic>) {
        var value = sectionMap[key]?.toString();
        return value ?? defaultPlaceholder;
      }

      return defaultPlaceholder;
    }

    // Section title widget
    Widget _sectionTitle(String title) => Container(
          width: 1800,
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade800,
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );

    // Table row helper widget
    TableRow _tableRow(List<Widget> children) => TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: children,
        );

    // Table row with blue background for headings
    TableRow _blueRow(List<String> texts) => TableRow(
          decoration: BoxDecoration(color: Colors.blue.shade100),
          children: texts
              .map((text) => Center(
                  child: Text(text,
                      style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Energy Procurement Table
          _sectionTitle('Details of Energy procurement and consumption'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(300),
              2: FixedColumnWidth(180),
              3: FixedColumnWidth(180),
              4: FixedColumnWidth(180),
              5: FixedColumnWidth(180),
              6: FixedColumnWidth(180),
              7: FixedColumnWidth(180),
              8: FixedColumnWidth(180),
              9: FixedColumnWidth(180),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.blue.shade100),
                children: const [
                  Center(
                      child: Text("Source",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Center(
                      child: Text("Renewable Energy",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(),
                  SizedBox(),
                  Center(
                      child: Text("Conventional Energy",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(),
                  Center(
                      child: Text(
                          "Total energy\nconsumption\n(in Million units)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Center(
                      child: Text("Average per unit\ncost (in INR)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Center(
                      child: Text(
                          "% of energy consumption\nfrom renewable source",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Center(
                      child: Text(
                          "% of energy consumption\nfrom non- renewable source",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.blue.shade100),
                children: const [
                  SizedBox(),
                  Center(
                      child: Text(
                          "Installed capacity (in Mw)\nOn-site   Off-site   Total",
                          textAlign: TextAlign.center)),
                  Center(
                      child: Text(
                          "Consumption from\nRenewable Source\n(in Million Units)",
                          textAlign: TextAlign.center)),
                  Center(
                      child: Text("Per unit cost\n(in INR)",
                          textAlign: TextAlign.center)),
                  Center(
                      child: Text(
                          "Consumption from\nConventional Source\n(in Million Units)",
                          textAlign: TextAlign.center)),
                  Center(
                      child: Text("Per unit cost\n(in INR)",
                          textAlign: TextAlign.center)),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                ],
              ),
              _tableRow([
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'Source'))),
                Center(
                    child: Text(
                        "${getValue('Details of Energy procurement and consumption', 'On-site')}   ${getValue('Details of Energy procurement and consumption', 'Off-site')}   ${getValue('Details of Energy procurement and consumption', 'Total')}")),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'Consumption from Renewable Source'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'RenewablePerUnitCost'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'Consumption from Conventional Source'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'ConventionalPerUnitCost'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'Total energy consumption'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        'AvgPerUnitCost'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        '% of energy consumption from renewable source'))),
                Center(
                    child: Text(getValue(
                        'Details of Energy procurement and consumption',
                        '% of energy consumption from non- renewable source'))),
              ]),
            ],
          ),
          const SizedBox(height: 20),

          // Net Metering Table
          _sectionTitle('Net Metering'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(300),
              1: FixedColumnWidth(600),
            },
            children: [
              _blueRow(["Whether Net Metered Yes/No", "If Yes"]),
              _tableRow([
                Center(child: Text(getValue('Net Metering', 'NetMeterStatus'))),
                Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: Text(
                                "Sanctioned Capacity of Net metering (in Mw)\n${getValue('Net Metering', 'SanctionCapacity')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "Allowed upto how much Million Units\n${getValue('Net Metering', 'AllowedUpto')}"))),
                  ],
                )
              ]),
            ],
          ),
          const SizedBox(height: 20),

          // Status of achieving Carbon Neutrality
          _sectionTitle('Status of achieving Carbon Neutrality'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(200),
              1: FixedColumnWidth(180),
              2: FixedColumnWidth(600),
            },
            children: [
              _blueRow([
                "Steps taken for achieving Carbon Neutrality",
                "Achieved Net Zero (Y/N)",
                "If Yes"
              ]),
              _tableRow([
                Center(
                    child: Text(getValue(
                        'Status of achieveing Carbon Neutrality',
                        'Steps taken for achieving Carbon Neutrality'))),
                Center(
                    child: Text(getValue(
                        'Status of achieveing Carbon Neutrality',
                        'Achieved Net Zero'))),
                Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: Text(
                                "Target Date to achieve\n${getValue('Status of achieveing Carbon Neutrality', 'Target Date to achieve')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "PERT Chart\n${getValue('Status of achieveing Carbon Neutrality', 'PertChart')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "Remarks\n${getValue('Status of achieveing Carbon Neutrality', 'Remarks')}"))),
                  ],
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),

          // Status of achieving Net Zero
          _sectionTitle('Status of achieving Net Zero'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(200),
              1: FixedColumnWidth(180),
              2: FixedColumnWidth(600),
            },
            children: [
              _blueRow([
                "Steps taken for achieving Net Zero",
                "Achieved Net Zero (Y/N)",
                "If Yes"
              ]),
              _tableRow([
                Center(
                    child: Text(getValue('Status of achieveing Net Zero',
                        'Steps taken for achieving Net Zero'))),
                Center(
                    child: Text(getValue(
                        'Status of achieveing Net Zero', 'Achieved Net Zero'))),
                Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: Text(
                                "Target Date to achieve\n${getValue('Status of achieveing Net Zero', 'Target Date to achieve')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "PERT Chart\n${getValue('Status of achieveing Net Zero', 'PertChart')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "Remarks\n${getValue('Status of achieveing Net Zero', 'Remarks')}"))),
                  ],
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),

          // Sewage Treatment Plant Details
          _sectionTitle('Sewage Treatment Plant Details'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(250),
              1: FixedColumnWidth(750),
            },
            children: [
              _blueRow(["", "Work in Progress/Planned"]),
              _tableRow([
                const Center(child: Text("Work in Progress")),
                Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: Text(
                                "Installed sewage treatment capacity (KLD)\n${getValue('Sewage Treatment Plant Details', 'Installed sewage treatment capacity (KLD)')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "STP installation (KLD)\n${getValue('Sewage Treatment Plant Details', 'STP installation (KLD)')}"))),
                    Expanded(
                        child: Center(
                            child: Text(
                                "Target date to achieve\n${getValue('Sewage Treatment Plant Details', 'Target date to achieve')}"))),
                  ],
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),

          // Installation of LED lights details
          _sectionTitle('Installation of LED lights details'),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FixedColumnWidth(300),
              1: FixedColumnWidth(300),
            },
            children: [
              _blueRow([
                "No. of Non-LED lights installed",
                "No. of LED lights installed"
              ]),
              _tableRow([
                Center(
                    child: Text(getValue('Installation of LED lights details',
                        'No. of Non-LED lights installed'))),
                Center(
                    child: Text(getValue('Installation of LED lights details',
                        'No. of LED lights installed'))),
              ]),
            ],
          ),
        ],
      ),
    );
  }
  Widget _tariffDetailsWidget(Map<String, dynamic>? tariffDetails) {
    final udfDetails = tariffDetails?['UDF Charges Details'] ?? {};
    final airportType =
        udfDetails['Whether Major or Non-Major Airport as per AERA Act'] ??
            'NA';
    final List<String> years = [
      '2024-2025',
      '2025-2026',
      '2026-2027',
      '2027-2028',
      '2028-2029'
    ];

    return Column(
      children: [
        // Container(
        //   margin: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     border: Border.all(color: Colors.blue.shade800, width: 2),
        //   ),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.stretch,
        //     children: [
        //       Container(
        //         color: Colors.blue.shade800,
        //         padding: const EdgeInsets.all(12.0),
        //         child: const Text(
        //           'UDF Charge Details',
        //           style: TextStyle(
        //             color: Colors.white,
        //             fontWeight: FontWeight.bold,
        //             fontSize: 16,
        //           ),
        //         ),
        //       ),
        //       SingleChildScrollView(
        //         scrollDirection: Axis.horizontal,
        //         child: Table(
        //           defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        //           border: TableBorder.all(color: Colors.blue.shade100),
        //           columnWidths: {
        //             0: FixedColumnWidth(280),
        //             for (int i = 1; i <= years.length; i++) i: FixedColumnWidth(160),
        //           },
        //           children: [
        //             // Main Header Row
        //             TableRow(
        //               decoration: BoxDecoration(color: Colors.blue.shade100),
        //               children: [
        //                 const Padding(
        //                   padding: EdgeInsets.all(12.0),
        //                   child: Text(
        //                     'Whether Major or Non-Major Airport as per AERA Act',
        //                     style: TextStyle(fontWeight: FontWeight.bold),
        //                   ),
        //                 ),
        //                 Padding(
        //                   padding: const EdgeInsets.all(12.0),
        //                   child: Text(
        //                     'Applicable UDF Charges for FY in INR (If not determined, pl indicate as NA)',
        //                     textAlign: TextAlign.center,
        //                     style: const TextStyle(fontWeight: FontWeight.bold),
        //                   ),
        //                 ),
        //                 ...List.filled(years.length - 1, const SizedBox()),
        //               ],
        //             ),
        //
        //             // Year Headers
        //             TableRow(
        //               decoration: BoxDecoration(color: Colors.blue.shade100),
        //               children: [
        //                 const SizedBox(),
        //                 ...years.map(
        //                       (year) => Padding(
        //                     padding: const EdgeInsets.all(8.0),
        //                     child: Center(
        //                       child: Text(
        //                         year.replaceAll('-', '–'),
        //                         style: const TextStyle(fontWeight: FontWeight.bold),
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //
        //             // Data Row
        //             TableRow(
        //               children: [
        //                 Padding(
        //                   padding: const EdgeInsets.all(12.0),
        //                   child: Text(airportType),
        //                 ),
        //                 ...years.map((year) {
        //                   final yearCharges = udfDetails[year];
        //                   final domestic = yearCharges?['Domestic'] ?? 'NA';
        //                   final international = yearCharges?['International'] ?? 'NA';
        //                   return Padding(
        //                     padding: const EdgeInsets.all(12.0),
        //                     child: Text('Domestic: $domestic\nInternational: $international'),
        //                   );
        //                 }).toList(),
        //               ],
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        // You can now pass `tariffDetails` into landing and parking widgets too:
        _udfChargeDetailsWidget(tariffDetails),
        _landingChargeDetailsWidget(tariffDetails),
        _parkingChargeDetailsTable(tariffDetails),
      ],
    );
  }
  Widget _udfChargeDetailsWidget(Map<String, dynamic>? tariffDetails) {
    final udfData =
        tariffDetails?['UDF Charges Details'] as Map<String, dynamic>?;

    final List<String> years = [
      '2024-2025',
      '2025-2026',
      '2026-2027',
      '2027-2028',
      '2028-2029'
    ];

    final String airportType =
        udfData?['Whether Major or Non-Major Airport as per AERA Act'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Container(
            color: Colors.blue.shade800,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'UDF Charge Details',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),

          // Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.blue.shade100),
              columnWidths: {
                0: const FixedColumnWidth(300),
                for (int i = 0; i < years.length; i++)
                  i + 1: const FixedColumnWidth(150),
              },
              children: [
                // Grouped Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Whether Major or Non-Major Airport as per AERA Act',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        color: Colors.blue.shade100,
                        child: const Text(
                          'Applicable UDF Charges for FY in INR (If not determined, pl indicate as NA)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    for (int i = 0; i < years.length - 1; i++) const SizedBox(),
                  ],
                ),

                // Year Headers
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade50),
                  children: [
                    const SizedBox(),
                    ...years.map(
                      (year) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            year.replaceAll('-', '–'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Data Row
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(airportType),
                    ),
                    ...years.map((year) {
                      final dynamic value = udfData?[year];

                      // Safely cast only if value is a Map<String, dynamic>
                      final charges = value is Map<String, dynamic> ? value : null;

                      if (charges == null ||
                          (charges['Domestic'] == 'N/A' && charges['International'] == 'N/A')) {
                        return const Center(child: Text('NA'));
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Domestic: ${charges['Domestic'] ?? 'NA'}'),
                            const SizedBox(height: 4),
                            Text('International: ${charges['International'] ?? 'NA'}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                )

              ],
            ),
          ),
        ],
      ),
    );
  }
  Map<String, List<List<String>>?> getParkingChargeYearlyRates(
      Map<String, dynamic>? tariffDetails) {
    final Map<String, List<List<String>>?> data = {};
    if (tariffDetails == null) return data;

    final parkingDetails = tariffDetails['Parking Charge Details'];
    if (parkingDetails == null) return data;

    for (String type in ['International', 'Domestic']) {
      final charges = parkingDetails[type] as Map<String, dynamic>?;

      charges?.forEach((year, list) {
        final parsedList = (list as List<dynamic>).map<List<String>>((item) {
          return [
            item['AUWFROM'].toString(),
            item['AUWTO'].toString(),
            item['BASE'].toString(),
            item['RATE'].toString(),
            item['FLATRATE'].toString()
          ];
        }).toList();

        data['$year-$type'] = parsedList;
      });
    }

    return data;
  }

  Widget _parkingChargeDetailsTable(Map<String, dynamic>? tariffDetails) {
    final List<String> years = [
      '2024-2025',
      '2025-2026',
      '2026-2027',
      '2027-2028',
      '2028-2029'
    ];
    final data = getParkingChargeYearlyRates(tariffDetails);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.blue.shade800,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Parking Charge Details',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.shade100,
                      child: const Text(
                        'Whether Major or Non-Major Airport as per AERA Act',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      color: Colors.blue.shade100,
                      width: years.length * 200,
                      child: const Text(
                        'Applicable Parking Charges for FY in INR (If not determined, pl indicate as NA)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 250, color: Colors.blue.shade50),
                    ...years.map((year) => Container(
                          width: 200,
                          padding: const EdgeInsets.all(8),
                          color: Colors.blue.shade50,
                          child: Center(
                              child: Text(year,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                        )),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(12),
                      child: const Text('Major Airport'),
                    ),
                    ...years.map((year) {
                      final intl = data['$year-International'];
                      final dom = data['$year-Domestic'];

                      return Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            const Text('International:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            intl != null
                                ? _rateTable(rates: intl)
                                : const Text('NA'),
                            const SizedBox(height: 8),
                            const Text('Domestic:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            dom != null
                                ? _rateTable(rates: dom)
                                : const Text('NA'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<List<String>>? extractLandingCharges({
    required Map<String, dynamic> tariffDetails,
    required String year,
    required String type, // 'International' or 'Domestic'
  }) {
    final details = tariffDetails['Landing Charges Details']?[type]?[year];
    if (details == null || details is! List) return null;

    return (details as List).map<List<String>>((item) {
      return [
        item['AUWFROM'].toString(),
        item['AUWTO'].toString(),
        item['BASE'].toString(),
        item['RATE'].toString(),
        item['FLATRATE'].toString(),
      ];
    }).toList();
  }

  Widget _landingChargeDetailsWidget(Map<String, dynamic>? tariffDetails) {
    final List<String> years = [
      '2024-2025',
      '2025-2026',
      '2026-2027',
      '2027-2028',
      '2028-2029'
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.blue.shade800,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Landing Charge Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.blue.shade100),
              columnWidths: {
                0: const FixedColumnWidth(300),
                for (int i = 0; i < years.length; i++)
                  i + 1: const FixedColumnWidth(200),
              },
              children: [
                // Grouped header
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Whether Major or Non-Major Airport as per AERA Act',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        color: Colors.blue.shade100,
                        child: Text(
                          'Applicable Landing Charges for FY in INR (If not determined, pl indicate as NA)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    for (int i = 0; i < years.length - 1; i++) const SizedBox(),
                  ],
                ),

                // Year row
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue.shade100),
                  children: [
                    const SizedBox(),
                    ...years
                        .map((y) => Center(child: Text(y.replaceAll('-', '–'))))
                        .toList(),
                  ],
                ),

                // Data row for Major Airport
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Major Airport'),
                    ),
                    ...years.map((year) {
                      final intl = extractLandingCharges(
                            tariffDetails: tariffDetails!,
                            year: year,
                            type: 'International',
                          ) ??
                          [];
                      final dom = extractLandingCharges(
                            tariffDetails: tariffDetails,
                            year: year,
                            type: 'Domestic',
                          ) ??
                          [];

                      if (intl.isEmpty && dom.isEmpty) {
                        return const Center(child: Text('NA'));
                      }

                      return _yearlyChargeColumn(
                        intlRates: intl,
                        domRates: dom,
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearlyChargeColumn({
    required List<List<String>> intlRates,
    required List<List<String>> domRates,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('International:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _rateTable(rates: intlRates),
          const SizedBox(height: 12),
          const Text('Domestic:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _rateTable(rates: domRates),
        ],
      ),
    );
  }

  Widget _rateTable({required List<List<String>> rates}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grouped Headers Row
        Row(
          children: [
            _headerGroup('S.No', flex: 1),
            _headerGroup('Weight of Aircraft (Kgs)', flex: 2),
            _headerGroup('Rates (Rs)', flex: 2),
            _headerGroup('Flat Rates (Rs)', flex: 1),
          ],
        ),

        // Sub-Headers Row
        const SizedBox(height: 4),
        Row(
          children: [
            _subHeader(''),
            _subHeader('From Range'),
            _subHeader('To Range'),
            _subHeader('Base range'),
            _subHeader('Rate Per 1000 Kg'),
            _subHeader(''),
          ],
        ),

        const SizedBox(height: 4),

        // Data Rows
        for (int i = 0; i < rates.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                _dataCell((i + 1).toString()),
                _dataCell(rates[i][0]),
                _dataCell(rates[i][1]),
                _dataCell(rates[i][2]),
                _dataCell(rates[i][3]),
                _dataCell(rates[i][4]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _headerGroup(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _subHeader(String text) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _ratingWidget(Map<String, dynamic> rating) {
    final aci = rating[
            'Airports Council International - Airport Service Quality (ACI-ASQ) Survey'] ??
        {};
    final css = rating['Customer Satisfaction Survey (CSS)'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Title Row

        // ACI-ASQ Header
        Container(
          color: const Color(0xFF005BAC),
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: const Text(
            'Airports Council International – Airport Service Quality (ACI-ASQ) Survey',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        // ACI-ASQ Sub-header
        Container(
          color: const Color(0xFF99CCFF),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const Center(
            child: Text(
              'ASQ Rating of ACI–ASQ Survey',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // ACI-ASQ Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FixedColumnWidth(200),
              1: FixedColumnWidth(220),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(100),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
              6: FixedColumnWidth(130),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: const Color(0xFFB3D9FF)),
                children: [
                  _tableHeader('Name of the Airport'),
                  _tableHeader('Airport Category'),
                  _tableHeader('Year'),
                  _tableHeader('ASQ Rating'),
                  _tableHeader('Rank'),
                  _tableHeader('Difference in ASQ Rating'),
                  _tableHeader('Difference in ASQ Rating over MOU Target'),
                ],
              ),
              TableRow(
                children: [
                  _tableCell(aci['Airport Name'] ?? 'N/A'),
                  _tableCell(aci['Airport Category'] ?? 'N/A'),
                  _tableCell(aci['Year']?.toString() ?? 'N/A'),
                  _tableCell('${aci['ASQ Rating'] ?? 'N/A'}'),
                  _tableCell('${aci['Rank'] ?? 'N/A'}'),
                  _tableCell(
                      '${aci['Difference in ASQ Rating'] ?? 'N/A'}'), // ✅ NEW
                  _tableCell(
                      '${aci['Difference in ASQ Rating over MOU Target'] ?? 'N/A'}'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // CSS Section Header
        Container(
          color: const Color(0xFF005BAC),
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: const Text(
            'Customer Satisfaction Survey (CSS)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        // CSS Sub-header
        Container(
          color: const Color(0xFF99CCFF),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const Center(
            child: Text(
              'Customer Satisfaction Index of Airports for Round vis-a-vis Round - II',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // CSS Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FixedColumnWidth(80),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(200),
              3: FixedColumnWidth(100),
              4: FixedColumnWidth(250),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: const Color(0xFFB3D9FF)),
                children: [
                  _tableHeader('Rank'),
                  _tableHeader('Year'),
                  _tableHeader('Customer Satisfaction Index'),
                  _tableHeader('Round'),
                  _tableHeader('Difference between Round - I and Round - II'),
                ],
              ),
              TableRow(
                children: [
                  _tableCell('${css['Rank'] ?? 'N/A'}'),
                  _tableCell('${css['Year'] ?? 'N/A'}'),
                  _tableCell('${css['Rating'] ?? 'N/A'}'),
                  _tableCell(
                      '${css['Customer Satisfaction Index Round'] ?? 'N/A'}'),
                  _tableCell(
                      '${css['Difference between Round - I and Round - II'] ?? 'N/A'}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _technologyInitiativeWidget(List<Map<String, dynamic>> initiatives) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: Colors.blue.shade100),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(60),
                1: FixedColumnWidth(300),
                2: FixedColumnWidth(320),
                3: FixedColumnWidth(150),
                4: FixedColumnWidth(300),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFB3D9FF)),
                  children: [
                    _tableHeader('SL No'),
                    _tableHeader('Technology Initiative'),
                    _tableHeader('Benefits'),
                    _tableHeader('Date of Completion / PDC'),
                    _tableHeader('Remarks'),
                  ],
                ),

                // Data Rows
                ...initiatives.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return TableRow(
                    children: [
                      _tableCell('$index'),
                      _tableCell(item['Technology Initiative'] ?? ''),
                      _tableCell(item['Benefits'] ?? ''),
                      _tableCell(item['Date of Completion / PDC'] ?? ''),
                      _tableCell(item['Remarks'] ?? ''),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );

  Widget _tableCell(String value) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(value, textAlign: TextAlign.left),
      );

  Widget otpWidget(
      Map<String, dynamic> arrivalOtp, Map<String, dynamic> departureOtp) {
    return SizedBox(
        height: 600,
        child: _OtpChart(arrivalOtp: arrivalOtp, departureOtp: departureOtp));
  }

  Widget _projectInchargeWidget(Map<String, dynamic> projectInCharge) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: projectInCharge.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " ",
                    showTitle: true),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _cargoOperatorWidget(Map<String, dynamic> cargoOperator) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cargoOperator.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget passengerPeakWidget(Map<String, dynamic>? passengerPeak) {
    if (passengerPeak == null || passengerPeak.isEmpty) {
      return const Center(child: Text("No passenger capacity data available."));
    }

    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: passengerPeak.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget totalHandlingCapacityWidget(Map<String, dynamic>? passengerMppa) {
    if (passengerMppa == null || passengerMppa.isEmpty) {
      return const Center(child: Text("No passenger capacity data available."));
    }

    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: passengerMppa.entries.map((entry) {
            return Row(
              children: [
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget passengerFootFallWidget(
      PassengerFootFallModel? passengerFootfall, BuildContext context) {
    if (passengerFootfall == null ||
        passengerFootfall.financialData == null ||
        passengerFootfall.financialData!.isEmpty) {
      return const Center(child: Text("No passenger footfall data available."));
    }

    return Container(
      color: ThemeColors.whiteColor,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              children: [
                _buildHeaderCell("Financial Year"),
                _buildHeaderCell("Domestic"),
                _buildHeaderCell("International"),
                _buildHeaderCell("Total"),
              ],
            ),
            // Data rows
            ...passengerFootfall.financialData!.map((financial) {
              return TableRow(
                children: [
                  _buildDataCell(financial.financialYear),
                  _buildDataCell(financial.domestic?.toString()),
                  _buildDataCell(financial.international?.toString()),
                  _buildDataCell(financial.total?.toString()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

// Helper method for header cell
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

// Helper method for data cell
  Widget _buildDataCell(String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Center(
        child: Text(
          text ?? '-',
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  GlobalKey chartKey = GlobalKey();
  Widget passengerTrendsChart(PassengerFootFallModel? passengerFootfall) {
    if (passengerFootfall?.financialData == null ||
        passengerFootfall!.financialData!.isEmpty) {
      return const Center(child: Text("No passenger footfall data available."));
    }

    List<ChartData> chartData =
        passengerFootfall.financialData!.map((financial) {
      return ChartData(
        financial.financialYear,
        financial.domestic?.toDouble() ?? 0.0,
        financial.international?.toDouble() ?? 0.0,
      );
    }).toList();

    return RepaintBoundary(
      key: chartKey, // Key to capture image
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: SfCartesianChart(
          title: ChartTitle(text: 'Passenger Trends'),
          legend: Legend(isVisible: true, position: LegendPosition.bottom),
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(
            numberFormat: NumberFormat.compact(),
          ),
          series: <CartesianSeries<ChartData, String>>[
            LineSeries<ChartData, String>(
              name: 'Domestic',
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.year,
              yValueMapper: (ChartData data, _) => data.domestic,
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.orange,
            ),
            LineSeries<ChartData, String>(
              name: 'International',
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.year,
              yValueMapper: (ChartData data, _) => data.international,
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget movementDetailsWidget(
      MovemenetDetailsModel? movementDetails, BuildContext context) {
    if (movementDetails == null ||
        movementDetails.financialData == null ||
        movementDetails.financialData!.isEmpty) {
      return const Center(child: Text("No Movement Details data available."));
    }

    return Container(
      color: ThemeColors.whiteColor,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              children: [
                _buildHeaderCell("Financial Year"),
                _buildHeaderCell("Domestic"),
                _buildHeaderCell("International"),
                _buildHeaderCell("Total"),
              ],
            ),
            ...movementDetails.financialData!.map((financial) {
              return TableRow(
                children: [
                  _buildDataCell(financial.financialYear),
                  _buildDataCell(financial.domestic?.toString()),
                  _buildDataCell(financial.international?.toString()),
                  _buildDataCell(financial.total?.toString()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget movementTrendsChart(MovemenetDetailsModel? movementTrends) {
    if (movementTrends?.financialData == null ||
        movementTrends!.financialData!.isEmpty) {
      return const Center(child: Text("No movement Trends available."));
    }

    List<ChartData> chartData = movementTrends.financialData!.map((financial) {
      return ChartData(
          financial.financialYear.toString(),
          financial.domestic?.toDouble() ?? 0.0,
          financial.international?.toDouble() ?? 0.0);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Movement Trends'),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat
              .compact(), // Converts big numbers into readable format (e.g., 1K, 10K)
          //title: AxisTitle(text: "Mo (approx)"),
        ),
        series: <CartesianSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            name: 'Domestic',
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.year,
            yValueMapper: (ChartData data, _) => data.domestic,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.orange,
          ),
          LineSeries<ChartData, String>(
            name: 'International',
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.year,
            yValueMapper: (ChartData data, _) => data.international,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget cargoTonnageWidget(
      CargoTonnageModel? cargoTonnage, BuildContext context) {
    if (cargoTonnage == null ||
        cargoTonnage.financialData == null ||
        cargoTonnage.financialData!.isEmpty) {
      return const Center(child: Text("No Cargo Tonnage data available."));
    }

    return Container(
      color: ThemeColors.whiteColor,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              children: [
                _buildHeaderCell("Financial Year"),
                _buildHeaderCell("Domestic"),
                _buildHeaderCell("International"),
                _buildHeaderCell("Total"),
              ],
            ),
            ...cargoTonnage.financialData!.map((financial) {
              return TableRow(
                children: [
                  _buildDataCell(financial.financialYear),
                  _buildDataCell(financial.domestic?.toString()),
                  _buildDataCell(financial.international?.toString()),
                  _buildDataCell(financial.total?.toString()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget cargoTrendsChart(CargoTonnageModel? cargoTrends) {
    if (cargoTrends?.financialData == null ||
        cargoTrends!.financialData!.isEmpty) {
      return const Center(child: Text("No movement Trends available."));
    }

    List<ChartData> chartData = cargoTrends.financialData!.map((financial) {
      return ChartData(
          financial.financialYear.toString(),
          financial.domestic?.toDouble() ?? 0.0,
          financial.international?.toDouble() ?? 0.0);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Cargo Trends'),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat
              .compact(), // Converts big numbers into readable format (e.g., 1K, 10K)
          //title: AxisTitle(text: "Mo (approx)"),
        ),
        series: <CartesianSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            name: 'Domestic',
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.year,
            yValueMapper: (ChartData data, _) => data.domestic,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.orange,
          ),
          LineSeries<ChartData, String>(
            name: 'International',
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.year,
            yValueMapper: (ChartData data, _) => data.international,
            markerSettings: const MarkerSettings(isVisible: true),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value, {bool showTitle = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: RichText(
        text: TextSpan(
          text: showTitle
              ? "$title: "
              : "", // Show title only if showTitle is true
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value ?? " ",
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String year;
  final double domestic;
  final double international;

  ChartData(this.year, this.domestic, this.international);
}

class GroupedChartData {
  final String operatorCd;
  final double onTime;
  final double above15;
  final double above30;

  GroupedChartData({
    required this.operatorCd,
    required this.onTime,
    required this.above15,
    required this.above30,
  });

  factory GroupedChartData.fromJson(Map<String, dynamic> json) {
    return GroupedChartData(
      operatorCd: json['operatorCd'] ?? '',
      onTime: double.tryParse(json['ontimeFlights'].toString()) ?? 0.0,
      above15: double.tryParse(json['above15'].toString()) ?? 0.0,
      above30: double.tryParse(json['above30'].toString()) ?? 0.0,
    );
  }
}

class _OtpChart extends StatefulWidget {
  final Map<String, dynamic> arrivalOtp;
  final Map<String, dynamic> departureOtp;

  const _OtpChart({
    required this.arrivalOtp,
    required this.departureOtp,
  });

  @override
  State<_OtpChart> createState() => _OtpChartState();
}

class _OtpChartState extends State<_OtpChart> {
  bool showArrival = true;

  @override
  Widget build(BuildContext context) {
    final rawData = showArrival
        ? widget.arrivalOtp['OneTimePerformance'] ?? []
        : widget.departureOtp['OneTimePerformance'] ?? [];

    final chartData = _parseChartData(rawData);
    final categories = ['On Time', 'Deviation 16–29 Min', 'Deviation 30+ Min'];

    final List<CartesianSeries<_ChartData, String>> seriesList = categories.map(
      (category) {
        final data = chartData.where((e) => e.category == category).toList();

        return BarSeries<_ChartData, String>(
          name: category,
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.operator,
          yValueMapper: (_ChartData data, _) => data.value,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        );
      },
    ).toList();

    return Column(
      children: [
        ToggleButtons(
          isSelected: [showArrival, !showArrival],
          onPressed: (index) {
            setState(() {
              showArrival = index == 0;
              // Debug log to verify switch
              debugPrint(
                  '🔄 Switched to ${showArrival ? "Arrival" : "Departure"}');

              final selectedData = showArrival
                  ? widget.arrivalOtp['OneTimePerformance']
                  : widget.departureOtp['OneTimePerformance'];

              debugPrint(
                  '📊 Raw ${showArrival ? "Arrival" : "Departure"} Data: $selectedData');
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Arrival'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Departure'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Builder(
            builder: (context) {
              final rawData = showArrival
                  ? widget.arrivalOtp['OneTimePerformance'] ?? []
                  : widget.departureOtp['OneTimePerformance'] ?? [];

              final chartData = _parseChartData(rawData);
              final categories = [
                'On Time',
                'Deviation 16–29 Min',
                'Deviation 30+ Min'
              ];

              final seriesList = categories.map((category) {
                final data =
                    chartData.where((e) => e.category == category).toList();
                Color color;
                switch (category) {
                  case 'On Time':
                    color = const Color(0xFF2CA02C); // green
                    break;
                  case 'Deviation 16–29 Min':
                    color = const Color(0xFFFFEB3B); // yellow
                    break;
                  case 'Deviation 30+ Min':
                    color = const Color(0xFFEF5350); // red
                    break;
                  default:
                    color = Colors.grey;
                }

                return BarSeries<_ChartData, String>(
                  name: category,
                  dataSource: data,
                  xValueMapper: (_ChartData data, _) => data.operator,
                  yValueMapper: (_ChartData data, _) => data.value,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  color: color,
                );
              }).toList();

              return SfCartesianChart(
                title: ChartTitle(
                  text:
                      'One Time Performance - ${showArrival ? 'Arrival' : 'Departure'}',
                  alignment: ChartAlignment.near,
                ),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Airline'),
                  labelPlacement: LabelPlacement.betweenTicks,
                  labelRotation: -90, // Slants text for better fit
                  labelIntersectAction:
                      AxisLabelIntersectAction.rotate45, // Prevents overlap
                  maximumLabelWidth: 120, // Prevent cutoff for long names
                  labelStyle: TextStyle(
                    fontSize: 10, // Shrinks text to fit
                    fontWeight: FontWeight.w500,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Percentage'),
                  minimum: 0,
                  maximum: 100,
                  interval: 10,
                ),
                isTransposed: true,
                series: seriesList,
              );
            },
          ),
        ),
      ],
    );
  }

  List<_ChartData> _parseChartData(List<dynamic> rawList) {
    final List<_ChartData> result = [];

    for (var item in rawList) {
      final operator = item['operatorCd']?.toString() ?? 'Unknown';

      final onTime = _toNum(item['ontimeFlights']);
      final above15 = _toNum(item['above15']);
      final above30 = _toNum(item['above30']);

      if (onTime != null && above15 != null && above30 != null) {
        result.addAll([
          _ChartData(operator, 'On Time', onTime),
          _ChartData(operator, 'Deviation 16–29 Min', above15),
          _ChartData(operator, 'Deviation 30+ Min', above30),
        ]);
      } else {
        debugPrint('⛔ Skipping item due to invalid numbers: $item');
      }
    }

    return result;
  }

  num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}

class _ChartData {
  final String operator;
  final String category;
  final num value;

  _ChartData(this.operator, this.category, this.value);
}
