import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/product.dart';
import 'models/schedule_item.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/schedule_service.dart';
import 'widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductService _productService = ProductService();
  final ScheduleService _scheduleService = ScheduleService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Work',
    'Meeting',
    'Study',
    'Fitness',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 1. HTTP GET Request Execution (20pts - Part of FULL API)
  // ============================================================
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load schedule tasks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 2. HTTP POST Request Execution (Create / Add)
  // ============================================================
  Future<void> _createProduct(Product newProduct) async {
    // Show quick progress feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Executing HTTP POST request...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final created = await _productService.createProduct(newProduct);

    if (!mounted) return;
    setState(() {
      _allProducts.insert(0, created);
    });
    _applyFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'HTTP POST Success: Created "${created.title}" (ID: ${created.id})',
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // 3. HTTP PUT Request Execution (Update)
  // ============================================================
  Future<void> _updateProduct(Product updatedProduct) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Executing HTTP PUT request...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await _productService.updateProduct(updatedProduct);

    if (!mounted) return;
    setState(() {
      final index = _allProducts.indexWhere((p) => p.id == result.id);
      if (index != -1) {
        _allProducts[index] = result;
      }
    });
    _applyFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('HTTP PUT Success: Updated "${result.title}"'),
        backgroundColor: Colors.indigo.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // 4. HTTP DELETE Request Execution (Delete)
  // ============================================================
  Future<void> _deleteProduct(Product product) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Executing HTTP DELETE request...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await _productService.deleteProduct(product.id);

    if (!mounted) return;
    if (success) {
      setState(() {
        _allProducts.removeWhere((p) => p.id == product.id);
      });
      _applyFilter();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('HTTP DELETE Success: Removed "${product.title}"'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'HTTP DELETE Task',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text('Send HTTP DELETE request to remove "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Execute DELETE'),
          ),
        ],
      ),
    );
  }

  // Dialog / Sheet for Creating (POST) or Editing (PUT) a Product/Task
  void _openTaskFormSheet({Product? existingProduct}) {
    final isEditing = existingProduct != null;
    final titleController = TextEditingController(
      text: existingProduct?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingProduct?.description ?? '',
    );
    final durationController = TextEditingController(
      text: existingProduct?.duration ?? '1h 00m',
    );
    String selectedCat = existingProduct?.category ?? 'Work';
    String selectedPri = existingProduct?.priority ?? 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isEditing
                              ? Icons.edit_note_rounded
                              : Icons.add_circle_outline_rounded,
                          color: Colors.deepPurple,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditing
                              ? 'Edit Task (HTTP PUT)'
                              : 'New Task (HTTP POST)',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task / Product Title',
                        hintText: 'e.g. Code Review & Sprint Demo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Detailed task agenda or notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCat,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                [
                                      'Work',
                                      'Meeting',
                                      'Study',
                                      'Fitness',
                                      'Personal',
                                    ]
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedCat = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPri,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['High', 'Medium', 'Low']
                                .map(
                                  (pri) => DropdownMenuItem(
                                    value: pri,
                                    child: Text(pri),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedPri = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        hintText: 'e.g. 1h 30m',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          Navigator.of(ctx).pop();

                          if (isEditing) {
                            final updated = existingProduct.copyWith(
                              title: title,
                              description: descController.text.trim(),
                              category: selectedCat,
                              priority: selectedPri,
                              duration: durationController.text.trim(),
                            );
                            _updateProduct(updated);
                          } else {
                            final newP = Product(
                              id: 0,
                              title: title,
                              description: descController.text.trim(),
                              category: selectedCat,
                              priority: selectedPri,
                              duration: durationController.text.trim(),
                            );
                            _createProduct(newP);
                          }
                        },
                        icon: Icon(
                          isEditing
                              ? Icons.save_rounded
                              : Icons.cloud_upload_rounded,
                        ),
                        label: Text(
                          isEditing ? 'Execute HTTP PUT' : 'Execute HTTP POST',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // Search View Filtering (10pts)
  // ============================================================
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesQuery =
            query.isEmpty ||
            product.title.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.priority.toLowerCase().contains(query);

        final matchesCategory =
            _selectedCategory == 'All' ||
            product.category.toLowerCase() == _selectedCategory.toLowerCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _scheduleProduct(Product product) async {
    final user = AuthService().currentUser;
    final userId = user?.uid ?? 'guest_user';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final item = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: product.title,
      description: product.description,
      date: today,
      startHour: 9,
      startMinute: 0,
      endHour: 10,
      endMinute: 30,
      category: product.category,
      priority: SchedulePriority.fromString(product.priority),
      isCompleted: false,
    );

    await _scheduleService.addSchedule(item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${product.title}" to your schedule!'),
        backgroundColor: Colors.deepPurple,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.amberAccent,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Task & Work Catalog',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('POST'),
              backgroundColor: Colors.green,
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.deepPurple,
              ),
            ),
            tooltip: 'Add Task (HTTP POST)',
            onPressed: () => _openTaskFormSheet(),
          ),
          IconButton(
            icon: Badge.count(
              count: _allProducts.length,
              isLabelVisible: _allProducts.isNotEmpty,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.refresh_rounded, color: Colors.deepPurple),
            ),
            tooltip: 'Reload Tasks (HTTP GET)',
            onPressed: _fetchProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskFormSheet(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Badge(
          label: Text('POST'),
          backgroundColor: Colors.amber,
          child: Icon(Icons.add_rounded),
        ),
        label: const Text(
          'Add Task (POST)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search View & Filter Section (10pts)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search View Input Bar (10pts)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks, work, meetings...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.deepPurple,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Category Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: Colors.deepPurple,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                            _applyFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Count & Status Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_filteredProducts.length} of ${_allProducts.length} tasks',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_searchController.text.isNotEmpty ||
                    _selectedCategory != 'All')
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = 'All');
                      _applyFilter();
                    },
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Dynamic ListView Presentation (15pts)
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Executing HTTP GET request...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              const Text(
                'No matching tasks found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No tasks matched "${_searchController.text}".'
                    : 'No tasks found in this category.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    // Dynamic Product ListView with Pull-to-Refresh (15pts)
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(
            product: product,
            onSchedule: () => _scheduleProduct(product),
            onEdit: () => _openTaskFormSheet(existingProduct: product),
            onDelete: () => _confirmDeleteProduct(product),
          );
        },
      ),
    );
  }
}
