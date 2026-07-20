import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/refrigerant_model.dart';

class RefrigerantSelectorScreen extends StatefulWidget {
  final RefrigerantModel? selectedRefrigerant;

  const RefrigerantSelectorScreen({super.key, this.selectedRefrigerant});

  @override
  State<RefrigerantSelectorScreen> createState() =>
      _RefrigerantSelectorScreenState();
}

class _RefrigerantSelectorScreenState extends State<RefrigerantSelectorScreen> {
  late List<RefrigerantModel> _refrigerants;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  // Selected filters for Screen 2
  final List<String> _selectedSafetyGroups = [];
  final List<String> _selectedClasses = [];

  @override
  void initState() {
    super.initState();
    // Deep copy: create new model instances so toggling favorites does not mutate
    // the shared defaultRefrigerants list.
    _refrigerants = defaultRefrigerants
        .map(
          (r) => RefrigerantModel(
            name: r.name,
            gwp: r.gwp,
            odp: r.odp,
            criticalTemp: r.criticalTemp,
            boilingPoint: r.boilingPoint,
            safetyGroup: r.safetyGroup,
            typeClass: r.typeClass,
            color: r.color,
            isFavorite: r.isFavorite,
          ),
        )
        .toList();
    if (widget.selectedRefrigerant != null) {
      // Keep match
      final index = _refrigerants.indexWhere(
        (r) => r.name == widget.selectedRefrigerant!.name,
      );
      if (index != -1) {
        _refrigerants[index] = widget.selectedRefrigerant!;
      }
    }
  }

  // Filter logic
  List<RefrigerantModel> get _filteredList {
    return _refrigerants.where((ref) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty &&
          !ref.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      // 2. Favorites Tab
      if (_showFavoritesOnly && !ref.isFavorite) {
        return false;
      }
      // 3. Safety Group Filter
      if (_selectedSafetyGroups.isNotEmpty &&
          !_selectedSafetyGroups.contains(ref.safetyGroup)) {
        return false;
      }
      // 4. Class Type Filter
      if (_selectedClasses.isNotEmpty &&
          !_selectedClasses.contains(ref.typeClass)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Toggles favorite status
  void _toggleFavorite(int index) {
    setState(() {
      _refrigerants[index].isFavorite = !_refrigerants[index].isFavorite;
    });
  }

  // Resets all filters (Screen 2)
  void _resetFilters() {
    setState(() {
      _selectedSafetyGroups.clear();
      _selectedClasses.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chọn môi chất lạnh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter icon button
                GestureDetector(
                  onTap: () => _showFilterModal(context),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showFavoritesOnly = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_showFavoritesOnly
                              ? AppColors.bgCard
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.format_list_bulleted,
                              color: !_showFavoritesOnly
                                  ? Colors.white
                                  : AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tất cả',
                              style: TextStyle(
                                color: !_showFavoritesOnly
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showFavoritesOnly = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _showFavoritesOnly
                              ? AppColors.bgCard
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: _showFavoritesOnly
                                  ? Colors.amber
                                  : AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Yêu thích',
                              style: TextStyle(
                                color: _showFavoritesOnly
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy môi chất lạnh nào.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      // Find actual index in raw list to toggle favorite correctly
                      final rawIndex = _refrigerants.indexWhere(
                        (r) => r.name == item.name,
                      );

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  widget.selectedRefrigerant?.name == item.name
                                  ? item.color.withValues(alpha: 0.4)
                                  : AppColors.divider,
                              width:
                                  widget.selectedRefrigerant?.name == item.name
                                  ? 1.5
                                  : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  item.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: item.isFavorite
                                      ? Colors.amber
                                      : Colors.white60,
                                  size: 20,
                                ),
                                onPressed: () => _toggleFavorite(rawIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Screen 2: Bottom Sheet Filter Modal
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Count total matches in real time based on active modal filters
            final tempFiltered = _refrigerants.where((ref) {
              if (_selectedSafetyGroups.isNotEmpty &&
                  !_selectedSafetyGroups.contains(ref.safetyGroup)) {
                return false;
              }
              if (_selectedClasses.isNotEmpty &&
                  !_selectedClasses.contains(ref.typeClass)) {
                return false;
              }
              return true;
            }).toList();

            final totalFound = tempFiltered.length;

            final List<Map<String, dynamic>> safetyGroupOptions = [
              {
                'name': 'A1',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'A1')
                    .length,
              },
              {
                'name': 'A2',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'A2')
                    .length,
              },
              {
                'name': 'A2L',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'A2L')
                    .length,
              },
              {
                'name': 'A3',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'A3')
                    .length,
              },
              {
                'name': 'B1',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'B1')
                    .length,
              },
              {
                'name': 'B2',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'B2')
                    .length,
              },
              {
                'name': 'B2L',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'B2L')
                    .length,
              },
              {
                'name': 'B3',
                'count': _refrigerants
                    .where((r) => r.safetyGroup == 'B3')
                    .length,
              },
            ];

            final List<Map<String, dynamic>> classOptions = [
              {
                'name': 'CFC',
                'count': _refrigerants
                    .where((r) => r.typeClass == 'CFC')
                    .length,
              },
              {
                'name': 'HC',
                'count': _refrigerants.where((r) => r.typeClass == 'HC').length,
              },
              {
                'name': 'HCF/CO2',
                'count': _refrigerants
                    .where((r) => r.typeClass == 'HCF/CO2')
                    .length,
              },
              {
                'name': 'HCFC',
                'count': _refrigerants
                    .where((r) => r.typeClass == 'HCFC')
                    .length,
              },
              {
                'name': 'HFC',
                'count': _refrigerants
                    .where((r) => r.typeClass == 'HFC')
                    .length,
              },
            ];

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalFound Tìm thấy sản phẩm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reset Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setModalState(() {
                          _resetFilters();
                        });
                        setState(() {});
                      },
                      child: const Text(
                        'CÀI ĐẶT LẠI BỘ LỌC',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scrollable filters
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Nhóm an toàn Section
                        const Text(
                          'Nhóm an toàn',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: safetyGroupOptions.map((opt) {
                              final name = opt['name'] as String;
                              final count = opt['count'] as int;
                              final isChecked = _selectedSafetyGroups.contains(
                                name,
                              );
                              if (count == 0) return const SizedBox.shrink();

                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: AppColors.accentPrimary,
                                checkColor: Colors.white,
                                title: Text(
                                  '$name ($count)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                value: isChecked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      _selectedSafetyGroups.add(name);
                                    } else {
                                      _selectedSafetyGroups.remove(name);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Lớp Section
                        const Text(
                          'Lớp',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: classOptions.map((opt) {
                              final name = opt['name'] as String;
                              final count = opt['count'] as int;
                              final isChecked = _selectedClasses.contains(name);
                              if (count == 0) return const SizedBox.shrink();

                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: AppColors.accentPrimary,
                                checkColor: Colors.white,
                                title: Text(
                                  '$name ($count)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                value: isChecked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      _selectedClasses.add(name);
                                    } else {
                                      _selectedClasses.remove(name);
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Apply button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Xem $totalFound Sản phẩm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
