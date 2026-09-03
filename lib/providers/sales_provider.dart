import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/invoice.dart';
import '../data/services/cloud_sync_service.dart';
import '../data/services/local_db_service.dart';

enum SalesDateFilter { today, yesterday, thisWeek, last7Days, thisMonth, allTime, custom }

class TopSellerItem {
  final String name;
  final int quantity;
  final double revenue;

  TopSellerItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class DailySalesSummary {
  final String dateLabel;
  final int invoiceCount;
  final int unitsSold;
  final double revenue;

  DailySalesSummary({
    required this.dateLabel,
    required this.invoiceCount,
    required this.unitsSold,
    required this.revenue,
  });
}

class SalesTimeBucket {
  final String label;
  final double revenue;
  final int count;

  SalesTimeBucket({
    required this.label,
    required this.revenue,
    required this.count,
  });
}

/// Provider for managing sales analytics, date range filters, and dashboard metrics
class SalesProvider with ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;

  List<Invoice> _allInvoices = [];
  SalesDateFilter _selectedFilter = SalesDateFilter.today;
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();
  String _invoiceSearchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  SalesProvider() {
    refreshInvoices();
    CloudSyncService.instance.addListener(refreshInvoices);
  }

  SalesDateFilter get selectedFilter => _selectedFilter;
  DateTime get customStartDate => _customStartDate;
  DateTime get customEndDate => _customEndDate;
  String get invoiceSearchQuery => _invoiceSearchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void refreshInvoices() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allInvoices = _db.getAllInvoices();
    } catch (e) {
      _errorMessage = 'Failed to load invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(SalesDateFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _selectedFilter = SalesDateFilter.custom;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  void setInvoiceSearchQuery(String query) {
    _invoiceSearchQuery = query;
    notifyListeners();
  }

  String get dateRangeLabel {
    final now = DateTime.now();
    final dFormat = DateFormat('dd-MMM-yyyy');

    switch (_selectedFilter) {
      case SalesDateFilter.today:
        return 'Today (${dFormat.format(now)})';
      case SalesDateFilter.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        return 'Yesterday (${dFormat.format(yest)})';
      case SalesDateFilter.thisWeek:
      case SalesDateFilter.last7Days:
        final start = now.subtract(const Duration(days: 6));
        return '${dFormat.format(start)} to ${dFormat.format(now)}';
      case SalesDateFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case SalesDateFilter.allTime:
        return 'All Time History';
      case SalesDateFilter.custom:
        return '${dFormat.format(_customStartDate)} to ${dFormat.format(_customEndDate)}';
    }
  }

  /// Invoices matching current date filter
  List<Invoice> get filteredInvoices {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_selectedFilter) {
      case SalesDateFilter.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case SalesDateFilter.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        start = DateTime(yest.year, yest.month, yest.day);
        end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
        break;
      case SalesDateFilter.thisWeek:
      case SalesDateFilter.last7Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case SalesDateFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case SalesDateFilter.allTime:
        start = DateTime(2020);
        end = DateTime(2035);
        break;
      case SalesDateFilter.custom:
        start = DateTime(_customStartDate.year, _customStartDate.month, _customStartDate.day);
        end = DateTime(_customEndDate.year, _customEndDate.month, _customEndDate.day, 23, 59, 59);
        break;
    }

    return _allInvoices.where((inv) {
      final matchesDate = !inv.createdAt.isBefore(start) && !inv.createdAt.isAfter(end);
      if (!matchesDate) return false;

      if (_invoiceSearchQuery.isEmpty) return true;

      final q = _invoiceSearchQuery.toLowerCase();
      final matchesNum = inv.invoiceNumber.toLowerCase().contains(q);
      final matchesCustomer = inv.customerName?.toLowerCase().contains(q) ?? false;
      final matchesPhone = inv.customerPhone?.contains(q) ?? false;

      return matchesNum || matchesCustomer || matchesPhone;
    }).toList();
  }

  // --- KPI Aggregations ---

  double get totalRevenue =>
      filteredInvoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  int get totalInvoicesCount => filteredInvoices.length;

  int get totalUnitsSold =>
      filteredInvoices.fold(0, (sum, inv) => sum + inv.totalUnits);

  double get averageOrderValue =>
      totalInvoicesCount > 0 ? totalRevenue / totalInvoicesCount : 0.0;

  // --- Top Sellers ---

  List<TopSellerItem> get topSellersByRevenue {
    final Map<String, _Aggregate> map = {};

    for (final inv in filteredInvoices) {
      for (final item in inv.items) {
        final key = item.displayName;
        map.putIfAbsent(key, () => _Aggregate());
        map[key]!.quantity += item.quantity;
        map[key]!.revenue += item.lineTotal;
      }
    }

    final list = map.entries
        .map((e) => TopSellerItem(
              name: e.key,
              quantity: e.value.quantity,
              revenue: e.value.revenue,
            ))
        .toList();

    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }

  List<TopSellerItem> get topSellersByQuantity {
    final list = List<TopSellerItem>.from(topSellersByRevenue);
    list.sort((a, b) => b.quantity.compareTo(a.quantity));
    return list;
  }

  /// Top 3 products by revenue matching specification
  List<TopSellerItem> get top3ByRevenue => topSellersByRevenue.take(3).toList();

  /// Top 3 products by quantity matching specification
  List<TopSellerItem> get top3ByQuantity => topSellersByQuantity.take(3).toList();

  /// Daily breakdown table aggregation
  List<DailySalesSummary> get dailyBreakdown {
    final Map<String, _DailyAgg> map = {};
    final format = DateFormat('dd-MMM-yyyy');

    for (final inv in filteredInvoices) {
      final key = format.format(inv.createdAt);
      map.putIfAbsent(key, () => _DailyAgg(dateLabel: key));
      map[key]!.invoiceCount++;
      map[key]!.unitsSold += inv.totalUnits;
      map[key]!.revenue += inv.grandTotal;
    }

    return map.values
        .map((e) => DailySalesSummary(
              dateLabel: e.dateLabel,
              invoiceCount: e.invoiceCount,
              unitsSold: e.unitsSold,
              revenue: e.revenue,
            ))
        .toList();
  }

  // --- Time Buckets for Bar Chart ---

  List<SalesTimeBucket> get salesChartData {
    if (_selectedFilter == SalesDateFilter.today) {
      // Group by hours (e.g. 8 AM - 8 PM in 2-hour blocks)
      final List<SalesTimeBucket> buckets = [];
      for (int hour = 8; hour <= 20; hour += 2) {
        final label = '${hour > 12 ? hour - 12 : hour}${hour >= 12 ? 'PM' : 'AM'}';
        double rev = 0;
        int count = 0;

        for (final inv in filteredInvoices) {
          if (inv.createdAt.hour >= hour && inv.createdAt.hour < hour + 2) {
            rev += inv.grandTotal;
            count++;
          }
        }
        buckets.add(SalesTimeBucket(label: label, revenue: rev, count: count));
      }
      return buckets;
    } else {
      // Group by day
      final Map<String, SalesTimeBucket> map = {};
      final invoices = filteredInvoices;

      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final key = '${date.day}/${date.month}';
        map[key] = SalesTimeBucket(label: key, revenue: 0, count: 0);
      }

      for (final inv in invoices) {
        final key = '${inv.createdAt.day}/${inv.createdAt.month}';
        if (map.containsKey(key)) {
          final existing = map[key]!;
          map[key] = SalesTimeBucket(
            label: key,
            revenue: existing.revenue + inv.grandTotal,
            count: existing.count + 1,
          );
        }
      }

      return map.values.toList();
    }
  }
}

class _Aggregate {
  int quantity = 0;
  double revenue = 0.0;
}

class _DailyAgg {
  final String dateLabel;
  int invoiceCount = 0;
  int unitsSold = 0;
  double revenue = 0.0;

  _DailyAgg({required this.dateLabel});
}
