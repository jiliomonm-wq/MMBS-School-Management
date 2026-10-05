import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'owner_dashboard.dart';
import 'theme_widgets.dart';

class MainScreen extends StatefulWidget {
  final UserProfile user;
  final String lang;
  final String Function(String) t;
  final VoidCallback onToggleLang, onLogout;

  const MainScreen({
    super.key,
    required this.user,
    required this.lang,
    required this.t,
    required this.onToggleLang,
    required this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String t(String k) => widget.t(k);

  // Firestore ထဲ တာဝန်/Homework အသစ်ထည့်ခြင်း
  Future<void> assignTask(String title, String subject, String targetGrade, DateTime dueDate, String imageUrl) async {
    final newTask = SchoolTask(
      id: '',
      title: title,
      subject: subject,
      targetGrade: targetGrade,
      teacherId: widget.user.id,
      teacherName: widget.user.name,
      dueDate: dueDate,
      taskImageUrl: imageUrl,
    );

    await _firestore.collection('tasks').add(newTask.toMap());
    _snack('${t('assign_task')} ✓');
  }

  // ကျောင်းသားဘက်မှ အဖြေတင်သွင်းခြင်း
  Future<void> submitTask(String taskId, String answer, String studentName, String imageUrl) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': 'submitted',
      'submission': answer,
      'submittedBy': studentName,
      'submissionImageUrl': imageUrl,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    _snack('${t('submit_task')} ✓');
  }

  // တိုင်ကြားစာ Firebase သို့ ပို့ခြင်း
  Future<void> addComplaint(String title, String desc, String role, String name) async {
    final complaint = Complaint(title: title, desc: desc, fromRole: role, fromName: name);
    await _firestore.collection('complaints').add(complaint.toMap());
    _snack('${t('submit')} ✓');
  }

  // သတင်းကြေညာချက် အသစ်ထုတ်ပြန်ခြင်း
  Future<void> addAnnouncement(String title, String content, String target) async {
    final ann = Announcement(title: title, content: content, target: target);
    await _firestore.collection('announcements').add(ann.toMap());
    _snack('${t('create_announcement')} ✓');
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tasks').snapshots(),
      builder: (context, taskSnapshot) {
        final tasks = taskSnapshot.hasData
            ? taskSnapshot.data!.docs.map((d) => SchoolTask.fromFirestore(d)).toList()
            : <SchoolTask>[];

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('announcements').snapshots(),
          builder: (context, annSnapshot) {
            final announcements = annSnapshot.hasData
                ? annSnapshot.data!.docs.map((d) => Announcement.fromFirestore(d)).toList()
                : <Announcement>[];

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('complaints').snapshots(),
              builder: (context, compSnapshot) {
                final complaints = compSnapshot.hasData
                    ? compSnapshot.data!.docs.map((d) => Complaint.fromFirestore(d)).toList()
                    : <Complaint>[];

                Widget page;
                final role = widget.user.role;

                if (role == 'Student') {
                  page = StudentDashboard(
                    user: widget.user,
                    lang: widget.lang,
                    t: t,
                    onToggleLang: widget.onToggleLang,
                    announcements: announcements,
                    tasks: tasks,
                    onComplain: () => _showComplaint('Student'),
                    onSubmitTask: submitTask,
                    onUpdateAvatar: (url) {},
                    onLogout: widget.onLogout,
                  );
                } else if (role == 'Teacher') {
                  page = TeacherDashboard(
                    user: widget.user,
                    lang: widget.lang,
                    t: t,
                    onToggleLang: widget.onToggleLang,
                    announcements: announcements,
                    tasks: tasks,
                    onComplain: () => _showComplaint('Teacher'),
                    onAssignTask: assignTask,
                    onUpdateAvatar: (url) {},
                    onLogout: widget.onLogout,
                  );
                } else {
                  page = OwnerDashboard(
                    user: widget.user,
                    lang: widget.lang,
                    t: t,
                    onToggleLang: widget.onToggleLang,
                    complaints: complaints,
                    announcements: announcements,
                    tasks: tasks,
                    allUsers: const [],
                    onAddAnnouncement: addAnnouncement,
                    onUpdateAvatar: (url) {},
                    onUpdateUser: (u) {},
                    onAddUser: (u) {},
                    onLogout: widget.onLogout,
                  );
                }

                return LightBackground(child: page);
              },
            );
          },
        );
      },
    );
  }

  void _showComplaint(String role) {
    final tc = TextEditingController();
    final dc = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t('complaint'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: tc,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: t('title'),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dc,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: t('desc'),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(t('cancel'), style: const TextStyle(color: AppColors.textSecondary))),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  if (tc.text.isNotEmpty) {
                    addComplaint(tc.text, dc.text, role, widget.user.name);
                    Navigator.pop(c);
                  }
                },
                child: Text(t('submit')),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
