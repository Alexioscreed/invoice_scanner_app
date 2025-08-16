import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      invoiceProvider.loadInvoices(),
      notificationProvider.loadNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tailwind slate-50
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B), // Tailwind slate-800
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFF64748B).withOpacity(0.1),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF475569), // Tailwind slate-600
                    ),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (notificationProvider.hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444), // Tailwind red-500
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF475569), // Tailwind slate-600
            ),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF3B82F6), // Tailwind blue-500
        backgroundColor: Colors.white,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B82F6), // Tailwind blue-500
                      Color(0xFF1D4ED8), // Tailwind blue-700
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(
                          'Welcome back!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your invoices efficiently',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBFDBFE), // Tailwind blue-200
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Statistics cards
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Tailwind slate-800
                ),
              ),
              const SizedBox(height: 16),
              Consumer<InvoiceProvider>(
                builder: (context, invoiceProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Invoices',
                          value: '${invoiceProvider.totalCount}',
                          icon: Icons.receipt_long,
                          color: const Color(0xFF3B82F6), // Tailwind blue-500
                          backgroundColor: const Color(
                            0xFFDBEAFE,
                          ), // Tailwind blue-100
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Amount',
                          value:
                              '\$${invoiceProvider.totalAmount.toStringAsFixed(2)}',
                          icon: Icons.attach_money,
                          color: const Color(
                            0xFF10B981,
                          ), // Tailwind emerald-500
                          backgroundColor: const Color(
                            0xFFD1FAE5,
                          ), // Tailwind emerald-100
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Consumer<InvoiceProvider>(
                builder: (context, invoiceProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Paid',
                          value: '${invoiceProvider.paidCount}',
                          icon: Icons.check_circle,
                          color: const Color(
                            0xFF10B981,
                          ), // Tailwind emerald-500
                          backgroundColor: const Color(
                            0xFFD1FAE5,
                          ), // Tailwind emerald-100
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: '${invoiceProvider.pendingCount}',
                          icon: Icons.schedule,
                          color: const Color(0xFFF59E0B), // Tailwind amber-500
                          backgroundColor: const Color(
                            0xFFFEF3C7,
                          ), // Tailwind amber-100
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Overdue',
                          value: '${invoiceProvider.overdueCount}',
                          icon: Icons.warning,
                          color: const Color(0xFFEF4444), // Tailwind red-500
                          backgroundColor: const Color(
                            0xFFFECACA,
                          ), // Tailwind red-100
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Tailwind slate-800
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Add Invoice',
                      icon: Icons.add_circle_outline,
                      onTap: () {
                        context.push('/add-invoice');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'View All',
                      icon: Icons.receipt_long_outlined,
                      onTap: () {
                        context.push('/invoices');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'Reports',
                      icon: Icons.analytics_outlined,
                      onTap: () {
                        context.push('/reporting');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Recent invoices
              const Text(
                'Recent Invoices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Tailwind slate-800
                ),
              ),
              const SizedBox(height: 16),

              Consumer<InvoiceProvider>(
                builder: (context, invoiceProvider, child) {
                  if (invoiceProvider.isLoading) {
                    return Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6), // Tailwind blue-500
                        ),
                      ),
                    );
                  }

                  final recentInvoices = invoiceProvider.invoices
                      .take(5)
                      .toList();

                  if (recentInvoices.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF1F5F9,
                              ), // Tailwind slate-100
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Color(0xFF94A3B8), // Tailwind slate-400
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No invoices yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569), // Tailwind slate-600
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start by adding your first invoice',
                            style: TextStyle(
                              color: Color(0xFF94A3B8), // Tailwind slate-400
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: recentInvoices
                        .map(
                          (invoice) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF64748B,
                                  ).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEFF6FF,
                                  ), // Tailwind blue-50
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    invoice.vendorName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(
                                        0xFF3B82F6,
                                      ), // Tailwind blue-500
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                invoice.vendorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(
                                    0xFF1E293B,
                                  ), // Tailwind slate-800
                                ),
                              ),
                              subtitle: Text(
                                'Invoice #${invoice.invoiceNumber}',
                                style: const TextStyle(
                                  color: Color(
                                    0xFF64748B,
                                  ), // Tailwind slate-500
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${invoice.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(
                                        0xFF1E293B,
                                      ), // Tailwind slate-800
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(invoice.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      invoice.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                context.push('/invoice-detail/${invoice.id}');
                              },
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor ?? color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B), // Tailwind slate-800
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B), // Tailwind slate-500
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Tailwind blue-50
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: const Color(0xFF3B82F6), // Tailwind blue-500
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Tailwind slate-800
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
