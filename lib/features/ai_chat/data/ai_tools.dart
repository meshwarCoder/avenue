import 'package:google_generative_ai/google_generative_ai.dart';

class AiTools {
  static final _searchDefaultTasks = FunctionDeclaration(
    'searchDefaultTasks',
    'Search for DEFAULT tasks (templates for recurring tasks) using a query string. Use this when the user asks about "habits", "routines", or "default tasks".',
    Schema(
      SchemaType.object,
      properties: {
        'query': Schema(SchemaType.string, description: 'The search query'),
      },
      requiredProperties: ['query'],
    ),
  );

  static final List<Tool> tools = [
    Tool(
      functionDeclarations: [
        _getTasks,
        _addTask,
        _updateTask,
        _deleteTask,
        _searchTasks,
        _searchDefaultTasks,
      ],
    ),
  ];

  static final _getTasks = FunctionDeclaration(
    'getTasks',
    'Get tasks for a specific date range. Use this when the user asks about their schedule.',
    Schema(
      SchemaType.object,
      properties: {
        'startDate': Schema(
          SchemaType.string,
          description: 'Start date in YYYY-MM-DD format',
        ),
        'endDate': Schema(
          SchemaType.string,
          description:
              'End date in YYYY-MM-DD format (optional, defaults to startDate if not provided)',
        ),
      },
      requiredProperties: ['startDate'],
    ),
  );

  static final _addTask = FunctionDeclaration(
    'addTask',
    'Add a new task to the schedule.',
    Schema(
      SchemaType.object,
      properties: {
        'name': Schema(SchemaType.string, description: 'Title of the task'),
        'desc': Schema(
          SchemaType.string,
          description: 'Description or details',
        ),
        'task_date': Schema(
          SchemaType.string,
          description: 'Date in YYYY-MM-DD format',
        ),
        'start_time': Schema(
          SchemaType.string,
          description: 'Start time in HH:mm:ss format (optional)',
        ),
        'end_time': Schema(
          SchemaType.string,
          description: 'End time in HH:mm:ss format (optional)',
        ),
        'category': Schema(
          SchemaType.string,
          description: 'Category (e.g., Work, Personal, Health)',
        ),
        'color_value': Schema(
          SchemaType.integer,
          description: 'Color hex value (optional)',
        ),
        'one_time': Schema(
          SchemaType.boolean,
          description: 'Is it a one-time task? Default true',
        ),
        'importance_type': Schema(
          SchemaType.string,
          description: 'Importance level',
          enumValues: ['Low', 'Medium', 'High'],
        ),
      },
      requiredProperties: ['name', 'task_date'],
    ),
  );

  // We need to keep updateTask flexible as user might only change one field
  static final _updateTask = FunctionDeclaration(
    'updateTask',
    'Update an existing task. You must provide the task ID.',
    Schema(
      SchemaType.object,
      properties: {
        'id': Schema(
          SchemaType.string,
          description: 'The unique ID of the task to update',
        ),
        'name': Schema(SchemaType.string, description: 'New title'),
        'desc': Schema(SchemaType.string, description: 'New description'),
        'task_date': Schema(
          SchemaType.string,
          description: 'New date YYYY-MM-DD',
        ),
        'start_time': Schema(
          SchemaType.string,
          description: 'New start time HH:mm:ss',
        ),
        'end_time': Schema(
          SchemaType.string,
          description: 'New end time HH:mm:ss',
        ),
        'completed': Schema(
          SchemaType.boolean,
          description: 'Mark as completed (true) or pending (false)',
        ),
        'importance_type': Schema(
          SchemaType.string,
          description: 'New importance level',
          enumValues: ['Low', 'Medium', 'High'],
        ),
      },
      requiredProperties: ['id'],
    ),
  );

  static final _deleteTask = FunctionDeclaration(
    'deleteTask',
    'Delete a task by ID.',
    Schema(
      SchemaType.object,
      properties: {
        'id': Schema(
          SchemaType.string,
          description: 'The unique ID of the task to delete',
        ),
      },
      requiredProperties: ['id'],
    ),
  );

  static final _searchTasks = FunctionDeclaration(
    'searchTasks',
    'Search for tasks using a query string (semantic or keyword). Use this when the user asks to "find" something or asks a question about their tasks that isn\'t just "what is on date X".',
    Schema(
      SchemaType.object,
      properties: {
        'query': Schema(SchemaType.string, description: 'The search query'),
      },
      requiredProperties: ['query'],
    ),
  );
}
