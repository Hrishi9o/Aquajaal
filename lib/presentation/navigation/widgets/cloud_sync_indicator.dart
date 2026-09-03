import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/services/cloud_sync_service.dart';

/// App bar button displaying live cloud synchronization status
class CloudSyncIndicator extends StatefulWidget {
  final bool compact;
  const CloudSyncIndicator({super.key, this.compact = false});

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

    Color iconColor;
    IconData iconData;
    String tooltip;

    switch (sync.status) {
      case SyncStatus.synced:
        iconColor = AppColors.accentDark;
        iconData = Icons.cloud_done_rounded;
        tooltip = 'Cloud Synchronized — All data up to date';
        break;
      case SyncStatus.syncing:
        iconColor = AppColors.primary;
        iconData = Icons.sync_rounded;
        tooltip = 'Synchronizing with cloud...';
        break;
      case SyncStatus.offline:
        iconColor = isDark ? Colors.white60 : Colors.grey.shade600;
        iconData = Icons.cloud_off_rounded;
        tooltip = 'Offline Mode — Invoices and stock saved locally on device';
        break;
      case SyncStatus.error:
        iconColor = AppColors.error;
        iconData = Icons.cloud_off_rounded;
        tooltip = 'Sync Error: ${sync.lastError ?? "Check internet & Firebase URL"}';
        break;
      case SyncStatus.idle:
      default:
        iconColor = isDark ? Colors.white60 : Colors.grey.shade600;
        iconData = Icons.cloud_queue_rounded;
        tooltip = 'Cloud Sync Ready';
        break;
    }

    final iconWidget = sync.status == SyncStatus.syncing
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
          )
        : Icon(iconData, color: iconColor, size: 20);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _showSyncDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: widget.compact
              ? iconWidget
              : Row(
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final timeFormatter = DateFormat('dd-MMM-yyyy hh:mm a');
          final lastSyncStr = sync.lastSyncTime != null
              ? timeFormatter.format(sync.lastSyncTime!)
              : 'Not synced yet';

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Icon, Title, and Close Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Multi-Device Cloud Sync',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Status & Last Synced Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sync.status == SyncStatus.synced
                                      ? AppColors.accentDark
                                      : (sync.status == SyncStatus.offline ? Colors.grey : AppColors.error),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${sync.status == SyncStatus.offline ? 'OFFLINE — Local storage active' : sync.status.name.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: sync.status == SyncStatus.synced
                                      ? AppColors.accentDark
                                      : (sync.status == SyncStatus.offline ? Colors.grey : AppColors.error),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last Synced: $lastSyncStr',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),

                    if (sync.status == SyncStatus.offline) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No internet connection. Data is safe on device and will sync automatically when online.',
                                style: TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (sync.lastError != null && sync.status == SyncStatus.error) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sync.lastError!.length > 120
                              ? '${sync.lastError!.substring(0, 120)}...'
                              : sync.lastError!,
                          style: const TextStyle(fontSize: 11, color: AppColors.error),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Endpoint URL
                    const Text(
                      'Firebase / Cloud Sync Endpoint URL:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        hintText: 'https://<project>-default-rtdb.firebaseio.com',
                        prefixIcon: Icon(Icons.link_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),

                    // Auto-sync switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Sync on New Sales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Syncs invoices immediately when created', style: TextStyle(fontSize: 11)),
                      value: autoSync,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => autoSync = val),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
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
                            label: const Text('Sync Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              sync.configure(url: urlController.text, autoSync: autoSync);
                              AppToast.success(context, '✓ Cloud sync configuration saved');
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
