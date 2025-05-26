

import 'package:mocadb/src/core/utils/extension.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../core/utils/routes.dart';
import '../../../datamodel/airports_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/custom_text.dart';
import '../../widgets/custom_text_form.dart';
import '../provider/dashboard_provider.dart';
import 'AirportsViewTappedScreen.dart';

class AllAirportsScreen extends StatelessWidget {
  const AllAirportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      bodyWidget: Consumer<DashboardProvider>(
        builder: (BuildContext context, DashboardProvider provider, _) {
          if (provider.isLoading) {
            return const SizedBox.shrink();
          }

          final String searchText =
          provider.AirportNameController.text.trim().toLowerCase();

          // Filter list based on the search input
          final List<AllAirportsModel> filteredList = searchText.isNotEmpty
              ? provider.allAirportsList.where((AllAirportsModel element) {
            final String fileNumber =
            (element.airportName ?? '').toLowerCase();
            return fileNumber.contains(searchText);

          }).toList()
              : provider.allAirportsList;
          print('Filtered List: ${filteredList.map((e) => e.airportName).toList()}');
          print('Provider List: ${provider.allAirportsList}');
          print('Filtered List: $filteredList');
          return Column(
            children: <Widget>[
              if (provider.allAirportsList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextFormField(
                    controller: provider.AirportNameController,
                    focusNode: provider.AirportNameFocusNode,
                    labelText:
                    '${Constants.enter} ${Constants.airport} ${Constants.name}',
                    onChanged: (String val) {
                      provider.notifyToAllValues();
                    },
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(30)
                    ],
                    suffixIcon: searchText.isEmpty
                        ? const Icon(Icons.search)
                        : IconButton(
                      onPressed: () {
                        provider.AirportNameController.clear();
                        provider.notifyToAllValues();
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: ThemeColors.orangeColor,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                  child: CustomText(
                    writtenText: Constants.noDataFound,
                    textStyle: ThemeTextStyle.style(),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _customFileCard(
                      context: context,
                      data: filteredList[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //? Custom File Card
  Widget _customFileCard({
    required BuildContext context,
    required AllAirportsModel data,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 12.0),
      child: InkWell(
        onTap: () async {
          await NavigateRoutes.navigatePush(
              widget: AirportsViewTappedScreen(data: data), context: context);
        },
        child: Container(
            decoration: BoxDecoration(
                color: ThemeColors.primaryColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: ThemeColors.primaryColor),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: ThemeColors.primaryColor,
                    offset: Offset(0.5, 0.5),
                  ),
                  BoxShadow(
                    color: ThemeColors.primaryColor,
                    offset: Offset(-0.5, -0.5),
                  )
                ]),
            child: Column(children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
                    child: CustomText(
                        writtenText: data.airportName ?? Constants.empty,
                        textStyle: ThemeTextStyle.style(
                            color: ThemeColors.whiteColor)),
                  ),
                ],
              ),
            ])),
      ),
    );
  }

  //? Custom label Body text
  Widget _customLabelBodyText({
    required BuildContext context,
    required String label,
    required String? body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: CustomText(
              writtenText: label,
              textStyle: ThemeTextStyle.style(
                fontWeight: FontWeight.normal,
              )),
        ),
        CustomText(
            writtenText: ' : ',
            textStyle: ThemeTextStyle.style(
              fontWeight: FontWeight.normal,
            )),
        Expanded(
          flex: 2,
          child: CustomText(
              writtenText: body ?? Constants.hypenSymbol,
              textStyle: ThemeTextStyle.style(
                color: ThemeColors.blueColor,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }
}
