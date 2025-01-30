import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Syncfusion charts import
import 'package:shared_preferences/shared_preferences.dart'; // For token and userId
import 'header_page.dart'; // Import your HeaderPage
import 'navbar.dart'; // Import your Navbar
import 'package:nicoapp/services/api_services.dart'; // Import your API Service

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int unassignedInquiriesCount = 0;
  int ongoingInquiriesCount = 0;
  int rejectedCount = 6; // Static rejected value for now
  int completedCount = 0; // Initialize completed inquiries

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {
      try {
        final data = await ApiService.fetchDashboardData(userId, token);
        setState(() {
          unassignedInquiriesCount = data['unassignedInquiriesCount'];
          ongoingInquiriesCount = data['ongoingInquiriesCount'];
          completedCount = data['completedInquiriesCount'];
        });
      } catch (e) {
        print("Error fetching dashboard data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Set your desired height
        child: HeaderPage(pageTitle: 'Analytics'), // Fixed Header
      ),
      bottomNavigationBar: const NavBar(
        initialIndex: 1,
      ), // Fixed Footer
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Syncfusion Pie Chart at the top
                    SizedBox(
                      height: screenWidth > 600 ? 300 : 250, // Adjust height
                      child: SfCircularChart(
                        title: ChartTitle(text: 'Inquiry Distribution'),
                        legend: Legend(isVisible: true),
                        series: <PieSeries<_PieChartData, String>>[
                          PieSeries<_PieChartData, String>(
                            dataSource: _getPieChartData(),
                            xValueMapper: (_PieChartData data, _) => data.x,
                            yValueMapper: (_PieChartData data, _) => data.y,
                            dataLabelMapper: (_PieChartData data, _) =>
                                '${data.y}%',
                            dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.inside),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Space after Pie chart

                    // Bar Chart with Syncfusion
                    SizedBox(
                      width: 600, // Set width of the chart
                      height: 250, // Set height as needed
                      child: SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        title: ChartTitle(text: 'Inquiry Status Breakdown'),
                        primaryXAxis: CategoryAxis(
                          title: AxisTitle(text: 'Inquiries'),
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: NumericAxis(
                          axisLine: const AxisLine(width: 0),
                          majorTickLines: const MajorTickLines(size: 0),
                        ),
                        series: <ColumnSeries<_BarChartData, String>>[
                          ColumnSeries<_BarChartData, String>(
                            dataSource: _getBarChartData(),
                            xValueMapper: (_BarChartData data, _) => data.x,
                            yValueMapper: (_BarChartData data, _) => data.y,
                            name: 'Inquiries',
                            selectionBehavior: SelectionBehavior(enable: true),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30), // Space after the Bar chart
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Data for Pie Chart
  List<_PieChartData> _getPieChartData() {
    int totalCount = unassignedInquiriesCount +
        ongoingInquiriesCount +
        rejectedCount +
        completedCount;

    return [
      _PieChartData(
          'Unassigned', _getPercentage(unassignedInquiriesCount, totalCount)),
      _PieChartData(
          'Ongoing', _getPercentage(ongoingInquiriesCount, totalCount)),
      _PieChartData('Rejected', _getPercentage(rejectedCount, totalCount)),
      _PieChartData('Completed', _getPercentage(completedCount, totalCount)),
    ];
  }

  /// Data for Bar Chart
  List<_BarChartData> _getBarChartData() {
    return [
      _BarChartData('Unassigned', unassignedInquiriesCount),
      _BarChartData('Ongoing', ongoingInquiriesCount),
      _BarChartData('Rejected', rejectedCount),
      _BarChartData('Completed', completedCount),
    ];
  }

  /// Helper method to calculate percentage
  double _getPercentage(int count, int total) {
    if (total == 0) return 0;
    return (count / total) * 100;
  }
}

/// Pie chart data model
class _PieChartData {
  _PieChartData(this.x, this.y);
  final String x;
  final double y;
}

/// Bar chart data model
class _BarChartData {
  _BarChartData(this.x, this.y);
  final String x;
  final int y;
}
