import 'dart:ui';
import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserUtils {
  // Summary card
  static Widget buildStatusSummaryCard(List<Map<String, dynamic>> items,
      {void Function(int index)? onTap, Color? color}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      color: color ??
          primaryColor, // Use provided color or default to primaryColor
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: onTap != null ? () => onTap(index) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item['color'],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item['count'].toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'],
                      style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  //Expandeble Group Widget
  static Widget buildExpandableGroup({
    required String title,
    required Color color,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Map<String, dynamic>> groupList,
    required void Function(Map<String, dynamic>) onSeeMore,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12), bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: groupList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No items.'),
                  )
                : Column(
                    children: groupList
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => onSeeMore(item),
                                      style: TextButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        item['title'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 15, color: Colors.black),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ),
                                  Text(item['start_date']),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }

  static void showToast(
    String message,
    Color color,
    BuildContext context,
  ) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
