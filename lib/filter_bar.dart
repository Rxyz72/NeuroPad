import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            bool isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: GestureDetector(
                onTap: () => onFilterSelected(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF000000) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}