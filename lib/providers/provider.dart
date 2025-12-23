import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbyte_gig_app/models/task_model.dart';

// --- Authentication Provider ---
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// --- Repository for Firestore Operations ---
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TaskRepository(this.userId);

  // Get Stream of Tasks
  Stream<List<Task>> getTasks() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('dueDate') // Sort by earliest date
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList(),
        );
  }

  Future<void> addTask(Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toMap());
  }

  Future<void> updateTask(Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}

// --- Filter State ---
final taskFilterProvider = StateProvider<String>(
  (ref) => 'all',
); // 'all', 'completed', 'incomplete'
final priorityFilterProvider = StateProvider<String?>(
  (ref) => null,
); // null, 'high', 'medium', 'low'

// --- Tasks Stream Provider (Filtered) ---
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final user = ref.watch(authProvider).value;
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
});
