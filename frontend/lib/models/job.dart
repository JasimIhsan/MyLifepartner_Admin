class JobModel {
  final int id;
  final String name;

  const JobModel({required this.id, required this.name});

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
