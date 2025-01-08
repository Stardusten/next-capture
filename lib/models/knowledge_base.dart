class KnowledgeBase {
  final String name;
  final String location;

  KnowledgeBase({
    required this.name,
    required this.location,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      name: json['name'] as String,
      location: json['location'] as String,
    );
  }
}
