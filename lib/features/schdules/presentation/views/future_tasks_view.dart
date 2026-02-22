import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_sheet.dart';
import '../../../../core/widgets/avenue_loading.dart';

class FutureTasksView extends StatefulWidget {
  const FutureTasksView({super.key});

  @override
  State<FutureTasksView> createState() => _FutureTasksViewState();
}

class _FutureTasksViewState extends State<FutureTasksView> {
  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().loadFutureTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Future Tasks",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: AvenueLoadingIndicator());
          } else if (state is FutureTasksLoaded) {
            final tasks = state.tasks;
            if (tasks.isEmpty) {
              return const Center(child: Text("No future tasks found"));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  height: 100,
                  onTap: () {
                    // Future tasks are editable? Yes.
                    // But toggling done -> moves to "Past/Today" if date matches?
                    // Verify logic.
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TaskDetailSheet(
                        task: task,
                        selectedDate: task.taskDate,
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
