class AiTools {
  static List<Map<String, dynamic>> get declarations => [
    {
      'name': 'getSchedule',
      'description':
          'Fetch schedule for a specific date or date range. Returns both normal tasks and recurring habits by default. Past dates only return normal tasks.',
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
                'Filter by type: "all" (default), "task" (one-time tasks), or "default" (recurring habits).',
          },
        },
        'required': ['startDate'],
      },
    },
    {
      'name': 'searchSchedule',
      'description':
          'Semantic search for tasks or habits by topic, name, or meaning. Use when the user asks about a specific activity without specifying a date.',
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
                'Filter by type: "all" (default), "task" (one-time tasks), or "default" (recurring habits).',
          },
        },
        'required': ['query'],
      },
    },
    {
      'name': 'manageSchedule',
      'description':
          'Propose creating, updating, or deleting a one-time task or recurring habit. The proposed action is NOT executed immediately — it is presented to the user for confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['create', 'update', 'delete'],
            'description':
                '"create" for new entries, "update" to modify existing, "delete" to remove. Delete only requires type + id.',
          },
          'type': {
            'type': 'string',
            'enum': ['task', 'default'],
            'description':
                '"task" for one-time entries, "default" for recurring habits.',
          },
          'id': {
            'type': 'string',
            'description':
                'Required for "update" and "delete" actions. Must be a real UUID retrieved from getSchedule or searchSchedule.',
          },
          'name': {
            'type': 'string',
            'description': 'Name of the task or habit.',
          },
          'date': {
            'type': 'string',
            'description': 'YYYY-MM-DD. Required for type="task" on create.',
          },
          'startTime': {
            'type': 'string',
            'description': 'HH:mm. Required for create.',
          },
          'endTime': {
            'type': 'string',
            'description': 'HH:mm. Defaults to startTime + 1 hour if omitted.',
          },
          'weekdays': {
            'type': 'array',
            'items': {'type': 'integer'},
            'description':
                '1=Mon, 7=Sun. Required for create where type="default".',
          },
          'importance': {
            'type': 'string',
            'enum': ['Low', 'Medium', 'High'],
          },
          'note': {'type': 'string'},
          'category': {
            'type': 'string',
            'enum': [
              'Work',
              'Meeting',
              'Personal',
              'Health',
              'Study',
              'Finance',
              'Social',
              'Other',
            ],
          },
          'isDone': {
            'type': 'boolean',
            'description': 'Mark task as complete. Only for type="task".',
          },
        },
        'required': ['action', 'type'],
      },
    },
  ];
}
