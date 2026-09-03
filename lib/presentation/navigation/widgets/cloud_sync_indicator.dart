import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/services/cloud_sync_service.dart';

/// App bar button displaying live cloud synchronization status between brother's counter phone & father's device
class CloudSyncIndicator extends StatefulWidget {
  const CloudSyncIndicator({super.key});

  @override
  State<CloudSyncIndicator> createState() => _CloudSyncIndicatorState();
}

class _CloudSyncIndicatorState extends State<CloudSyncIndicator> {
  @override
  void initState() {
    super.initState();
    CloudSyncService.instance.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    CloudSyncService.instance.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sync = CloudSyncService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget;
    Color iconColor;
    String tooltip;

    switch (sync.status) {
      case SyncStatus.synced:
        iconWidget = const Icon(Icons.cloud_done_rounded, size: 20);
        iconColor = AppColors.accentDark;
        tooltip = 'Synced with Cloud';
        break;
      case SyncStatus.syncing:
        iconWidget = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
        iconColor = Colors.white;
        tooltip = 'Syncing data...';
        break;
      case SyncStatus.error:
        iconWidget = const Icon(Icons.cloud_off_rounded, size: 20);
        iconColor = AppColors.warning;
        tooltip = 'Sync error / Offline';
        break;
      case SyncStatus.offline:
      case SyncStatus.idle:
        iconWidget = const Icon(Icons.cloud_outlined, size: 20);
        iconColor = isDark ? Colors.white70 : Colors.black54;
        tooltip = 'Cloud Sync Ready';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _showSyncDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Text(
                sync.status == SyncStatus.syncing
                    ? 'Syncing...'
                    : (sync.status == SyncStatus.synced ? 'Synced' : 'Cloud Sync'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    final sync = CloudSyncService.instance;
    final urlController = TextEditingController(text: sync.cloudUrl);
    bool autoSync = sync.autoSyncEnabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final timeFormatter = DateFormat('dd-MMM-yyyy hh:mm a');
          final lastSyncStr = sync.lastSyncTime != null
              ? timeFormatter.format(sync.lastSyncTime!)
              : 'Not synced yet';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Multi-Device Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Allows brother at counter & father anywhere to view live sales and stock in real time.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Status: ${sync.status.name.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Last Synced: $lastSyncStr',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (sync.lastError != null) ...[
                      const SizedBox(height: 8),
                      Text('Error: ${sync.lastError}',
                          style: const TextStyle(fontSize: 11, color: AppColors.error)),
                    ],
                    const Divider(height: 24),
                    const Text('Firebase / Cloud Sync Endpoint URL:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        hintText: 'https://<project>-default-rtdb.firebaseio.com',
                        prefixIcon: Icon(Icons.link_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Sync on New Sales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Syncs invoices immediately when created', style: TextStyle(fontSize: 11)),
                      value: autoSync,
                      onChanged: (val) => setDialogState(() => autoSync = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  sync.configure(url: urlController.text, autoSync: autoSync);
                  final success = await sync.triggerFullSync();
                  if (ctx.mounted) {
                    if (success) {
                      AppToast.success(ctx, '✓ Data synchronized with cloud');
                    } else {
                      AppToast.warning(ctx, 'Sync completed locally (offline)');
                    }
                    Navigator.of(ctx).pop();
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Now'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  sync.configure(url: urlController.text, autoSync: autoSync);
                  AppToast.success(context, '✓ Cloud sync configuration saved');
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save Settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
