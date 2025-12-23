import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  (Color, Color, Color) _getPriorityColors(String priority) {
    switch (priority) {
      case 'high':
        return (
          const Color(0xFFFF3366),
          const Color(0xFFFFEBEE),
          const Color(0x40FF3366),
        );
      case 'medium':
        return (
          const Color(0xFFFF8C00),
          const Color(0xFFFFF3E0),
          const Color(0x40FF8C00),
        );
      case 'low':
      default:
        return (
          const Color(0xFF00C853),
          const Color(0xFFE8F5E9),
          const Color(0x4000C853),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final (mainColor, lightBg, shadowColor) = _getPriorityColors(task.priority);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,

      // --- Red Background ---
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3366),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),

      // --- UNDO Logic Here ---
      onDismissed: (_) {
        if (user != null) {
          // 1. Delete immediately
          final repo = TaskRepository(user.uid);
          repo.deleteTask(task.id);

          // 2. Show SnackBar with Undo
          ScaffoldMessenger.of(context).clearSnackBars(); // remove any old ones
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Task "${task.title}" deleted',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(
                0xFF1D1D35,
              ), // Dark background matching theme
              duration: const Duration(seconds: 5), // 5 Second Timer
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: const Color(0xFF00BFA5), // Teal accent color
                onPressed: () {
                  // 3. Restore Task (Write exactly same object back to DB)
                  repo.addTask(task);
                },
              ),
            ),
          );
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () {
                      if (user != null) {
                        TaskRepository(user.uid).updateTask(
                          Task(
                            id: task.id,
                            title: task.title,
                            description: task.description,
                            dueDate: task.dueDate,
                            priority: task.priority,
                            userId: task.userId,
                            isCompleted: !task.isCompleted,
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? mainColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: task.isCompleted
                              ? mainColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: task.isCompleted
                                ? Colors.grey.shade400
                                : const Color(0xFF2B2B48),
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: mainColor,
                          ),
                        ),
                        if (task.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              task.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Metadata (Date & Priority)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.priority.toUpperCase(),
                          style: TextStyle(
                            color: mainColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM d').format(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
