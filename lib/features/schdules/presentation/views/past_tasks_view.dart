import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import 'package:avenue/features/schdules/presentation/views/days_view.dart';
import 'package:avenue/features/schdules/presentation/views/schedule_view.dart';

class PastTasksView extends StatefulWidget {
  final int initialOffset;
  const PastTasksView({super.key, this.initialOffset = 1});

  @override
  State<PastTasksView> createState() => _PastTasksViewState();
}

class _PastTasksViewState extends State<PastTasksView> {
  late int _weekOffset;

  @override
  void initState() {
    super.initState();
    _weekOffset = widget.initialOffset;
    context.read<TaskCubit>().loadDateBounds();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final endOfRange = normalizedToday.subtract(
      Duration(days: (_weekOffset - 1) * 7 + 1),
    );
    final startOfRange = endOfRange.subtract(const Duration(days: 6));

    final days = List.generate(7, (index) {
      return startOfRange.add(Duration(days: index));
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Past Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final firstTaskDate = state.firstTaskDate;
          final canGoBack =
              firstTaskDate == null || startOfRange.isAfter(firstTaskDate);

          return Column(
            children: [
              // Navigation Controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: canGoBack
                          ? () {
                              setState(() {
                                _weekOffset++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_ios),
                      tooltip: "Previous Week",
                      color: canGoBack ? Colors.black : Colors.grey,
                    ),
                    Text(
                      _formatDateRange(startOfRange, endOfRange),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004D61),
                      ),
                    ),
                    IconButton(
                      onPressed: _weekOffset > 1
                          ? () {
                              setState(() {
                                _weekOffset--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: "Next Week",
                      color: _weekOffset > 1 ? Colors.black : Colors.grey,
                    ),
                  ],
                ),
              ),

              // Days List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[6 - index]; // 6, 5, 4... 0

                    return DayCard(
                      day: day,
                      isToday: false,
                      isPast: true,
                      isFuture: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeView(selectedDate: day),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return "${start.day}/${start.month} - ${end.day}/${end.month}";
  }
}
