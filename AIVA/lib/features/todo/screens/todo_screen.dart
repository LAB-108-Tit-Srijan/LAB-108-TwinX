import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class TodoItem {
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime? dueDate;
  final bool isCompleted;
  final String priority; // high, medium, low

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 'medium',
  });

  TodoItem copyWith({bool? isCompleted}) {
    return TodoItem(
      id: id,
      title: title,
      description: description,
      category: category,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority,
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'Upcoming', 'Completed'];
  
  List<TodoItem> _todos = [
    TodoItem(
      id: '1',
      title: 'Complete Physics Chapter 5',
      description: 'Focus on thermodynamics concepts',
      category: 'Study',
      dueDate: DateTime.now(),
      priority: 'high',
    ),
    TodoItem(
      id: '2',
      title: 'Practice Math Problems',
      description: 'Solve 20 calculus problems',
      category: 'Practice',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: 'medium',
    ),
    TodoItem(
      id: '3',
      title: 'Review Chemistry Notes',
      category: 'Review',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      priority: 'low',
    ),
    TodoItem(
      id: '4',
      title: 'Take Biology Quiz',
      description: 'Chapter 3 - Cell Biology',
      category: 'Quiz',
      dueDate: DateTime.now(),
      priority: 'high',
    ),
    TodoItem(
      id: '5',
      title: 'Watch Physics Video Lecture',
      category: 'Study',
      isCompleted: true,
      priority: 'medium',
    ),
    TodoItem(
      id: '6',
      title: 'Complete Assignment 3',
      description: 'Submit before deadline',
      category: 'Assignment',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      priority: 'high',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dvpw = MediaQuery.of(context).size.width;
    final dvph = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(dvpw, dvph),
            _buildStats(dvpw, dvph),
            _buildFilters(dvpw, dvph),
            Expanded(child: _buildTodoList(dvpw, dvph)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : dvph * 0.02),
        child: FloatingActionButton(
          onPressed: () => _showAddTodoSheet(context, dvpw, dvph),
          backgroundColor: AppColors.primaryDark,
          child: Icon(Icons.add_rounded, color: AppColors.primaryLime),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(double dvpw, double dvph) {
    return Container(
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grayLight.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(dvpw * 0.025),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(dvpw * 0.03),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: dvpw * 0.06,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Container(
            padding: EdgeInsets.all(dvpw * 0.025),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(dvpw * 0.03),
            ),
            child: Icon(
              Icons.checklist_rounded,
              size: dvpw * 0.06,
              color: AppColors.orange,
            ),
          ),
          SizedBox(width: dvpw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.055,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Stay organized & productive',
                  style: GoogleFonts.lato(
                    fontSize: dvpw * 0.032,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double dvpw, double dvph) {
    final completed = _todos.where((t) => t.isCompleted).length;
    final pending = _todos.where((t) => !t.isCompleted).length;
    final today = _todos.where((t) => 
      !t.isCompleted && 
      t.dueDate != null && 
      t.dueDate!.day == DateTime.now().day
    ).length;

    return Container(
      margin: EdgeInsets.all(dvpw * 0.04),
      padding: EdgeInsets.all(dvpw * 0.04),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today', today.toString(), AppColors.primaryLime, dvpw),
          Container(width: 1, height: dvph * 0.05, color: AppColors.white.withOpacity(0.2)),
          _buildStatItem('Pending', pending.toString(), AppColors.orange, dvpw),
          Container(width: 1, height: dvph * 0.05, color: AppColors.white.withOpacity(0.2)),
          _buildStatItem('Done', completed.toString(), AppColors.green, dvpw),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, double dvpw) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.07,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: dvpw * 0.032,
            color: AppColors.grayLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(double dvpw, double dvph) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: dvpw * 0.04),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: EdgeInsets.only(right: dvpw * 0.025),
              padding: EdgeInsets.symmetric(
                horizontal: dvpw * 0.045,
                vertical: dvpw * 0.025,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.white,
                borderRadius: BorderRadius.circular(dvpw * 0.06),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : AppColors.grayLight,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.lato(
                  fontSize: dvpw * 0.035,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.primaryDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<TodoItem> get _filteredTodos {
    switch (_selectedFilter) {
      case 'Today':
        return _todos.where((t) => 
          !t.isCompleted && 
          t.dueDate != null && 
          t.dueDate!.day == DateTime.now().day
        ).toList();
      case 'Upcoming':
        return _todos.where((t) => 
          !t.isCompleted && 
          t.dueDate != null && 
          t.dueDate!.isAfter(DateTime.now())
        ).toList();
      case 'Completed':
        return _todos.where((t) => t.isCompleted).toList();
      default:
        return _todos;
    }
  }

  Widget _buildTodoList(double dvpw, double dvph) {
    final todos = _filteredTodos;
    
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: dvpw * 0.2,
              color: AppColors.grayLight,
            ),
            SizedBox(height: dvph * 0.02),
            Text(
              'No tasks here!',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.gray,
              ),
            ),
            Text(
              'Add a new task to get started',
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.035,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(dvpw * 0.04),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return _buildTodoCard(todos[index], dvpw, dvph);
      },
    );
  }

  Widget _buildTodoCard(TodoItem todo, double dvpw, double dvph) {
    Color priorityColor;
    switch (todo.priority) {
      case 'high':
        priorityColor = AppColors.red;
        break;
      case 'medium':
        priorityColor = AppColors.orange;
        break;
      default:
        priorityColor = AppColors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: dvph * 0.015),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(dvpw * 0.04),
        border: todo.isCompleted ? null : Border(
          left: BorderSide(color: priorityColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(dvpw * 0.04),
          onTap: () {
            setState(() {
              final index = _todos.indexWhere((t) => t.id == todo.id);
              if (index != -1) {
                _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.all(dvpw * 0.04),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: dvpw * 0.065,
                  height: dvpw * 0.065,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.isCompleted 
                        ? AppColors.green 
                        : Colors.transparent,
                    border: Border.all(
                      color: todo.isCompleted ? AppColors.green : AppColors.grayLight,
                      width: 2,
                    ),
                  ),
                  child: todo.isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: dvpw * 0.04,
                          color: AppColors.white,
                        )
                      : null,
                ),
                SizedBox(width: dvpw * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: GoogleFonts.lato(
                          fontSize: dvpw * 0.04,
                          fontWeight: FontWeight.w700,
                          color: todo.isCompleted 
                              ? AppColors.gray 
                              : AppColors.primaryDark,
                          decoration: todo.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      if (todo.description != null) ...[
                        SizedBox(height: dvph * 0.005),
                        Text(
                          todo.description!,
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.033,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                      SizedBox(height: dvph * 0.01),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.025,
                              vertical: dvpw * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLime.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(dvpw * 0.015),
                            ),
                            child: Text(
                              todo.category,
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.028,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          if (todo.dueDate != null && !todo.isCompleted) ...[
                            SizedBox(width: dvpw * 0.02),
                            Icon(
                              Icons.schedule_rounded,
                              size: dvpw * 0.04,
                              color: AppColors.gray,
                            ),
                            SizedBox(width: dvpw * 0.01),
                            Text(
                              _formatDate(todo.dueDate!),
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.028,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return 'Today';
    } else if (date.day == now.day + 1 && date.month == now.month) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}';
  }

  void _showAddTodoSheet(BuildContext context, double dvpw, double dvph) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Study';
    String selectedPriority = 'medium';
    int selectedDueDay = 0; // 0=Today, 1=Tomorrow, 2=Day after tomorrow

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final bottomSafePadding = MediaQuery.of(context).padding.bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: dvph * 0.85,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(dvpw * 0.06)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: EdgeInsets.only(top: dvph * 0.015),
                  child: Container(
                    width: dvpw * 0.12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(dvpw * 0.05, dvpw * 0.05, dvpw * 0.05, bottomSafePadding + dvpw * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Task',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.055,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: dvph * 0.02),
                        TextField(
                          controller: titleController,
                          style: GoogleFonts.lato(fontSize: dvpw * 0.04),
                          decoration: InputDecoration(
                            hintText: 'Task title',
                            hintStyle: GoogleFonts.lato(color: AppColors.gray),
                            filled: true,
                            fillColor: AppColors.lightBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(dvpw * 0.03),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.04,
                              vertical: dvph * 0.015,
                            ),
                          ),
                        ),
                        SizedBox(height: dvph * 0.015),
                        TextField(
                          controller: descController,
                          style: GoogleFonts.lato(fontSize: dvpw * 0.038),
                          decoration: InputDecoration(
                            hintText: 'Description (optional)',
                            hintStyle: GoogleFonts.lato(color: AppColors.gray),
                            filled: true,
                            fillColor: AppColors.lightBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(dvpw * 0.03),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: dvpw * 0.04,
                              vertical: dvph * 0.015,
                            ),
                          ),
                        ),
                        SizedBox(height: dvph * 0.02),
                        // Due Date / Reminder
                        Text(
                          'Remind me',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.038,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: dvph * 0.01),
                        Row(
                          children: [
                            Expanded(child: _buildDueDateOption('Today', 0, selectedDueDay, dvpw, (d) => setSheetState(() => selectedDueDay = d))),
                            SizedBox(width: dvpw * 0.02),
                            Expanded(child: _buildDueDateOption('Tomorrow', 1, selectedDueDay, dvpw, (d) => setSheetState(() => selectedDueDay = d))),
                            SizedBox(width: dvpw * 0.02),
                            Expanded(child: _buildDueDateOption('In 2 days', 2, selectedDueDay, dvpw, (d) => setSheetState(() => selectedDueDay = d))),
                          ],
                        ),
                        SizedBox(height: dvph * 0.02),
                        Text(
                          'Category',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.038,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: dvph * 0.01),
                        Wrap(
                          spacing: dvpw * 0.02,
                          runSpacing: dvpw * 0.02,
                          children: ['Study', 'Practice', 'Review', 'Quiz', 'Assignment'].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedCategory = cat),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: dvpw * 0.035,
                                  vertical: dvpw * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryDark : AppColors.lightBg,
                                  borderRadius: BorderRadius.circular(dvpw * 0.05),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.lato(
                                    fontSize: dvpw * 0.032,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.white : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: dvph * 0.02),
                        Text(
                          'Priority',
                          style: GoogleFonts.lato(
                            fontSize: dvpw * 0.038,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: dvph * 0.01),
                        Row(
                          children: [
                            Expanded(child: _buildPriorityOption('High', 'high', AppColors.red, selectedPriority, dvpw, (p) => setSheetState(() => selectedPriority = p))),
                            SizedBox(width: dvpw * 0.02),
                            Expanded(child: _buildPriorityOption('Medium', 'medium', AppColors.orange, selectedPriority, dvpw, (p) => setSheetState(() => selectedPriority = p))),
                            SizedBox(width: dvpw * 0.02),
                            Expanded(child: _buildPriorityOption('Low', 'low', AppColors.green, selectedPriority, dvpw, (p) => setSheetState(() => selectedPriority = p))),
                          ],
                        ),
                        SizedBox(height: dvph * 0.025),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleController.text.isNotEmpty) {
                                setState(() {
                                  _todos.insert(0, TodoItem(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: titleController.text,
                                    description: descController.text.isEmpty ? null : descController.text,
                                    category: selectedCategory,
                                    dueDate: DateTime.now().add(Duration(days: selectedDueDay)),
                                    priority: selectedPriority,
                                  ));
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(vertical: dvph * 0.018),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(dvpw * 0.03),
                              ),
                            ),
                            child: Text(
                              'Add Task',
                              style: GoogleFonts.lato(
                                fontSize: dvpw * 0.042,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Extra padding for keyboard
                        SizedBox(height: keyboardHeight > 0 ? dvph * 0.02 : 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDueDateOption(String label, int value, int selected, double dvpw, Function(int) onSelect) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dvpw * 0.02,
          vertical: dvpw * 0.03,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withOpacity(0.15) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(dvpw * 0.025),
          border: Border.all(
            color: isSelected ? AppColors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              value == 0 ? Icons.today_rounded : value == 1 ? Icons.event_rounded : Icons.date_range_rounded,
              size: dvpw * 0.055,
              color: isSelected ? AppColors.blue : AppColors.gray,
            ),
            SizedBox(height: dvpw * 0.015),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.03,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.blue : AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String label, String value, Color color, String selected, double dvpw, Function(String) onSelect) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dvpw * 0.04,
          vertical: dvpw * 0.025,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(dvpw * 0.025),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: dvpw * 0.03,
              height: dvpw * 0.03,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            SizedBox(width: dvpw * 0.02),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: dvpw * 0.035,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

