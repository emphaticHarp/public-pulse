import 'package:flutter/material.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  // ---------------- Search & Filter ----------------
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.gray400,
                    size: 20,
                  ),
                  hintText: 'Search posts, people, issues...',
                  hintStyle: TextStyle(color: AppColors.gray500, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
