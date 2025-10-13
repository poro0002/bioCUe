import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biocue/themes/colors.dart';

class HorizontalCalendar extends StatelessWidget {
  final DateTime startDate;
  final int daysToShow;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const HorizontalCalendar({
    required this.startDate, //the first date to show (e.g. today minus 3 days)
    this.daysToShow = 7, // how many days to show (default is 7)
    required this.selectedDate, // the currently selected date (used to highlight it)
    required this.onDateSelected, // a callback function that runs when a date is tapped
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonthYear = DateFormat.yMMMM().format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: Text(
            currentMonthYear,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysToShow,
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final isSelected =
                  date.day == selectedDate.day &&
                  date.month == selectedDate.month &&
                  date.year == selectedDate.year;

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFFF6F61) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E().format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        date.day.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
