import 'package:flutter/material.dart';
import 'package:mocadb/src/datamodel/Monitor/top_airlines_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../datamodel/Monitor/index_data_model.dart';
import '../../../datamodel/Monitor/top_route_model.dart';
import '../../widgets/arr_dep_line_chart.dart';
import '../../widgets/custom_text_form.dart';
import '../provider/monitor_provider.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/Monitor/arrival_model.dart';
import '../../../datamodel/Monitor/departure_model.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  DateTime? selectedDate;
  bool isLoadingData = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = Provider.of<MonitorProvider>(context, listen: false);
      await provider.getAllAirportListApiCall();

      final chennaiAirport = provider.allAirportsList.firstWhere(
            (airport) =>
            (airport.airportName?.toLowerCase() ?? '').contains('chennai'),
        orElse: () => AllAirportsModel(),
      );

      if (chennaiAirport.airportCd != null &&
          chennaiAirport.airportCd!.isNotEmpty) {
        selectedDate = null;
        provider.userSelectedDate = null;
        provider.selectedAllAirport = chennaiAirport;
        await _onAirportSelected(provider, chennaiAirport);
      }
    });
  }

  Future<void> _onAirportSelected(
      MonitorProvider provider, AllAirportsModel selectedAirport) async {
    setState(() {
      isLoadingData = true;
    });

    provider.selectedAllAirport = selectedAirport;

    // Step 1: Always call date API first
    await provider.postDateApi(airportCd: selectedAirport.airportCd ?? "");

    // Step 2: Determine which date to use
    String? dateToUse;

    if (selectedDate != null) {
      // Use user selected date
      dateToUse = DateFormat('dd/MMM/yyyy').format(selectedDate!);
    } else if (provider.apiSelectedDate != null &&
        provider.apiSelectedDate!.isNotEmpty) {
      // Else fallback to date from date API
      dateToUse = provider.apiSelectedDate;
    }

    // Step 3: If no date found (even from API), abort
    if (dateToUse == null || dateToUse.isEmpty) {
      setState(() {
        isLoadingData = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Date not available for the selected airport."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 4: Proceed with other API calls
    await provider.postArrivalApiCall(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);
    await provider.postDepartureApiCall(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);
    await provider.postTopRoutes(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);
    await provider.postTopAirlines(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);
    await provider.postArrDepTrackApi(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);
    await provider.postIndexData(
        airportCd: selectedAirport.airportCd ?? "", selectedDate: dateToUse);

    setState(() {
      isLoadingData = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<MonitorProvider>(
      builder: (context, monitorProvider, _) {
        if (monitorProvider.isLoading &&
            monitorProvider.allAirportsList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final arrivals = monitorProvider.selectedArrivalModel?.arrivals ?? [];
        final departures =
            monitorProvider.selectedDepartureModel?.departure ?? [];
        final topRoute = monitorProvider.selectedTopRouteModel?.topRoutes ?? [];
        final topAirlines =
            monitorProvider.selectedTopAirlinesModel?.topAirlines ?? [];
        final chartData = monitorProvider
            .selectedArrDepTrackModel?.vOMMAirportArrivalsAdnDepartures ??
            [];

        final chartPoints2023 = <ChartSampleData>[];
        final chartPoints2024 = <ChartSampleData>[];
        final chartPoints2025 = <ChartSampleData>[];

        for (var e in chartData) {
          final month = e.month ?? '';
          final year2023 = double.tryParse(e.s3year ?? '0') ?? 0;
          final year2024 = double.tryParse(e.s2year ?? '0') ?? 0;
          final year2025 = double.tryParse(e.s1year ?? '0') ?? 0;

          chartPoints2023.add(ChartSampleData(x: month, y: year2023));
          chartPoints2024.add(ChartSampleData(x: month, y: year2024));
          if (year2025 > 0) {
            chartPoints2025.add(ChartSampleData(x: month, y: year2025));
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<AllAirportsModel>(
                  labelName: '',
                  hintText: 'Choose an airport',
                  items: monitorProvider.allAirportsList,
                  value: monitorProvider.selectedAllAirport,
                  itemLabel: (airport) => airport.airportName ?? 'Unknown',
                  showSearchBox: true,
                  onChanged: (selectedAirport) async {
                    if (selectedAirport != null) {
                      selectedDate = null;
                      monitorProvider.userSelectedDate = null;
                      await _onAirportSelected(monitorProvider, selectedAirport);
                    }
                  },
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      monitorProvider.userSelectedDate = picked;
                      if (monitorProvider.selectedAllAirport?.airportCd != null) {
                        await _onAirportSelected(
                            monitorProvider, monitorProvider.selectedAllAirport!);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(selectedDate!)
                              : (monitorProvider.apiSelectedDate != null
                              ? monitorProvider.apiSelectedDate!
                              : 'Select Date'),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoadingData)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _sectionHeader("Arrivals", arrivals.isNotEmpty,
                          () => _showArrivalBottomSheet(context, arrivals)),
                  _buildArrivalTable(arrivals.take(5).toList()),
                  const SizedBox(height: 24),
                  _sectionHeader("Departures", departures.isNotEmpty,
                          () => _showDepartureBottomSheet(context, departures)),
                  _buildDepartureTable(departures.take(5).toList()),
                  const SizedBox(height: 24),
                  _sectionHeaderNew("Top Routes"),
                  const SizedBox(height: 12),
                  _buildTopRoutesSection(topRoute),
                  const SizedBox(height: 24),
                  _sectionHeaderNew("Top Airlines"),
                  const SizedBox(height: 12),
                  _buildTopAirlinesSection(topAirlines),
                  const SizedBox(height: 24),
                  Text(
                    "${monitorProvider.selectedAllAirport?.airportCd ?? 'Airport'} Arrivals & Departures",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    legend: Legend(isVisible: true, position: LegendPosition.top),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<ChartSampleData, String>>[
                      LineSeries<ChartSampleData, String>(
                        dataSource: chartPoints2023,
                        xValueMapper: (data, _) => data.x,
                        yValueMapper: (data, _) => data.y,
                        name: '2023',
                        color: Colors.green,
                        dashArray: [5, 5],
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      LineSeries<ChartSampleData, String>(
                        dataSource: chartPoints2024,
                        xValueMapper: (data, _) => data.x,
                        yValueMapper: (data, _) => data.y,
                        name: '2024',
                        color: Colors.red,
                        dashArray: [5, 5],
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                      LineSeries<ChartSampleData, String>(
                        dataSource: chartPoints2025,
                        xValueMapper: (data, _) => data.x,
                        yValueMapper: (data, _) => data.y,
                        name: '2025',
                        color: Colors.blue,
                        width: 2,
                        markerSettings:
                        const MarkerSettings(isVisible: true),
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.top,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (monitorProvider.indexDataModel != null)
                    _buildIndexDataCard(monitorProvider.indexDataModel!),
                ]
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _sectionHeader(
      String title, bool showViewAll, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (showViewAll)
          TextButton(onPressed: onViewAll, child: const Text("View All")),
      ],
    );
  }

  Widget _sectionHeaderNew(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildArrivalTable(List<Arrivals> arrivals) {
    if (arrivals.isEmpty) return const Text("No arrival data available.");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          _buildTableHeader(["Scheduled", "Flight", "From", "Status"]),
          ...arrivals.map((e) {
            final scheduled = _parseTime(e.sTA);
            final actual = _parseTime(e.iSTATA);
            return TableRow(children: [
              _cell(e.sTA),
              _cell(e.fLIGHTNO),
              _cell(e.dEPLOCATION),
              _statusCell("Landed", e.iSTATA, _isDelayed(scheduled, actual)),
            ]);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDepartureTable(List<Departure> departures) {
    if (departures.isEmpty) return const Text("No departure data available.");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          _buildTableHeader(["Scheduled", "Flight", "To", "Status"]),
          ...departures.map((e) {
            final scheduled = _parseTime(e.sTA);
            final actual = _parseTime(e.iSTATA);
            return TableRow(children: [
              _cell(e.sTA),
              _cell(e.fLIGHTNO),
              _cell(e.dEPLOCATION),
              _statusCell("Departed", e.iSTATA, _isDelayed(scheduled, actual)),
            ]);
          }).toList(),
        ],
      ),
    );
  }

  void _showArrivalBottomSheet(BuildContext context, List<Arrivals> arrivals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView( // ✅ Vertical scroll
            child: SingleChildScrollView( // ✅ Horizontal scroll
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  _buildTableHeader([
                    "S.No",
                    "Scheduled",
                    "Flight",
                    "From",
                    "Operator",
                    "Reg No",
                    "Aircraft",
                    "Route",
                    "Status"
                  ]),
                  ...arrivals.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final e = entry.value;
                    final scheduled = _parseTime(e.sTA);
                    final actual = _parseTime(e.iSTATA);
                    return TableRow(children: [
                      _cell(index.toString()),
                      _cell(e.sTA),
                      _cell(e.fLIGHTNO),
                      _cell(e.dEPLOCATION),
                      _cell(e.oPERATORCD),
                      _cell(e.rEGNO),
                      _cell(e.aIRCRAFTTYPECD),
                      _cell(e.rOUTECD),
                      _statusCell("Landed", e.iSTATA, _isDelayed(scheduled, actual)),
                    ]);
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTopRoutesSection(List<TopRoutes> topRoute) {
    if (topRoute.isEmpty) return const Text("No TopRoute data available.");

    return Container(
      width: double.infinity,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1), // S.No
          1: FlexColumnWidth(4), // Location
          2: FlexColumnWidth(2), // Count
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          _buildTableHeader(["S.No", "Location", "Count"]),
          ...topRoute.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;

            return TableRow(children: [
              _cell((index + 1).toString()),

              // Location cell with image + text
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    if (e.locationImgUrl != null && e.locationImgUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          e.locationImgUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                       Container(),

                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.lOCATION ?? '-',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              _cell(e.cOUNT),
            ]);
          }).toList(),
        ],
      ),
    );
  }


  Widget _buildTopAirlinesSection(List<TopAirlines> topAirlines) {
    if (topAirlines.isEmpty) return const Text("No TopAirlines data available.");

    return SizedBox(
      width: double.infinity,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1), // S.No
          1: FlexColumnWidth(2), // Image
          2: FlexColumnWidth(4), // Operator
          3: FlexColumnWidth(2), // Count
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          _buildTableHeader(["S.No", "Logo", "Operator", "Count"]),
          ...topAirlines.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            return TableRow(children: [
              _cell((index + 1).toString()),

              // Airline Logo Cell (handles 404)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: (e.airlineImgUrl != null && e.airlineImgUrl!.isNotEmpty)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    e.airlineImgUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Return blank white box for 404s or failures
                      return Container(
                        width: 32,
                        height: 32,
                        color: Colors.white,
                      );
                    },
                  ),
                )
                    : Container(
                  width: 32,
                  height: 32,
                  color: Colors.white,
                ),
              ),

              _cell(e.oPERATOR),
              _cell(e.cOUNT),
            ]);
          }).toList(),
        ],
      ),
    );
  }



  void _showDepartureBottomSheet(
      BuildContext context, List<Departure> departures) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  _buildTableHeader([
                    "S.No",
                    "Scheduled",
                    "Flight",
                    "To",
                    "Operator",
                    "Reg No",
                    "Aircraft",
                    "Route",
                    "Status"
                  ]),
                  ...departures.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final e = entry.value;
                    final scheduled = _parseTime(e.sTA);
                    final actual = _parseTime(e.iSTATA);
                    return TableRow(children: [
                      _cell(index.toString()),
                      _cell(e.sTA),
                      _cell(e.fLIGHTNO),
                      _cell(e.dEPLOCATION),
                      _cell(e.oPERATORCD),
                      _cell(e.rEGNO),
                      _cell(e.aIRCRAFTTYPECD),
                      _cell(e.rOUTECD),
                      _statusCell(
                          "Departed", e.iSTATA, _isDelayed(scheduled, actual)),
                    ]);
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildIndexDataCard(IndexDataModel indexData) {
    double getPercentage(String value) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0;
    }

    return SizedBox(
      width: double.infinity, // Full width of the parent
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              indexData.indexData?.firstOrNull?.cURRENTTIME ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Local Time",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: getPercentage(indexData.indexData?.firstOrNull?.aRRDELAYDATA ?? "") / 100,
              center: Text(
                indexData.indexData?.firstOrNull?.aRRDELAYDATA ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 8),
            const Text("Arrival OTP", style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: getPercentage(indexData.indexData?.firstOrNull?.dEPDELAYDATA ?? "") / 100,
              center: Text(
                indexData.indexData?.firstOrNull?.dEPDELAYDATA ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 8),
            const Text("Departure OTP", style: TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }


  TableRow _buildTableHeader(List<String> titles) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
      children: titles
          .map((title) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }

  Widget _cell(String? value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(value ?? '-', style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _statusCell(String status, String? actualTime, bool isDelayed) {
    final color = isDelayed ? Colors.red : Colors.green;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Flexible(
            child: Text('$status ${actualTime ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      try {
        final now = DateTime.now();
        final parsed = DateFormat("HH:mm").parse(timeStr);
        return DateTime(
            now.year, now.month, now.day, parsed.hour, parsed.minute);
      } catch (_) {
        return null;
      }
    }
  }

  bool _isDelayed(DateTime? scheduled, DateTime? actual) {
    if (scheduled == null || actual == null) return false;
    if (scheduled.hour == 0 && actual.hour >= 20) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return actual.isAfter(scheduled.add(const Duration(minutes: 1)));
  }
}

class ChartSampleData {
  ChartSampleData({required this.x, required this.y});
  final String x;
  final double y;
}
