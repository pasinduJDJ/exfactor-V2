import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';

class NotificationCard {
  static Widget buildNotificationCards(List<Map<String, dynamic>> items,
      {required Function(int) onDelete,
      Function(Map<String, dynamic>)? onEdit}) {
    IconData _iconForType(String type) {
      switch (type) {
        case 'Event':
          return Icons.event;
        case 'Birthday':
          return Icons.cake;
        case 'News':
          return Icons.article;
        default:
          return Icons.notifications;
      }
    }

    Color _colorForType(String type) {
      switch (type) {
        case 'Event':
          return kPrimaryColor;
        case 'Birthday':
          return cardDarkYellow;
        case 'News':
          return cardGreen;
        default:
          return Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(0),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = items[i];
          final type = item['type'] as String;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 1) Leading icon
                  Container(
                    width: 36,
                    height: 36,
                    child: Icon(
                      _iconForType(type),
                      color: primaryColor,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 2) Title / Subtitle / Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['submission_date'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3) Edit and Delete buttons
                  if (onEdit != null)
                    IconButton(
                      icon:
                          const Icon(Icons.edit_document, color: primaryColor),
                      onPressed: () => onEdit(item),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: primaryColor),
                    onPressed: () => onDelete(item['notification_id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
