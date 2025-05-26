import 'package:carousel_slider/carousel_slider.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:mocadb/src/datamodel/AirportDetails/cargo_tonnage_model.dart';
import 'package:mocadb/src/datamodel/groups_Model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/theme/style.dart';
import '../../../datamodel/AirportDetails/airport_details_model.dart';
import '../../../datamodel/AirportDetails/movement_details_model.dart';
import '../../../datamodel/AirportDetails/passenger_footfall_model.dart';
import '../../../datamodel/airports_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/custom_text.dart';
import '../provider/dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;


class AirportsViewTappedScreen extends StatefulWidget {
  const AirportsViewTappedScreen({required this.data,this.isFromSavedScreen = false, super.key});
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
    dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    fetchData();
    fetchGroupsData();
    fetchAirportDetails(); // Fetch airport details when initializing
    setBoxForProvider();
    dashboardProvider.airportCode = widget.data.airportCd!;
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
        orElse: () => null,
      );

      if (saved != null) {
        List<dynamic> savedImages = saved[1]['airportImagesBytes'] ?? [];

        /// ✅ Load only first 3 images initially
        final initialImages = savedImages.take(3).toList();

        setState(() {
          imageUrls = []; // Clear online images
          imageMemoryList = List<Uint8List>.from(initialImages);
        });

        // 🔄 Optional: preload full list in background if needed later
        Future.delayed(Duration.zero, () {
          imageMemoryList = List<Uint8List>.from(savedImages);
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




  Future<void> fetchGroupsData() async {
    List<Map<String, dynamic>>? response = await dashboardProvider.getGroupsListApiCall();

    if (response != null) {
      setState(() {
        groupsList = response.map((e) => GroupsModel.fromJson(e)).toList();
        groupsList.sort((a, b) => (a.slno ?? 0).compareTo(b.slno ?? 0));

        // Set expansion states based on collapseStatus
        expansionStates = groupsList.map((group) => group.collapseStatus == "Y").toList();
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
        dashboardProvider.getPassengerFootFallListApiCall(airportCd: airportCode),
        dashboardProvider.getPassengerMppaListApiCall(airportCd: airportCode),
        dashboardProvider.getConnectivityListApiCall(airportCd: airportCode),
        dashboardProvider.getDestinationListApiCall(airportCd: airportCode),
        dashboardProvider.getRcsConnectivityListApiCall(airportCd: airportCode),
        dashboardProvider.getRCSRouteAndOperatorListApiCall(airportCd: airportCode),
        dashboardProvider.getPeakPeriodListApiCall(airportCd: airportCode),
        dashboardProvider.getAveragePerDayFootFallListApiCall(airportCd: airportCode),
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
        dashboardProvider.getProjectInchargeApiCall(airportCd: airportCode),
      ]);
      setState(() {

      }); // Update UI after data fetching
    } catch (e) {
      print("❌ Error loading airport details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load airport details!"))
      );
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
                      options: CarouselOptions(height: 250, autoPlay: true),
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
                            expansionStates[index] = !expansionStates[index];
                          });
                        },
                        expandedHeaderPadding: EdgeInsets.zero,
                        elevation: 1,
                        children: List.generate(provider.groupsList.length, (index) {
                          GroupsModel group = provider.groupsList[index];
                          return ExpansionPanel(
                            backgroundColor: Colors.white,
                            headerBuilder: (context, isExpanded) {
                              return Container(
                                color: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  group.groupHeading ?? "Unknown",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, size: 50));
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
    EasyLoading.show(status: "Preparing to save...");
    print('📦 addToBox with progress started');
    EasyLoading.show(status: 'Downloading images...');
    List<Future<Uint8List?>> downloadFutures = dashboardProvider.allAirportsImagesList.map((url) async {
      return await _downloadImageBytes(url);
    }).toList();

    List<Uint8List?> downloaded = await Future.wait(downloadFutures);
    List<Uint8List> imageBytes = downloaded.whereType<Uint8List>().toList();
    try {
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

      // 📥 Download images with progress
      final imageUrls = dashboardProvider.allAirportsImagesList;
      final List<Uint8List> imageBytes = [];
      final int total = imageUrls.length;

      for (int i = 0; i < total; i++) {
        final bytes = await _downloadImageBytes(imageUrls[i]);
        if (bytes != null) imageBytes.add(bytes);

        // 📊 Update progress
        double progress = (i + 1) / total;
        EasyLoading.showProgress(
          progress,
          status: 'Downloading images ${(progress * 100).toInt()}%',
        );
      }

      // 📦 Save all airport data
      final airportDetails = {
        'Airport Details': details.toJson(),
        "Passenger Handling Capacity (Peak Hour)": dashboardProvider.selectedPassengerPeak,
        "Passenger Footfall": dashboardProvider.selectedPassengerPeak,
        "Movement Details": dashboardProvider.selectedMovementDetails?.toJson(),
        "Passenger Trends": dashboardProvider.selectedPassengerFootfall?.toJson(),
        "Movement Trends": dashboardProvider.selectedMovementDetails?.toJson(),
        "Cargo Tonnage(MT)": dashboardProvider.selectedCargoTonnage?.toJson(),
        "Cargo Trends": dashboardProvider.selectedCargoTonnage?.toJson(),
        "Total Handling Capacity (MPPA)": dashboardProvider.selectedPassengerMppa,
        "Connectivity": dashboardProvider.selectedConnectivity,
        "Destinations": dashboardProvider.selectedDestinations,
        "RCS Connectivity": dashboardProvider.selectedRcsConnectivity,
        "RCS Route And Operator": dashboardProvider.selectedRCSRouteAndOperator,
        "Peak Period": dashboardProvider.selectedPeakPeriod,
        "Average Per Day Footfall": dashboardProvider.selectedAveragePerDayFootFall,
        "Cargo - Capacity (MTPA)": dashboardProvider.selectedCargoCapacity,
        "Cargo Operator": dashboardProvider.selectedCargoOperator,
        "APD Details": dashboardProvider.selectedApdDetails,
        "Work In Progress": dashboardProvider.selectedWorkInProgress,
        "Works Planned": dashboardProvider.selectedWorkPlanned,
        "Completed Works": dashboardProvider.selectedCompletedWorks,
        "Assistance Required": dashboardProvider.selectedAssistanceRequired,
        "Green Initiative": dashboardProvider.selectedGreenInitiative,
        "Project Incharge": dashboardProvider.selectedProjectIncharge,
        'groupsList': dashboardProvider.groupsList.map((g) => g.toJson()).toList(),
        'airportImagesBytes': imageBytes,
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


  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      print('⚠️ Timeout or error: $e');
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
            ? movementDetailsWidget(
            provider.selectedMovementDetails!, context)
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
            ? cargoTonnageWidget(provider.selectedCargoTonnage!,context)
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
            child: const Center(
                child: Text("No APD Details data available.")));
      case "Work In Progress":
        return provider.selectedWorkInProgress != null
            ? _workInProgressWidget(provider.selectedWorkInProgress!)
            : Container(
            color: ThemeColors.whiteColor,
            child: const Center(
                child: Text("No Work In Progress data available.")));
      case "Works Planned":
        return provider.selectedWorkPlanned != null
            ? _workPlannedWidget(provider.selectedWorkPlanned!)
            : Container(
            color: ThemeColors.whiteColor,
            child: const Center(
                child: Text("No Work Planned data available.")));
      case "Completed Works":
        return provider.selectedCompletedWorks != null
            ? _completedWorksWidget(provider.selectedCompletedWorks!)
            : Container(
            color: ThemeColors.whiteColor,
            child: const Center(
                child: Text("No Completed Work data available.")));
      case "Assistance Required":
        return provider.selectedAssistanceRequired != null
            ? _assistanceRequiredWidget(provider.selectedAssistanceRequired!)
            : Container(
            color: ThemeColors.whiteColor,
            child: const Center(
                child: Text("No Assistance Required data available.")));
      case "Green Initiative":
        return provider.selectedGreenInitiative != null
            ? _greenInitiativeWidget(provider.selectedGreenInitiative!)
            : Container(
            color: ThemeColors.whiteColor,
            child: const Center(
                child: Text("No Green Initiative data available.")));
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
      ["Airport Owned By", details.airportOwnedBy],
      ["Watch Hours", details.watchHours],
      ["Night Landing", details.nightLanding],
      ["Passenger Terminal Building (Area)", details.passengerTerminalBuildingAreaInSqm],
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
                      child: _buildDetailRow(
                          detailsList[leftIndex][0]!, detailsList[leftIndex][1]),
                    ),
                    if (rightIndex < detailsList.length)
                      Expanded(
                        child: _buildDetailRow(
                            detailsList[rightIndex][0]!, detailsList[rightIndex][1]),
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
                Expanded(child: _buildDetailRow(entry.key, entry.value?.toString() ?? " ")),
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
                Expanded(child: _buildDetailRow(entry.key, entry.value?.toString() ?? " ")),
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
                _buildDetailRow(entry.key, entry.value?.toString() ?? " "),
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
                Expanded(child: _buildDetailRow(entry.key, entry.value?.toString() ?? " ")),
              ],
            );
          }).toList(),
        ),
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

  Widget _averagePerDayFootfallWidget(Map<String, dynamic> averagePerDayFootfall) {
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
  Widget _workInProgressWidget(Map<String, dynamic> workInProgress) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: workInProgress.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow("", entry.value?.toString() ?? " ", showTitle: false)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _workPlannedWidget(Map<String, dynamic> workPlanned) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: workPlanned.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow("", entry.value?.toString() ?? " ", showTitle: false)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _completedWorksWidget(Map<String, dynamic> completedWorks) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: completedWorks.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow("", entry.value?.toString() ?? " ", showTitle: false)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _assistanceRequiredWidget(Map<String, dynamic> assistanceRequired) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: assistanceRequired.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow("", entry.value?.toString() ?? " ", showTitle: false)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _greenInitiativeWidget(Map<String, dynamic> greenInitiative) {
    return Container(
      color: ThemeColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: greenInitiative.entries.map((entry) {
            return Row(
              children: [
                Expanded(child: _buildDetailRow("", entry.value?.toString() ?? " ", showTitle: false)),
              ],
            );
          }).toList(),
        ),
      ),
    );
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
                _buildDetailRow(entry.key, entry.value?.toString() ?? " ", showTitle: true),
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

  Widget passengerFootFallWidget(PassengerFootFallModel? passengerFootfall, BuildContext context) {
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

    List<ChartData> chartData = passengerFootfall.financialData!.map((financial) {
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

  Widget movementDetailsWidget(MovemenetDetailsModel? movementDetails, BuildContext context) {
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

    List<ChartData> chartData =
    movementTrends.financialData!.map((financial) {
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
  Widget cargoTonnageWidget(CargoTonnageModel? cargoTonnage, BuildContext context) {
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

    List<ChartData> chartData =
    cargoTrends.financialData!.map((financial) {
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
          text: showTitle ? "$title: " : "", // Show title only if showTitle is true
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
