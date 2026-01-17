import 'package:flutter/material.dart';

class StatBox extends StatelessWidget {
  final String title;
  final String? value;
  final IconData? icon;
  final Color? iconColor;
  final double width;

  // 1. Add the new optional parameter
  final bool isTitleBold;

  const StatBox({
    super.key,
    required this.title,
    this.value,
    this.icon,
    this.iconColor,
    this.width = 150,
    // 2. Default it to false (normal weight)
    this.isTitleBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? Colors.grey),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    // 3. Use the boolean to toggle bold weight
                    fontWeight: isTitleBold ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}

// The blueprint for a single activity item
