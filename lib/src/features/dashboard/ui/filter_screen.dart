import 'package:flutter/material.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:mocadb/src/features/widgets/custom_text.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/utils/print.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/filter_airport_model.dart';
import '../../../datamodel/states_model.dart';
import '../../widgets/custom_text_form.dart';
import '../../widgets/submit_btn.dart';
import '../provider/dashboard_provider.dart';
import 'AirportListScreen.dart';

class FilterScreen extends StatefulWidget {
  final String? selectedAirport;
  final String? selectedState;
  final String? selectedRegion;
  final String? selectedFieldType;
  final String? selectedAirportType;
  const FilterScreen({super.key, required ScrollController scrollController, this.selectedAirport,
    this.selectedState,
    this.selectedRegion,
    this.selectedFieldType,
    this.selectedAirportType,});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late DashboardProvider dashboardProvider;

  @override
  void initState() {
    super.initState();
    dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    fetchData();
  }

  Future<void> fetchData() async {
    EasyLoading.show(status: Constants.loading);
    await dashboardProvider.getAllStatesListApiCall();
    await dashboardProvider.getAllAirportListApiCall();
    EasyLoading.dismiss();
    setState(() {});
  }

  String? selectedAirport;
  String? selectedState;
  String? selectedRegion;
  String? selectedFieldType;
  String? selectedAirportType;

  TextEditingController airportController = TextEditingController();
  TextEditingController landFromController = TextEditingController();
  TextEditingController landToController = TextEditingController();
  bool isUploadSuccessful = false;

  Widget _buildSubmitButton() {
    return SubmitButtonFillWidget(
      isEnabled: true,
      onTap: () {
        _submitData();
      },
      text: Constants.submit,
      btnColor: ThemeColors.primaryColor,
      textPadding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
    );
  }

  Future<void> _submitData() async {
    AllStatesModel? selectedStateObj = dashboardProvider.allStatesList.firstWhere(
          (state) => state.statename == selectedState,
      orElse: () => AllStatesModel(statecode: null, statename: ""),
    );

    FilterAirportsModel postData = FilterAirportsModel(
      airportName: selectedAirport ?? "",
      regionName: selectedRegion ?? "",
      state: selectedStateObj.statecode != null && selectedStateObj.statecode!.isNotEmpty
          ? int.tryParse(selectedStateObj.statecode!)
          : null,
      airportType: selectedAirportType ?? "",
      fieldType: selectedFieldType ?? "",
    );

    printDebug("Submitting Data: ${postData.toJson()}");

    final filteredResults = await dashboardProvider.postFilterAirportListApiCall(
      postData,
      dashboardProvider,
      context,
    );

    if (filteredResults != null && filteredResults.isNotEmpty) {
      // ✅ Convert list
      final convertedList = filteredResults.map((e) {
        return AllAirportsModel(
          airportCd: e.airportCd,
          airportName: e.airportName,
        );
      }).toList();

      Navigator.pop(context, convertedList); // ✅ Now returns List<AllAirportsModel>
    } else {
      EasyLoading.showInfo("No airports found for selected filters.");
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Airport Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryColor,
                ),
                items: dashboardProvider.allAirportsList
                    .map((airport) => airport.airportName)
                    .whereType<String>()
                    .toList(),
                itemLabel: (item) => item,
                hintText: "Select Airport",
                labelName: "Airport Name",
                value: selectedAirport,
                onChanged: (value) => setState(() => selectedAirport = value),
                showSearchBox: dashboardProvider.allAirportsList.length > 6,
              ),

              const SizedBox(height: 10),

              // Region Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryColor,
                ),
                items: {
                  "NR": "North Region",
                  "WR": "West Region",
                  "ER": "East Region",
                  "SR": "South Region",
                  "NE": "North East Region",
                }.entries.map((e) => e.key).toList(),
                itemLabel: (item) => {
                  "NR": "North Region",
                  "WR": "West Region",
                  "ER": "East Region",
                  "SR": "South Region",
                  "NE": "North East Region",
                }[item]!,
                hintText: "Select Region",
                labelName: "Region Name",
                value: selectedRegion,
                onChanged: (value) => setState(() => selectedRegion = value),
              ),

              const SizedBox(height: 10),

              // State Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryColor,
                ),
                items: dashboardProvider.allStatesList
                    .map((state) => state.statename)
                    .whereType<String>()
                    .toList(),
                itemLabel: (item) => item,
                hintText: "Select State",
                labelName: "State Name",
                value: selectedState,
                onChanged: (value) => setState(() => selectedState = value),
                showSearchBox: dashboardProvider.allStatesList.length > 6,
              ),

              const SizedBox(height: 10),

              // Field Type Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryColor,
                ),
                items: ['G', 'B'],
                itemLabel: (item) => item == 'G' ? 'Green Field' : 'Brown Field',
                hintText: "Select Field Type",
                labelName: "Field Type",
                value: selectedFieldType,
                onChanged: (value) => setState(() => selectedFieldType = value),
              ),

              const SizedBox(height: 10),

              // Airport Type Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryColor,
                ),
                items: [
                  "International",
                  "Domestic",
                  "Civil Enclave",
                  "Custom",
                  "Under Construction",
                ],
                itemLabel: (item) => item,
                hintText: "Select Airport Type",
                labelName: "Airport Type",
                value: selectedAirportType,
                onChanged: (value) => setState(() => selectedAirportType = value),
              ),

              const SizedBox(height: 20),

              // Submit & Clear Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SubmitButtonFillWidget(
                    isEnabled: true,
                    onTap: () {
                      setState(() {
                        selectedAirport = null;
                        selectedState = null;
                        selectedRegion = null;
                        selectedFieldType = null;
                        selectedAirportType = null;
                      });
                    },
                    text: "Clear",

                    btnColor: ThemeColors.primaryColor,
                    textPadding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                  ),
                  const SizedBox(width: 10),
                  _buildSubmitButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
