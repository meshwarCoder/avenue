enum AiIntent {
  search,
  create,
  update,
  delete,
  reorder,
  settings,
  chat,
  unknown;

  static AiIntent fromString(String intent) {
    return AiIntent.values.firstWhere(
      (e) => e.name == intent.toLowerCase(),
      orElse: () => AiIntent.unknown,
    );
  }
}
