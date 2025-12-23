import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart'; // Ensure this import exists
import '../providers/provider.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // --- Helper to Group Tasks by Date ---
  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final grouped = <String, List<Task>>{
      'Today': [],
      'Tomorrow': [],
      'Upcoming': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (var task in tasks) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      if (taskDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(task);
      } else if (taskDate.isAtSameMomentAs(tomorrow)) {
        grouped['Tomorrow']!.add(task);
      } else if (taskDate.isBefore(today) && !task.isCompleted) {
        // Optional: Group overdue tasks in "Today" or a separate "Overdue" key
        grouped['Today']!.add(task);
      } else {
        grouped['Upcoming']!.add(task);
      }
    }

    // Remove empty groups so we don't show headers with no tasks
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final filterStatus = ref.watch(taskFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          // --- Vibrant Header ---
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8E2DE2),
                  Color(0xFF4A00E0),
                ], // Purple to Indigo
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x404A00E0),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date & Logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMM').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Filter Row ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPriorityFilter(ref),
                      _buildFilterChip(ref, 'All', 'all', filterStatus),
                      _buildFilterChip(
                        ref,
                        'Pending',
                        'incomplete',
                        filterStatus,
                      ),
                      _buildFilterChip(ref, 'Done', 'completed', filterStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Grouped Task List ---
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // 1. Run the grouping logic
                final groupedTasks = _groupTasks(tasks);

                if (groupedTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          size: 80,
                          color: Colors.deepPurple.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found!',
                          style: TextStyle(
                            color: Colors.deepPurple.shade200,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 2. Render List of Groups
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                  itemCount: groupedTasks.length,
                  itemBuilder: (context, index) {
                    final key = groupedTasks.keys.elementAt(index);
                    final tasksInGroup = groupedTasks[key]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Section Header ---
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            bottom: 12,
                            left: 4,
                          ),
                          child: Text(
                            key.toUpperCase(), // "TODAY", "TOMORROW"
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        // --- Tasks in this Group ---
                        ...tasksInGroup
                            .map((task) => TaskTile(task: task))
                            .toList(),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        extendedIconLabelSpacing: 8,
      ).getApplicationContainer(),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String label,
    String value,
    String currentFilter,
  ) {
    final isSelected = currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => ref.read(taskFilterProvider.notifier).state = value,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6200EA) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFilter(WidgetRef ref) {
    final currentPriority = ref.watch(priorityFilterProvider);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: currentPriority,
          icon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.filter_list_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          dropdownColor: const Color(0xFF4A00E0),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          hint: const Text(
            "Priority",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Priority: All')),
            DropdownMenuItem(
              value: 'high',
              child: Text(
                'Priority: High',
                style: TextStyle(color: Color(0xFFFF80AB)),
              ),
            ),
            DropdownMenuItem(
              value: 'medium',
              child: Text(
                'Priority: Medium',
                style: TextStyle(color: Color(0xFFFFCC80)),
              ),
            ),
            DropdownMenuItem(
              value: 'low',
              child: Text(
                'Priority: Low',
                style: TextStyle(color: Color(0xFFB9F6CA)),
              ),
            ),
          ],
          onChanged: (val) =>
              ref.read(priorityFilterProvider.notifier).state = val,
        ),
      ),
    );
  }
}

extension FabExtension on FloatingActionButton {
  Widget getApplicationContainer() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60FF4B2B),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: this,
    );
  }
}
