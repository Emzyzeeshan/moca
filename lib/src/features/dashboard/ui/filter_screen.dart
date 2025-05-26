import 'package:flutter/material.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:mocadb/src/features/widgets/custom_text.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/utils/print.dart';
import '../../../datamodel/filter_airport_model.dart';
import '../../../datamodel/states_model.dart';
import '../../widgets/custom_text_form.dart';
import '../../widgets/submit_btn.dart';
import '../provider/dashboard_provider.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

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
    setState(() {}); // Refresh UI after data load
  }

  String? selectedAirport;
  String? selectedState;
  String? selectedRegion;
  String? cargoAvailability = "All";
  String? nightLanding = "All";
  String? watchHours = "All";

  TextEditingController airportController = TextEditingController();
  TextEditingController landFromController = TextEditingController();
  TextEditingController landToController = TextEditingController();
  bool isUploadSuccessful = false;
  Widget _buildSubmitButton() {
    return SubmitButtonFillWidget(
      isEnabled: true,
      onTap: () {
        _submitData(); // Call your asynchronous submission logic
      },
      text: Constants.submit,
      btnColor: ThemeColors.primaryColor, // Change color dynamically
      textPadding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
    );
  }

  Future<void> _submitData() async {
    // Find the selected state object using selectedState name
    AllStatesModel? selectedStateObj = dashboardProvider.allStatesList.firstWhere(
          (state) => state.statename == selectedState,
      orElse: () => AllStatesModel(statecode: null, statename: ""), // Default to null
    );

    // Convert selection to API format (Y/N), send empty string if "All"
    String formatFilterValue(String? value) {
      if (value == "Available" || value == "24 Hours") return "Y";
      if (value == "Not Available" || value == "Specific") return "N";
      return ""; // Send empty string for "All"
    }

    FilterAirportsModel postData = FilterAirportsModel(
      airportName: selectedAirport ?? "",
      regionName: selectedRegion ?? "",
      nightLanding: formatFilterValue(nightLanding), // Convert to Y/N or empty string
      state: selectedStateObj.statecode != null && selectedStateObj.statecode!.isNotEmpty
          ? int.tryParse(selectedStateObj.statecode!)
          : null,
      landFrom: landFromController.text.trim().isNotEmpty
          ? landFromController.text.trim()
          : "",
      landTo: landToController.text.trim().isNotEmpty
          ? landToController.text.trim()
          : "",
      watch: formatFilterValue(watchHours), // Convert to Y/N or empty string
      cargo: formatFilterValue(cargoAvailability), // Convert to Y/N or empty string
    );

    printDebug("Submitting Data: ${postData.toJson()}");
    await dashboardProvider.postFilterAirportListApiCall(postData, dashboardProvider, context);
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
                    color: ThemeColors.primaryColor),
                items: dashboardProvider.allAirportsList
                    .map((airport) => airport.airportName)
                    .whereType<String>() // Filters out null values
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
              // Region Dropdown
              CustomDropdown<String>(
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryColor),
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
                    color: ThemeColors.primaryColor),
                items: dashboardProvider.allStatesList
                    .map((state) => state.statename)
                    .whereType<String>() // Filters out null values
                    .toList(),
                itemLabel: (item) => item,
                hintText: "Select State",
                labelName: "State Name",
                value: selectedState,
                onChanged: (value) => setState(() => selectedState = value),
                showSearchBox: dashboardProvider.allStatesList.length > 6,
              ),

              const SizedBox(height: 10),

              // Cargo Availability Radio
        _buildRadioGroup(
            "Cargo Availability", ["Available", "Not Available", "All"], cargoAvailability,
                (value) {
              setState(() => cargoAvailability = value);
            }),
              // Land From & To Fields
              Row(
                children: [
                  Expanded(
                    child: CustomLabelTextFormField(
                      labelText: "Land From (in Acre)",
                      controller: landFromController,
                      focusNode: FocusNode(),
                      labelTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomLabelTextFormField(
                      labelText: "Land To (in Acre)",
                      controller: landToController,
                      focusNode: FocusNode(),
                      labelTextStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Night Landing Radio
              // CustomRadioButton(
              //   label: "Night Landing",
              //   value: nightLanding,
              //   yesOption: "Available",
              //   noOption: "Not Available",
              //   onChanged: (value) => setState(() => nightLanding = value),
              // ),
              _buildRadioGroup(
                  "Night Landing", ["Available", "Not Available", "All"], nightLanding,
                      (value) {
                    setState(() => nightLanding = value);
                  }),
              // Watch Hours Radio
              _buildRadioGroup(
                  "Watch Hours", ["24 Hours", "Specific", "All"], watchHours,
                      (value) {
                    setState(() => watchHours = value);
                  }),
              const SizedBox(height: 20),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSubmitButton(),
                  const SizedBox(width: 10),
                  SubmitButtonFillWidget(
                    isEnabled: true,
                    onTap: () {
                      setState(() {
                        selectedAirport = null;
                        selectedState = null;
                        selectedRegion = null;
                        cargoAvailability = "All";
                        nightLanding = "All";
                        watchHours = "All";
                        landFromController.clear();
                        landToController.clear();
                      });
                    },
                    text: "Clear",
                    btnColor: ThemeColors.primaryColor, // Same color as Submit button
                    textPadding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildRadioGroup(String label, List<String> options,
    String? selectedValue, Function(String?) onChanged) {
  return _buildFilterField(
    label,
    Row(
      children: options.map((option) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
                value: option, groupValue: selectedValue, onChanged: onChanged),
            Text(option,),
          ],
        );
      }).toList(),
    ),
  );
}

Widget _buildFilterField(String label, Widget field) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold,color: ThemeColors.primaryColor,)),
        field,
      ],
    ),
  );
}
