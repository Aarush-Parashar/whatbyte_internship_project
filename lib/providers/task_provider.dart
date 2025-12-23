import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import 'auth_provider.dart';

// --- State Providers for Filtering ---
// Filter by Status: 'all', 'completed', 'incomplete'
final taskFilterProvider = StateProvider<String>((ref) => 'all');

// Filter by Priority: null (show all), 'high', 'medium', 'low'
final priorityFilterProvider = StateProvider<String?>((ref) => null);

// --- The Main Task Stream (Filtered) ---
// This provider listens to Firestore AND the filter providers above.
// It automatically re-runs whenever new data comes in or a filter changes.
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final userAsync = ref.watch(authProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);

      final repository = TaskRepository(user.uid);
      final filterStatus = ref.watch(taskFilterProvider);
      final filterPriority = ref.watch(priorityFilterProvider);

      return repository.getTasks().map((tasks) {
        return tasks.where((task) {
          // 1. Filter by Status
          if (filterStatus == 'completed' && !task.isCompleted) return false;
          if (filterStatus == 'incomplete' && task.isCompleted) return false;

          // 2. Filter by Priority
          if (filterPriority != null && task.priority != filterPriority)
            return false;

          return true;
        }).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// --- Repository Class ---
// Encapsulates the raw Firestore commands
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskRepository(this.userId);

  // Get Stream of Tasks sorted by Due Date
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList(),
        );
  }

  // Create
  Future<void> addTask(Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toMap());
  }

  // Update
  Future<void> updateTask(Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete
  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
