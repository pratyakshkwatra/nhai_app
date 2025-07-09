import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:nhai_app/screens/survey_vehicle_data_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const Map<String, List<Map<String, List<String>>>> dropDownData = {
  'NH148N': [
    {
      '10/03/2025': ['Lane L2', 'Lane R2']
    },
  ],
};

Widget dropDownMenu(BuildContext context, String header, List<String> items,
    String selectedItem, Function(dynamic) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding:
            EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
        child: Text(
          header,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: CustomDropdown<String>(
              items: items,
              initialItem: selectedItem,
              onChanged: onChanged,
              decoration: CustomDropdownDecoration(
                closedFillColor: Colors.grey.shade300,
                closedBorderRadius: BorderRadius.circular(12),
                expandedFillColor: Colors.grey.shade300,
                expandedBorderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRoad = dropDownData.keys.first;
  String selectedDate = '';
  String selectedLane = '';

  List<String> getDatesForSelectedRoad() {
    final listOfMaps = dropDownData[selectedRoad]!;
    return listOfMaps.map((map) => map.keys.first).toList();
  }

  List<String> getLanesForSelectedDate() {
    final listOfMaps = dropDownData[selectedRoad]!;
    for (var map in listOfMaps) {
      if (map.containsKey(selectedDate)) {
        return map[selectedDate]!;
      }
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    selectedDate = getDatesForSelectedRoad().first;
    selectedLane = getLanesForSelectedDate().first;
  }

  @override
  Widget build(BuildContext context) {
    final dates = getDatesForSelectedRoad();
    final lanes = getLanesForSelectedDate();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(
          "NHAI Inspection App",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                dropDownMenu(
                  context,
                  "Select Highway/Roadway",
                  dropDownData.keys.toList(),
                  selectedRoad,
                  (value) {
                    setState(() {
                      selectedRoad = value;
                      selectedDate = getDatesForSelectedRoad().first;
                      selectedLane = getLanesForSelectedDate().first;
                    });
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                dropDownMenu(
                  context,
                  "Select Survey Date",
                  dates,
                  selectedDate,
                  (value) {
                    setState(() {
                      selectedDate = value;
                      selectedLane = getLanesForSelectedDate().first;
                    });
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
                dropDownMenu(
                  context,
                  "Select Survey Lane",
                  lanes,
                  selectedLane,
                  (value) {
                    setState(() {
                      selectedLane = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return SurveyVehicleDataScreen(
                      videoPath: 'assets/${selectedLane.split(" ").last}_1080p.mp4',
                      csvPath: 'assets/${selectedLane.split(" ").last}.csv',
                      lane: selectedLane,
                    );
                  }));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
