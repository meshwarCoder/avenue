import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/core/utils/validation.dart';
import '../../data/models/task_model.dart';
import '../../data/models/default_task_model.dart';
import '../cubit/task_cubit.dart';
import '../../../../core/utils/task_utils.dart';
import '../../../../core/utils/calendar_utils.dart';

class AddTaskView extends StatefulWidget {
  final TaskModel? task;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final bool disableRecurring;
  const AddTaskView({
    super.key,
    this.task,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.disableRecurring = false,
  });

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  late String _selectedImportance;
  late String _selectedCategory;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isRecurring = false;
  final List<int> _selectedWeekdays = [];
  DateTime? _selectedDate;
  final ScrollController _categoryScrollController = ScrollController();
  bool _showLeftIndicator = false;
  bool _showRightIndicator = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _selectedImportance = task?.importanceType ?? 'Medium';
    _selectedCategory = task?.category ?? 'Work';
    _titleController = TextEditingController(text: task?.name);
    _descController = TextEditingController(text: task?.desc);
    _startTime = task?.startTimeOfDay ?? widget.initialStartTime;
    _endTime = task?.endTimeOfDay ?? widget.initialEndTime;
    _selectedDate = task?.taskDate ?? widget.initialDate ?? DateTime.now();

    _startTimeController = TextEditingController(text: _formatTime(_startTime));
    _endTimeController = TextEditingController(text: _formatTime(_endTime));

