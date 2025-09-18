import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final String selectedFilter;
  final DateTimeRange? selectedDateRange;
  final Function(String) onFilterChanged;
  final Function(DateTimeRange?) onDateRangeChanged;

  const FilterBottomSheet({
    super.key,
    required this.selectedFilter,
    required this.selectedDateRange,
    required this.onFilterChanged,
    required this.onDateRangeChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedFilter;
  DateTimeRange? _selectedDateRange;

  final List<FilterOption> _filterOptions = [
    FilterOption('all', 'All Calls', Icons.phone),
    FilterOption('incoming', 'Incoming', Icons.call_received),
    FilterOption('outgoing', 'Outgoing', Icons.call_made),
    FilterOption('scam', 'Scam Suspected', Icons.warning),
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _selectedDateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildFilterOptions(),
          _buildDateRangeSection(),
          _buildActions(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    ).animate()
      .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.textTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Filter Call History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_filterOptions.length, (index) {
            final option = _filterOptions[index];
            return _buildFilterOption(option, index);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterOption(FilterOption option, int index) {
    final isSelected = _selectedFilter == option.value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = option.value;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildDateRangeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDateRange != null
                            ? _formatDateRange(_selectedDateRange!)
                            : 'Select date range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedDateRange != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        color: AppTheme.textSecondary,
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'all';
      _selectedDateRange = null;
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_selectedFilter);
    widget.onDateRangeChanged(_selectedDateRange);
    Navigator.of(context).pop();
  }
}

class FilterOption {
  final String value;
  final String label;
  final IconData icon;

  FilterOption(this.value, this.label, this.icon);
}
