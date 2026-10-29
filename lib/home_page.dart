import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/schedule_item.dart';
import 'services/auth_service.dart';
import 'services/schedule_service.dart';
import 'widgets/add_edit_schedule_sheet.dart';
import 'widgets/schedule_card.dart';

class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScheduleService _scheduleService = ScheduleService();
  User? _currentUser;
  List<ScheduleItem> _allSchedules = [];
  bool _isLoading = true;

  late DateTime _selectedDate;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Done'

  final List<String> _categories = [
    'All',
    'General',
    'Work',
    'Meeting',
    'Personal',
    'Study',
    'Fitness',
  ];

  String get _effectiveUserId =>
      widget.isGuest ? 'guest_user' : (_currentUser?.uid ?? 'guest_user');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentUser = AuthService().currentUser;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final schedules = await _scheduleService.getSchedules(_effectiveUserId);
    if (!mounted) return;
    setState(() {
      _allSchedules = schedules;
      _isLoading = false;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ScheduleItem> get _schedulesForSelectedDate {
    return _allSchedules.where((item) {
      final matchesDate = _isSameDay(item.date, _selectedDate);
      final matchesCategory =
          _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Pending' && !item.isCompleted) ||
          (_selectedStatus == 'Done' && item.isCompleted);
      return matchesDate && matchesCategory && matchesStatus;
    }).toList()
      ..sort((a, b) {
        final aMinutes = a.startHour * 60 + a.startMinute;
        final bMinutes = b.startHour * 60 + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // Today stats
  int get _todayTotalCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allSchedules.where((item) => _isSameDay(item.date, today)).length;
  }

  int get _todayCompletedCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allSchedules.where((item) => _isSameDay(item.date, today) && item.isCompleted).length;
  }

  void _openAddScheduleSheet([ScheduleItem? itemToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditScheduleSheet(
        userId: _effectiveUserId,
        initialDate: _selectedDate,
        itemToEdit: itemToEdit,
        onSave: (savedItem) async {
          if (itemToEdit != null) {
            await _scheduleService.updateSchedule(savedItem);
          } else {
            await _scheduleService.addSchedule(savedItem);
          }
          await _loadSchedules();
        },
      ),
    );
  }

  Future<void> _toggleItem(ScheduleItem item) async {
    await _scheduleService.toggleScheduleCompletion(item.id, _effectiveUserId);
    await _loadSchedules();
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    await _scheduleService.deleteSchedule(item.id, _effectiveUserId);
    await _loadSchedules();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.title}" removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _scheduleService.addSchedule(item);
            await _loadSchedules();
          },
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from Schedly?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService().signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedDateToday = _isSameDay(_selectedDate, today);
    final displayedList = _schedulesForSelectedDate;

    final todayTotal = _todayTotalCount;
    final todayDone = _todayCompletedCount;
    final progress = todayTotal > 0 ? todayDone / todayTotal : 0.0;

    final displayName = widget.isGuest
        ? 'Guest'
        : (_currentUser?.displayName?.isNotEmpty == true
            ? _currentUser!.displayName!
            : (_currentUser?.email?.split('@').first ?? 'Schedly User'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
            : CustomScrollView(
                slivers: [
                  // App Bar / User Profile Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $displayName 👋',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatHeaderDate(today),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Schedly Brand Badge & Sign Out Button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Image.asset(
                                  'asset/logo.png',
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                                tooltip: 'Sign Out',
                                onPressed: _confirmSignOut,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Today's Progress Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today\'s Progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}% Done',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  todayTotal == 0
                                      ? 'No tasks scheduled for today'
                                      : todayDone == todayTotal
                                          ? '🎉 All caught up for today!'
                                          : '$todayDone of $todayTotal tasks completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                if (!isSelectedDateToday)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = today;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Jump to Today',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Horizontal Date Picker Strip (14 days)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 82,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 14,
                        itemBuilder: (context, index) {
                          // -2 days to +11 days
                          final date = today.add(Duration(days: index - 2));
                          final isSelected = _isSameDay(date, _selectedDate);
                          final isToday = _isSameDay(date, today);

                          final hasTasksOnDate = _allSchedules.any((item) => _isSameDay(item.date, date));

                          const weekDayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = date);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 54,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : isToday
                                        ? Colors.deepPurple.shade50
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : isToday
                                          ? Colors.deepPurple.shade200
                                          : Colors.grey.shade200,
                                  width: isToday ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.deepPurple.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekDayShort[date.weekday - 1],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white70
                                          : isToday
                                              ? Colors.deepPurple
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? Colors.deepPurple
                                              : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasTasksOnDate
                                          ? (isSelected ? Colors.white : Colors.deepPurple)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Category Filters
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // Schedule Section Header + Status toggle (All, Pending, Done)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                isSelectedDateToday ? 'Today\'s Schedule' : 'Schedule',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${displayedList.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Status Filter Segment
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: ['All', 'Pending', 'Done'].map((status) {
                                final isStatusSelected = _selectedStatus == status;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedStatus = status),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isStatusSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: isStatusSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isStatusSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isStatusSelected
                                            ? Colors.deepPurple
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Schedule List or Empty State
                  displayedList.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.event_available_rounded,
                                    size: 32,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No schedules for this day',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Stay productive! Tap below to add a new schedule.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () => _openAddScheduleSheet(),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Schedule'),
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
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = displayedList[index];
                                return ScheduleCard(
                                  item: item,
                                  onToggle: () => _toggleItem(item),
                                  onEdit: () => _openAddScheduleSheet(item),
                                  onDelete: () => _deleteItem(item),
                                );
                              },
                              childCount: displayedList.length,
                            ),
                          ),
                        ),

                  // Bottom padding for FAB clearance
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddScheduleSheet(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
