import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Safety actions remain available for both owner and member accounts.
class AccountSafetyActions extends ConsumerWidget {
  const AccountSafetyActions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      SecondaryButton(
        label: 'Người dùng đã chặn',
        icon: Icons.block,
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _BlockedUsersDialog(),
        ),
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        key: const Key('deleteAccount'),
        label: 'Xóa tài khoản',
        icon: Icons.person_remove_outlined,
        destructive: true,
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _DeleteAccountDialog(),
        ),
      ),
    ],
  );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();
  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  bool busy = false;
  bool confirmed = false;
  String? error;
  Future<void> remove() async {
    if (busy || !confirmed) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).deleteAccount();
      await ref.read(authProvider.notifier).logout();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = ApiError.from(e).message;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Xóa tài khoản vĩnh viễn?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tài khoản đăng nhập và dữ liệu cá nhân sẽ bị xóa. Coins, vật phẩm và nhật ký sẽ mất. Phiên đang tham gia sẽ kết thúc đối với bạn. Nhóm bạn quản lý sẽ giải thể. Một số bản ghi phiên được giữ lại dưới dạng ẩn danh. Không thể hoàn tác.',
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi hiểu và muốn xóa tài khoản'),
              value: confirmed,
              onChanged: busy
                  ? null
                  : (v) => setState(() => confirmed = v ?? false),
            ),
            if (error != null) AppBanner(tone: BannerTone.danger, text: error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Giữ tài khoản'),
        ),
        FilledButton(
          key: const Key('confirmDeleteAccount'),
          onPressed: busy || !confirmed ? null : remove,
          child: Text(busy ? 'Đang xóa…' : 'Xóa vĩnh viễn'),
        ),
      ],
    ),
  );
}

class PublicSafetyActions extends ConsumerStatefulWidget {
  const PublicSafetyActions({super.key, required this.userId});
  final String userId;
  @override
  ConsumerState<PublicSafetyActions> createState() =>
      _PublicSafetyActionsState();
}

class _PublicSafetyActionsState extends ConsumerState<PublicSafetyActions> {
  bool busy = false;
  Future<void> block() async {
    final yes = await showConfirmDialog(
      context,
      title: 'Chặn người dùng?',
      message:
          'Ẩn hồ sơ công khai và thông tin nhận diện trong danh sách thành viên của nhau. Bạn vẫn có thể cùng thuộc một nhóm; thao tác này không xóa thành viên khỏi nhóm.',
      confirmLabel: 'Chặn',
      destructive: true,
    );
    if (!yes || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await ref.read(apiProvider).blockUser(widget.userId);
      ref.invalidate(membersProvider);
      ref.invalidate(publicProfileProvider);
      if (mounted) {
        showSnack(context, 'Đã chặn người dùng.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SecondaryButton(
        label: 'Báo cáo người dùng',
        icon: Icons.flag_outlined,
        onPressed: busy
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => _ReportDialog(userId: widget.userId),
              ),
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Chặn người dùng',
        icon: Icons.block,
        destructive: true,
        loading: busy,
        onPressed: busy ? null : block,
      ),
    ],
  );
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({required this.userId});
  final String userId;
  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  final details = TextEditingController();
  String reason = 'INAPPROPRIATE_CONTENT';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(apiProvider)
          .reportUser(widget.userId, reason, details.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        showSnack(context, 'Đã gửi báo cáo để xem xét.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = ApiError.from(e).message;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Báo cáo người dùng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: reason,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Lý do'),
              items: const [
                DropdownMenuItem(
                  value: 'INAPPROPRIATE_CONTENT',
                  child: Text('Nội dung không phù hợp'),
                ),
                DropdownMenuItem(value: 'HARASSMENT', child: Text('Quấy rối')),
                DropdownMenuItem(value: 'SPAM', child: Text('Spam')),
                DropdownMenuItem(value: 'OTHER', child: Text('Lý do khác')),
              ],
              onChanged: busy ? null : (v) => setState(() => reason = v!),
            ),
            TextField(
              controller: details,
              enabled: !busy,
              maxLength: 2000,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Chi tiết (không bắt buộc)',
                helperText: 'Không gửi mật khẩu hoặc thông tin nhạy cảm.',
              ),
            ),
            if (error != null) AppBanner(tone: BannerTone.danger, text: error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: busy ? null : send,
          child: Text(busy ? 'Đang gửi…' : 'Gửi báo cáo'),
        ),
      ],
    ),
  );
}

class _BlockedUsersDialog extends ConsumerStatefulWidget {
  const _BlockedUsersDialog();
  @override
  ConsumerState<_BlockedUsersDialog> createState() =>
      _BlockedUsersDialogState();
}

class _BlockedUsersDialogState extends ConsumerState<_BlockedUsersDialog> {
  List<Map<String, dynamic>>? users;
  String? error;
  String? busyId;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await ref.read(apiProvider).blockedUsers();
      if (mounted) {
        setState(() {
          users = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = ApiError.from(e).message);
    }
  }

  Future<void> unblock(String id) async {
    setState(() => busyId = id);
    try {
      await ref.read(apiProvider).unblockUser(id);
      ref.invalidate(membersProvider);
      ref.invalidate(publicProfileProvider);
      if (mounted) {
        setState(() => users!.removeWhere((u) => u['user_id'] == id));
      }
    } catch (e) {
      if (mounted) setState(() => error = ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Người dùng đã chặn'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              AppBanner(
                tone: BannerTone.danger,
                text: error!,
                action: 'Thử lại',
                onAction: load,
              ),
            if (users == null && error == null)
              const CircularProgressIndicator(),
            if (users != null && users!.isEmpty)
              const Text('Bạn chưa chặn người dùng nào.'),
            for (final u in users ?? <Map<String, dynamic>>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${u['display_name'] ?? 'Người dùng ${u['user_id']}'}',
                ),
                trailing: TextButton(
                  onPressed: busyId != null
                      ? null
                      : () => unblock('${u['user_id']}'),
                  child: Text(
                    busyId == u['user_id'] ? 'Đang xử lý…' : 'Bỏ chặn',
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busyId != null ? null : () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
    ],
  );
}
