class AiTools {
  static List<Map<String, dynamic>> get declarations => [
    {
      'name': 'getSchedule',
      'description':
          'Fetch schedule for a specific date or date range. This is the PRIMARY tool for all time-based questions. Returns both normal tasks and recurring habits/default tasks by default. Past dates only return normal tasks.',
      'parameters': {
        'type': 'object',
        'properties': {
          'startDate': {
            'type': 'string',
            'description': 'The start date in YYYY-MM-DD format.',
          },
          'endDate': {
            'type': 'string',
            'description': 'Optional end date for ranges in YYYY-MM-DD format.',
          },
          'type': {
            'type': 'string',
            'enum': ['all', 'task', 'default'],
            'description':
                'Filter by type: "all" (default), "task" (non-recurring), or "default" (habits/recurring).',
          },
        },
        'required': ['startDate'],
      },
    },
    {
      'name': 'searchSchedule',
      'description':
          'Semantic search for tasks or habits by topic, name, or meaning. Use this when the user asks about a specific activity without specifying a date.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query or topic.',
          },
          'type': {
            'type': 'string',
            'enum': ['all', 'task', 'default'],
            'description':
                'Filter by type: "all" (default), "task" (non-recurring), or "default" (habits/recurring).',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'manageSchedule',
      'description':
          'Unified tool to create or update one-time tasks and recurring habits. Use this for ALL modifications to the schedule.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['create', 'update'],
            'description':
                'Whether to create a new entry or update an existing one.',
          },
          'type': {
            'type': 'string',
            'enum': ['task', 'default'],
            'description':
                '"task" for one-time entries, "default" for recurring habits.',
          },
          'id': {
            'type': 'string',
            'description': 'Required ONLY for "update" action.',
          },
          'name': {'type': 'string'},
          'date': {
            'type': 'string',
            'description': 'YYYY-MM-DD (Required for type="task").',
          },
          'startTime': {
            'type': 'string',
            'description': 'HH:mm (Required for create).',
          },
          'endTime': {'type': 'string', 'description': 'HH:mm.'},
          'weekdays': {
            'type': 'array',
            'items': {'type': 'integer'},
            'description':
                '1=Mon, 7=Sun (Required for create where type="default").',
          },
          'importance': {
            'type': 'string',
            'enum': ['Low', 'Medium', 'High'],
          },
          'note': {'type': 'string'},
          'category': {
            'type': 'string',
            'enum': ['Work', 'Meeting', 'Personal', 'Health', 'Other'],
          },
          'isDone': {'type': 'boolean', 'description': 'Only for type="task".'},
          'isDeleted': {
            'type': 'boolean',
            'description': 'Set to true to delete the task or habit.',
          },
        },
        'required': ['action', 'type'],
      },
    },
  ];
}
