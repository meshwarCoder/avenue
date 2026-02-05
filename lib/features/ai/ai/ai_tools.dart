class AiTools {
  static List<Map<String, dynamic>> get declarations => [
    {
      'name': 'getTasks',
      'description':
          'Fetch tasks for a specific date or date range. Use this for specific schedule questions (e.g., "What do I have today?", "Show me tomorrow").',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'startDate': {
            'type': 'STRING',
            'description': 'The start date in YYYY-MM-DD format.',
          },
          'endDate': {
            'type': 'STRING',
            'description': 'Optional end date for ranges in YYYY-MM-DD format.',
          },
        },
        'required': ['startDate'],
      },
    },
    {
      'name': 'searchTasks',
      'description':
          'Semantic search for tasks by topic or meaning. Use this when the user asks about a specific activity (e.g., "Do I have gym?", "When did I study?").',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'query': {
            'type': 'STRING',
            'description': 'The search query or topic.',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'searchDefaultTasks',
      'description': 'Search within recurring (default) tasks/habits.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'query': {'type': 'STRING', 'description': 'The search query.'},
        },
        'required': ['query'],
      },
    },
    {
      'name': 'addTask',
      'description': 'Create a new task on a specific date.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'date': {'type': 'STRING', 'description': 'YYYY-MM-DD'},
          'startTime': {'type': 'STRING', 'description': 'HH:mm'},
          'endTime': {'type': 'STRING', 'description': 'HH:mm'},
          'importance': {
            'type': 'STRING',
            'enum': ['Low', 'Medium', 'High'],
          },
          'note': {'type': 'STRING'},
        },
        'required': ['name', 'date', 'startTime', 'endTime'],
      },
    },
    {
      'name': 'updateTask',
      'description': 'Update an existing task status or details.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'id': {'type': 'STRING'},
          'name': {'type': 'STRING'},
          'isDone': {'type': 'BOOLEAN'},
          'date': {'type': 'STRING', 'description': 'YYYY-MM-DD'},
        },
        'required': ['id'],
      },
    },
    {
      'name': 'deleteTask',
      'description': 'Delete a task by its ID.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'id': {'type': 'STRING'},
        },
        'required': ['id'],
      },
    },
    {
      'name': 'addDefaultTask',
      'description': 'Create a new recurring (default) task/habit.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'weekdays': {
            'type': 'ARRAY',
            'items': {'type': 'INTEGER'},
            'description': '1=Monday, 7=Sunday',
          },
          'startTime': {'type': 'STRING', 'description': 'HH:mm'},
          'endTime': {'type': 'STRING', 'description': 'HH:mm'},
          'importance': {
            'type': 'STRING',
            'enum': ['Low', 'Medium', 'High'],
          },
          'note': {'type': 'STRING'},
        },
        'required': ['name', 'weekdays', 'startTime', 'endTime'],
      },
    },
    {
      'name': 'updateDefaultTask',
      'description': 'Update a recurring (default) task template.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'id': {'type': 'STRING'},
          'name': {'type': 'STRING'},
          'weekdays': {
            'type': 'ARRAY',
            'items': {'type': 'INTEGER'},
          },
          'startTime': {'type': 'STRING', 'description': 'HH:mm'},
          'endTime': {'type': 'STRING', 'description': 'HH:mm'},
        },
        'required': ['id'],
      },
    },
    {
      'name': 'deleteDefaultTask',
      'description': 'Delete a recurring (default) task template.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'id': {'type': 'STRING'},
        },
        'required': ['id'],
      },
    },
  ];
}
