import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/sizes.dart';
import '../../models/category_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/brand_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  String? _category;
  String? _brand;
  String? _size;
  String? _color;
  String? _condition;
  String? _gender;
  double? _minPrice;
  double? _maxPrice;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  final _conditions = [
    AppStrings.conditionNewWithTag,
    AppStrings.conditionNew,
    AppStrings.conditionLikeNew,
    AppStrings.conditionUsedClean,
    AppStrings.conditionUsed,
  ];

  final _genders = [
    AppStrings.women,
    AppStrings.men,
    AppStrings.unisex,
    AppStrings.kids,
  ];

  final _colors = [
    AppStrings.colorBlack,
    AppStrings.colorWhite,
    AppStrings.colorRed,
    AppStrings.colorBlue,
    AppStrings.colorBeige,
    AppStrings.colorBrown,
    AppStrings.colorGray,
    AppStrings.colorPink,
    AppStrings.colorGreen,
    AppStrings.colorOrange,
    AppStrings.colorYellow,
    AppStrings.colorPurple,
    AppStrings.colorMulti,
  ];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(postFiltersProvider);
    _category = filters.category;
    _brand = filters.brand;
    _size = filters.size;
    _color = filters.color;
    _condition = filters.condition;
    _gender = filters.gender;
    _minPrice = filters.minPrice;
    _maxPrice = filters.maxPrice;
    if (_minPrice != null) {
      _minPriceController.text = _minPrice!.toStringAsFixed(0);
    }
    if (_maxPrice != null) {
      _maxPriceController.text = _maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final brandsAsync = ref.watch(brandsStreamProvider);
    final city = ref.watch(selectedCityProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.filter,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _category = null;
                          _brand = null;
                          _size = null;
                          _color = null;
                          _condition = null;
                          _gender = null;
                          _minPrice = null;
                          _maxPrice = null;
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        });
                      },
                      child: const Text(AppStrings.resetFilters),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Gender
                    _sectionTitle(AppStrings.gender),
                    Wrap(
                      spacing: 8,
                      children: _genders.map((g) {
                        return ChoiceChip(
                          label: Text(g),
                          selected: _gender == g,
                          onSelected: (selected) {
                            setState(() => _gender = selected ? g : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _sectionTitle(AppStrings.category),
                    categoriesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categories) => Wrap(
                        spacing: 8,
                        children: categories.map((c) {
                          return ChoiceChip(
                            label: Text(c.name),
                            selected: _category == c.name,
                            onSelected: (selected) {
                              setState(() {
                                _category = selected ? c.name : null;
                                _size = null; // Reset size when category changes
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Brand
                    _sectionTitle(AppStrings.brand),
                    brandsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (brands) => Wrap(
                        spacing: 8,
                        children: brands.map((b) {
                          return ChoiceChip(
                            label: Text(b.name),
                            selected: _brand == b.name,
                            onSelected: (selected) {
                              setState(
                                  () => _brand = selected ? b.name : null);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Condition
                    _sectionTitle(AppStrings.condition),
                    Wrap(
                      spacing: 8,
                      children: _conditions.map((c) {
                        return ChoiceChip(
                          label: Text(c),
                          selected: _condition == c,
                          onSelected: (selected) {
                            setState(() => _condition = selected ? c : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Size
                    _sectionTitle(AppStrings.size),
                    categoriesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categories) {
                        final selectedCat = categories.where((c) => c.name == _category).firstOrNull;
                        final sizeType = selectedCat?.sizeType ?? SizeType.clothes;
                        final sizes = Sizes.forSizeType(sizeType);
                        
                        // If no sizes for this category type, hide the section
                        if (sizes.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Wrap(
                          spacing: 8,
                          children: sizes.map((s) {
                            return ChoiceChip(
                              label: Text(s),
                              selected: _size == s,
                              onSelected: (selected) {
                                setState(() => _size = selected ? s : null);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Color
                    _sectionTitle(AppStrings.color),
                    Wrap(
                      spacing: 8,
                      children: _colors.map((c) {
                        return ChoiceChip(
                          label: Text(c),
                          selected: _color == c,
                          onSelected: (selected) {
                            setState(() => _color = selected ? c : null);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Price range
                    _sectionTitle(AppStrings.priceRange),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'من',
                                suffixText: 'ر.س',
                              ),
                              onChanged: (v) {
                                _minPrice = double.tryParse(v);
                              },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('—'),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'إلى',
                                suffixText: 'ر.س',
                              ),
                              onChanged: (v) {
                                _maxPrice = double.tryParse(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(postFiltersProvider.notifier).state = PostFilters(
                      category: _category,
                      brand: _brand,
                      size: _size,
                      color: _color,
                      condition: _condition,
                      gender: _gender,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(AppStrings.applyFilters),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
