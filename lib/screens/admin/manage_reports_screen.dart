import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/firestore_paths.dart';
import '../../models/report_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/firestore_service.dart';

class ManageReportsScreen extends ConsumerWidget {
  const ManageReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageReports),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirestorePaths.reports)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final report = ReportModel.fromDoc(docs[index]);
              return _ReportTile(report: report);
            },
          );
        },
      ),
    );
  }
}

class _ReportTile extends ConsumerWidget {
  final ReportModel report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporterAsync = ref.watch(userStreamByIdProvider(report.reporterId));
    final postAsync = ref.watch(postDetailProvider(report.postId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report reason
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reason,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${report.createdAt.day}/${report.createdAt.month}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reporter
            reporterAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (reporter) => Text(
                'المُبلّغ: ${reporter?.name ?? 'غير معروف'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),

            // Post info
            postAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (post) => post != null
                  ? GestureDetector(
                      onTap: () => context.push('/post/${post.postId}'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'الإعلان: ${post.title}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    // Delete the reported post
                    await FirestoreService().deletePost(report.postId);
                    await FirestoreService().deleteReport(report.id);
                  },
                  child: const Text('حذف الإعلان',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    // Dismiss report
                    await FirestoreService().deleteReport(report.id);
                  },
                  child: const Text('تجاهل البلاغ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
