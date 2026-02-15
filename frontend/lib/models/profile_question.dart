enum AnswerType { text, singleChoice, multiChoice, rating, boolean }

class ProfileQuestion {
  final int id;
  final int sectionId;
  final String question;
  final AnswerType answerType;
  final List<String>? options;
  final int? minWords;
  final int weight;
  final bool isRequired;
  final int orderNo;
  final bool isActive;
  final dynamic savedAnswer;

  final String? sectionName;

  ProfileQuestion({
    required this.id,
    required this.sectionId,
    required this.question,
    required this.answerType,
    this.options,
    this.minWords,
    required this.weight,
    required this.isRequired,
    required this.orderNo,
    required this.isActive,
    this.savedAnswer,
    this.sectionName,
  });

  factory ProfileQuestion.fromJson(Map<String, dynamic> json) {
    dynamic parsedAnswer;
    if (json['answers'] != null && (json['answers'] as List).isNotEmpty) {
      parsedAnswer = json['answers'][0]['answer'];
    }

    return ProfileQuestion(
      id: json['id'],
      sectionId: json['sectionId'],
      question: json['question'],
      answerType: _parseAnswerType(json['answerType']),
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      minWords: json['minWords'],
      weight: json['weight'],
      isRequired: json['isRequired'],
      orderNo: json['orderNo'],
      isActive: json['isActive'],
      savedAnswer: parsedAnswer,
      sectionName: json['section'] != null ? json['section']['title'] : null,
    );
  }

  static AnswerType _parseAnswerType(String type) {
    switch (type) {
      case 'TEXT':
        return AnswerType.text;
      case 'SINGLE_CHOICE':
        return AnswerType.singleChoice;
      case 'MULTI_CHOICE':
        return AnswerType.multiChoice;
      case 'RATING':
        return AnswerType.rating;
      case 'BOOLEAN':
        return AnswerType.boolean;
      default:
        return AnswerType.text;
    }
  }
}