    _categoryScrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollIndicators();
    });
  }

  void _updateScrollIndicators() {
    if (!_categoryScrollController.hasClients) return;
    final maxScroll = _categoryScrollController.position.maxScrollExtent;
    final currentScroll = _categoryScrollController.offset;

    setState(() {
      _showLeftIndicator = currentScroll > 5;
      _showRightIndicator = maxScroll > 0 && currentScroll < maxScroll - 5;
    });
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _categoryScrollController.removeListener(_updateScrollIndicators);
    _categoryScrollController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  final List<String> _importanceLevels = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? 'New Task' : 'Edit Task',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepPurple,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildFieldLabel("What's on your mind?", theme),
              _buildTextField(
                controller: _titleController,
                hint: 'Task Title',
                icon: Icons.edit_note_rounded,
                validator: Validation.validateTitle,
                theme: theme,
              ),
              const SizedBox(height: 24),

              _buildFieldLabel("Any details?", theme),
              _buildTextField(
                controller: _descController,
                hint: 'Description (Optional)',
                icon: Icons.description_outlined,
                maxLines: 2,
                theme: theme,
              ),
              const SizedBox(height: 24),

              if (widget.task == null && !widget.disableRecurring) ...[
                _buildFieldLabel("Occurrence", theme),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeToggle(
                        'One-time',
                        !_isRecurring,
                        () => setState(() => _isRecurring = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeToggle(
                        'Recurring',
                        _isRecurring,
                        () => setState(() => _isRecurring = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              if (!_isRecurring) ...[
                _buildFieldLabel('Scheduling', theme),
                _buildDateSelector(),
                const SizedBox(height: 24),
              ] else ...[
                _buildFieldLabel('Repeat on', theme),
                _buildWeekdaySelector(),
                const SizedBox(height: 24),
              ],

              _buildFieldLabel('Time Frame', theme),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      controller: _startTimeController,
                      label: 'Start',
                      onTap: () => _selectTime(true),
                      validator: (v) =>
                          Validation.validateStartTime(_startTime),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      controller: _endTimeController,
                      label: 'End',
                      onTap: () => _selectTime(false),
                      validator: (v) {
                        final err = Validation.validateEndTime(_endTime);
                        return err ??
                            Validation.validateTimeRange(_startTime, _endTime);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildFieldLabel('Category', theme),
              _buildCategorySelector(),
              const SizedBox(height: 32),

              _buildFieldLabel('Importance', theme),
              _buildImportanceRow(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ]
                          : [AppColors.deepPurple, const Color(0xFF6A4FC2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.task == null ? 'Create Task' : 'Update Changes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          size: 22,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildTypeToggle(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.colorScheme.primary : AppColors.deepPurple)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: CalendarUtils.normalize(DateTime.now()),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? const ColorScheme.dark(
                        primary: AppColors.slatePurple,
                        onPrimary: Colors.white,
                        onSurface: Colors.white,
                        surface: AppColors.darkBg,
                      )
                    : const ColorScheme.light(
                        primary: AppColors.deepPurple,
                        onPrimary: Colors.white,
                        onSurface: AppColors.deepPurple,
                        surface: AppColors.lightBg,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.today_rounded,
              color: AppColors.slatePurple,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? "${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}"
                  : "Select Date",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  Widget _buildWeekdaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isSelected = _selectedWeekdays.contains(dayIndex);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected)
                _selectedWeekdays.remove(dayIndex);
              else
                _selectedWeekdays.add(dayIndex);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimePicker({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.access_time_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark
            ? AppColors.slatePurple
            : AppColors.deepPurple;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.slatePurple,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: AppColors.darkBg,
                  )
                : const ColorScheme.light(
                    primary: AppColors.deepPurple,
                    onPrimary: Colors.white,
                    onSurface: AppColors.deepPurple,
                    surface: AppColors.lightBg,
                  ),
            timePickerTheme: TimePickerThemeData(
              dayPeriodBorderSide: BorderSide(color: primaryColor, width: 1.5),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return primaryColor;
                return Colors.transparent;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return primaryColor;
              }),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected))
                  return primaryColor.withValues(alpha: 0.2);
                return isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return primaryColor;
                return isDark ? Colors.white70 : Colors.black87;
              }),
              dialHandColor: primaryColor,
              dialBackgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return isDark ? Colors.white : Colors.black87;
              }),
              entryModeIconColor: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
          _startTimeController.text = time.format(context);
        } else {
          _endTime = time;
          _endTimeController.text = time.format(context);
        }
      });
    }
  }

  Widget _buildCategorySelector() {
    final categories = AppColors.taskCategories;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;

    return SizedBox(
      height: 48, // Slightly taller for better touch targets
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollMetricsNotification) {
            _updateScrollIndicators();
          }
          return false;
        },
        child: Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  final color = _getCategoryColor(category);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: color, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : color.withValues(alpha: 0.8)),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showLeftIndicator)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          bgColor,
                          bgColor.withValues(alpha: 0.9),
                          bgColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showRightIndicator)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          bgColor,
                          bgColor.withValues(alpha: 0.9),
                          bgColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportanceRow() {
    return Row(
      children: _importanceLevels.map((level) {
        final isSelected = _selectedImportance == level;
        final color = level == 'High'
            ? Colors.redAccent
            : (level == 'Medium' ? Colors.orangeAccent : Colors.green);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: level == 'High' ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedImportance = level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleSave() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (_formKey.currentState!.validate()) {
      if (_isRecurring) {
        if (_selectedWeekdays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one day')),
          );
          return;
        }
        _saveDefaultTask();
      } else {
        // One-time task: Check if it's in the past
        if (TaskUtils.isPast(_selectedDate ?? DateTime.now(), _startTime)) {
          TaskUtils.showBlockedActionMessage(
            context,
            "Cannot schedule tasks in the past!",
          );
          return;
        }

        final task = TaskModel.fromTimeOfDay(
          id: widget.task?.id,
          name: _titleController.text,
          desc: _descController.text,
          startTime: _startTime!,
          endTime: _endTime!,
          taskDate: _selectedDate ?? DateTime.now(),
          category: _selectedCategory,
          completed: widget.task?.completed ?? false,
          importanceType: _selectedImportance,
          oneTime: true,
          defaultTaskId: widget.task?.defaultTaskId,
        );
        _saveSpecificTask(task);
      }
    }
  }

  void _saveSpecificTask(TaskModel task) {
    if (widget.task == null)
      context.read<TaskCubit>().addTask(task);
    else
      context.read<TaskCubit>().updateTask(task);
    Navigator.pop(context);
  }

  void _saveDefaultTask() {
    final defaultTask = DefaultTaskModel(
      name: _titleController.text,
      desc: _descController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      category: _selectedCategory,
      weekdays: _selectedWeekdays,
      importanceType: _selectedImportance,
    );
    context.read<TaskCubit>().addDefaultTask(defaultTask);
    Navigator.pop(context);
  }

  Color _getCategoryColor(String category) {
    return AppColors.getCategoryColor(category);
  }
}
