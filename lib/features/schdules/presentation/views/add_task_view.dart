import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line/core/utils/validation.dart';
import '../../data/models/task_model.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';

class AddTaskView extends StatefulWidget {
  final TaskModel? task;
  final DateTime? initialDate;
  const AddTaskView({super.key, this.task, this.initialDate});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  late String _selectedImportance;
  late String _selectedCategory;
  late final TextEditingController _titleController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _selectedImportance = 'Medium'; // Default or from task if added to model
    _selectedCategory = task?.category ?? 'Meeting';
    _titleController = TextEditingController(text: task?.title);
    _startTime = task?.startTimeOfDay;
    _endTime = task?.endTimeOfDay;

    String formatTime(TimeOfDay? time) {
      if (time == null) return '';
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    _startTimeController = TextEditingController(text: formatTime(_startTime));
    _endTimeController = TextEditingController(text: formatTime(_endTime));
  }

  final List<String> _importanceLevels = ['Low', 'Medium', 'High'];
  final List<String> _categories = [
    'Meeting',
    'Work',
    'Important',
    'Break',
    'Personal',
    'Health',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? 'Add New Task' : 'Edit Task',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Task Title
              _buildLabel('Task Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: Validation.validateTitle,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Time'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          validator: (value) =>
                              Validation.validateStartTime(_startTime),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              setState(() {
                                _startTime = time;
                                _startTimeController.text = time.format(
                                  context,
                                );
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '--:-- --',
                            prefixIcon: const Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('End Time'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          validator: (value) {
                            final endTimeError = Validation.validateEndTime(
                              _endTime,
                            );
                            if (endTimeError != null) return endTimeError;
                            return Validation.validateTimeRange(
                              _startTime,
                              _endTime,
                            );
                          },
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              setState(() {
                                _endTime = time;
                                _endTimeController.text = time.format(context);
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '--:-- --',
                            prefixIcon: const Icon(
                              Icons.access_time,
                              size: 20,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Importance
              _buildLabel('Importance', isRequired: false),
              const SizedBox(height: 12),
              Row(
                children: _importanceLevels.map((level) {
                  final isSelected = _selectedImportance == level;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImportance = level),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category
              _buildLabel('Category', isRequired: false),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: Colors.blue.withAlpha(3))
                            : null,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _autovalidateMode =
                              AutovalidateMode.onUserInteraction;
                        });

                        if (_formKey.currentState!.validate()) {
                          final date =
                              widget.task?.date ??
                              widget.initialDate ??
                              DateTime.now();

                          final task = TaskModel.fromTimeOfDay(
                            id: widget.task?.id,
                            title: _titleController.text,
                            description: widget.task?.description ?? '',
                            startTime: _startTime!,
                            endTime: _endTime!,
                            date: date,
                            category: _selectedCategory,
                            color: _getCategoryColor(_selectedCategory),
                            isDone: widget.task?.isDone ?? false,
                          );

                          final state = context.read<TaskCubit>().state;
                          int maxConcurrentWithNew = 1; // The new task itself
                          bool hasAnyOverlap = false;

                          if (state is TaskLoaded) {
                            final otherTasks = state.tasks
                                .where((t) => t.id != task.id)
                                .toList();

                            // 1. Check if the new task overlaps with any existing task
                            List<TaskModel> overlappingWithNew = [];
                            for (var existing in otherTasks) {
                              if (_tasksOverlap(task, existing)) {
                                hasAnyOverlap = true;
                                overlappingWithNew.add(existing);
                              }
                            }

                            // 2. For each task that overlaps with the new one,
                            // check if it also overlaps with another task that overlaps with the new one.
                            if (overlappingWithNew.isNotEmpty) {
                              maxConcurrentWithNew = 2; // At least one overlap
                              for (
                                int i = 0;
                                i < overlappingWithNew.length;
                                i++
                              ) {
                                for (
                                  int j = i + 1;
                                  j < overlappingWithNew.length;
                                  j++
                                ) {
                                  if (_tasksOverlap(
                                    overlappingWithNew[i],
                                    overlappingWithNew[j],
                                  )) {
                                    // Found a point where the new task, task i, and task j all overlap
                                    maxConcurrentWithNew = 3;
                                    break;
                                  }
                                }
                                if (maxConcurrentWithNew >= 3) break;
                              }
                            }
                          }

                          if (maxConcurrentWithNew >= 3) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Too Many Tasks'),
                                content: const Text(
                                  'You cannot have more than 2 tasks at the same time. Please adjust the timing.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else if (hasAnyOverlap) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Task Overlap'),
                                content: const Text(
                                  'This task overlaps with another task. Do you want to continue?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _saveTask(task);
                                    },
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            _saveTask(task);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D61),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.task == null ? 'Add Task' : 'Update Task',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Add padding for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTask(TaskModel task) {
    if (widget.task == null) {
      context.read<TaskCubit>().addTask(task);
    } else {
      context.read<TaskCubit>().updateTask(task);
    }
    Navigator.pop(context);
  }

  double _timeToDouble(TimeOfDay time) => time.hour + (time.minute / 60.0);

  bool _tasksOverlap(TaskModel t1, TaskModel t2) {
    final start1 = _timeToDouble(t1.startTimeOfDay);
    final end1 = _timeToDouble(t1.endTimeOfDay);
    final start2 = _timeToDouble(t2.startTimeOfDay);
    final end2 = _timeToDouble(t2.endTimeOfDay);
    return (start1 < end2 && end1 > start2);
  }

  Widget _buildLabel(String text, {bool isRequired = true}) {
    return Row(
      children: [
        if (!isRequired)
          const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
        if (!isRequired) const SizedBox(width: 6),
        if (!isRequired && text == 'Category')
          const Icon(Icons.label_outline, size: 16, color: Colors.grey),
        if (!isRequired && text == 'Category') const SizedBox(width: 6),

        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Meeting':
        return Colors.redAccent;
      case 'Work':
        return Colors.orangeAccent;
      case 'Important':
        return Colors.red;
      case 'Break':
        return Colors.green;
      case 'Personal':
        return Colors.blue;
      case 'Health':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
