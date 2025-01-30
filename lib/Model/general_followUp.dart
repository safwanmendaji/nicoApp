class GeneralFollowUp {
  final int generalFollowUpId;
  final String generalFollowUpName;
  final FollowUpPerson followUpPerson;
  final CreatedBy createdBy;
  final UpdatedBy? updatedBy;
  final String description;
  final String? status;
  final String? statusNotes;
  final String? dueDate;
  final String? createdAt;
  final String? updatedAt;

  GeneralFollowUp(
      {required this.generalFollowUpId,
      required this.generalFollowUpName,
      required this.followUpPerson,
      required this.createdBy,
      this.updatedBy,
      required this.description,
      this.status,
      this.statusNotes,
      this.dueDate,
      this.createdAt,
      this.updatedAt});

  factory GeneralFollowUp.fromJson(Map<String, dynamic> json) {
    return GeneralFollowUp(
      generalFollowUpId: json['generalFollowUpId'],
      generalFollowUpName: json['generalFollowUpName'],
      followUpPerson: FollowUpPerson.fromJson(json['followUpPerson']),
      createdBy: CreatedBy.fromJson(json['createdBy']),
      updatedBy: json['updatedBy'] != null
          ? UpdatedBy.fromJson(json['updatedBy'] as Map<String, dynamic>)
          : null,
      description: json['description'],
      status: json['status'],
      statusNotes: json['statusNotes'],
      dueDate: json['dueDate'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class FollowUpPerson {
  final int id;
  final String name;
  final String email;
  final String designation;
  final String mobileNo;

  FollowUpPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.mobileNo,
  });

  factory FollowUpPerson.fromJson(Map<String, dynamic> json) {
    return FollowUpPerson(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      designation: json['designation'],
      mobileNo: json['mobileNo'],
    );
  }
}

class CreatedBy {
  final int id;
  final String name;
  final String email;
  final String designation;
  final String mobileNo;

  CreatedBy({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.mobileNo,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      designation: json['designation'],
      mobileNo: json['mobileNo'],
    );
  }
}

class UpdatedBy {
  final int id;
  final String name;
  final String email;
  final String designation;
  final String mobileNo;

  UpdatedBy({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.mobileNo,
  });

  factory UpdatedBy.fromJson(Map<String, dynamic> json) {
    return UpdatedBy(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      designation: json['designation'],
      mobileNo: json['mobileNo'],
    );
  }
}
