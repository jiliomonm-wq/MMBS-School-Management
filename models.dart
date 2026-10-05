import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String name, id, role, className, email, password;
  String avatarUrl;
  int age, leaveDays;
  double attendanceRate;
  String location, contact, parentName, parentPhone, gradesTaught, skills, experience;

  UserProfile({
    required this.name,
    required this.id,
    required this.role,
    this.className = '',
    this.email = '',
    this.password = '1234',
    this.avatarUrl = '',
    this.age = 15,
    this.leaveDays = 0,
    this.attendanceRate = 0.95,
    this.location = '',
    this.contact = '',
    this.parentName = '',
    this.parentPhone = '',
    this.gradesTaught = '',
    this.skills = '',
    this.experience = '',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'id': id,
    'role': role,
    'className': className,
    'email': email,
    'password': password,
    'avatarUrl': avatarUrl,
    'age': age,
    'leaveDays': leaveDays,
    'attendanceRate': attendanceRate,
    'location': location,
    'contact': contact,
    'parentName': parentName,
    'parentPhone': parentPhone,
    'gradesTaught': gradesTaught,
    'skills': skills,
    'experience': experience,
  };

  factory UserProfile.fromFirestore(Map<String, dynamic> map, String docId) {
    return UserProfile(
      name: map['name'] ?? '',
      id: docId,
      role: map['role'] ?? 'Student',
      className: map['className'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '1234',
      avatarUrl: map['avatarUrl'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 15,
      leaveDays: (map['leaveDays'] as num?)?.toInt() ?? 0,
      attendanceRate: (map['attendanceRate'] as num?)?.toDouble() ?? 0.95,
      location: map['location'] ?? '',
      contact: map['contact'] ?? '',
      parentName: map['parentName'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      gradesTaught: map['gradesTaught'] ?? '',
      skills: map['skills'] ?? '',
      experience: map['experience'] ?? '',
    );
  }
}

class SchoolTask {
  final String id, title, subject, targetGrade, teacherId, teacherName;
  final DateTime dueDate;
  String status, submission, submittedBy, taskImageUrl, submissionImageUrl;

  SchoolTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.targetGrade,
    required this.teacherId,
    required this.teacherName,
    required this.dueDate,
    this.status = 'pending',
    this.submission = '',
    this.submittedBy = '',
    this.taskImageUrl = '',
    this.submissionImageUrl = '',
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'subject': subject,
    'targetGrade': targetGrade,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'dueDate': Timestamp.fromDate(dueDate),
    'status': status,
    'submission': submission,
    'submittedBy': submittedBy,
    'taskImageUrl': taskImageUrl,
    'submissionImageUrl': submissionImageUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory SchoolTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SchoolTask(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      targetGrade: data['targetGrade'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      submission: data['submission'] ?? '',
      submittedBy: data['submittedBy'] ?? '',
      taskImageUrl: data['taskImageUrl'] ?? '',
      submissionImageUrl: data['submissionImageUrl'] ?? '',
    );
  }
}

class Complaint {
  final String title, desc, fromRole, fromName;
  Complaint({required this.title, required this.desc, required this.fromRole, required this.fromName});

  Map<String, dynamic> toMap() => {
    'title': title,
    'desc': desc,
    'fromRole': fromRole,
    'fromName': fromName,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Complaint(
      title: data['title'] ?? '',
      desc: data['desc'] ?? '',
      fromRole: data['fromRole'] ?? '',
      fromName: data['fromName'] ?? '',
    );
  }
}

class Announcement {
  final String title, content, target;
  Announcement({required this.title, required this.content, required this.target});

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'target': target,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Announcement(
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      target: data['target'] ?? 'all',
    );
  }
}
