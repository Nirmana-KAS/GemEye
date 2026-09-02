import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import '../services/certificate_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GradeResult> _allHistory = [];
  List<GradeResult> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedGradeFilter = 0; // 0 = All

  // Filter sheet state
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _confidenceFilter = 'All';
  String _certificateFilter = 'All';
  String _sortOption = 'Newest first';

  // Batch selection
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  static const Map<int, Color> gradeColors = {
    1: Color(0xFF091A47),
    2: Color(0xFF102670),
    3: Color(0xFF1B3A8C),
    4: Color(0xFF2E5BB8),
    5: Color(0xFF4A80D4),
    6: Color(0xFF7BA7E8),
    7: Color(0xFFA8C8F0),
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.getGradeHistory();
    setState(() {
      _allHistory = history;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<GradeResult> results = List.from(_allHistory);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      results = results.where((r) => r.stoneId.toLowerCase().contains(query)).toList();
    }

    if (_selectedGradeFilter > 0) {
      results = results.where((r) => r.gradeNumber == _selectedGradeFilter).toList();
    }

    if (_dateFrom != null) {
      results = results.where((r) => !r.capturedAt.isBefore(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      final endOfDay = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59);
      results = results.where((r) => !r.capturedAt.isAfter(endOfDay)).toList();
    }

    if (_confidenceFilter == 'High (80%+)') {
      results = results.where((r) => r.confidence >= 80).toList();
    } else if (_confidenceFilter == 'Medium (50%+)') {
      results = results.where((r) => r.confidence >= 50).toList();
    } else if (_confidenceFilter == 'Low (<50%)') {
      results = results.where((r) => r.confidence < 50).toList();
    }

    if (_certificateFilter == 'Exported') {
      results = results.where((r) => r.certificateNumber != null).toList();
    } else if (_certificateFilter == 'Not exported') {
      results = results.where((r) => r.certificateNumber == null).toList();
    }

    switch (_sortOption) {
      case 'Oldest first':
        results.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      case 'Grade 1→7':
        results.sort((a, b) => a.gradeNumber.compareTo(b.gradeNumber));
      case 'Grade 7→1':
        results.sort((a, b) => b.gradeNumber.compareTo(a.gradeNumber));
      case 'Confidence ↓':
        results.sort((a, b) => b.confidence.compareTo(a.confidence));
      case 'Confidence ↑':
        results.sort((a, b) => a.confidence.compareTo(b.confidence));
      default:
        results.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }

    setState(() => _filteredHistory = results);
  }

  int get _activeFilterCount {
    int count = 0;
    if (_dateFrom != null || _dateTo != null) count++;
    if (_confidenceFilter != 'All') count++;
    if (_certificateFilter != 'All') count++;
    if (_sortOption != 'Newest first') count++;
    return count;
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete stones?'),
        content: Text('Delete $count selected stone${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: GemEyeColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final id in _selectedIds) {
      await StorageService.deleteGradeResult(id);
    }
    _exitSelectionMode();
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count stone${count > 1 ? 's' : ''} deleted')),
      );
    }
  }

  Future<void> _exportSelected() async {
    final selectedResults = _filteredHistory.where((r) => _selectedIds.contains(r.id)).toList();
    int generated = 0;

    for (final result in selectedResults) {
      try {
        if (result.certificateNumber == null) {
          result.certificateNumber = await CertificateService.generateCertificateNumber();
          await StorageService.saveGradeResult(result);
        }

        Uint8List stoneImageBytes;
        try {
          stoneImageBytes = await File(result.capturedImagePath).readAsBytes();
        } catch (_) {
          stoneImageBytes = Uint8List(0);
        }

        final pdfBytes = await CertificateService.generateCertificatePdf(
          result: result,
          stoneImage: stoneImageBytes,
        );

        final dir = await getApplicationDocumentsDirectory();
        final certDir = Directory('${dir.path}/GemEye Certificates');
        if (!await certDir.exists()) {
          await certDir.create(recursive: true);
        }
        final file = File('${certDir.path}/${result.certificateNumber}.pdf');
        await file.writeAsBytes(pdfBytes);
        generated++;
      } catch (e) {
        debugPrint('Export failed for ${result.stoneId}: $e');
      }
    }

    _exitSelectionMode();
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$generated certificate${generated > 1 ? 's' : ''} saved')),
      );
    }
  }

  Future<void> _shareSelected() async {
    final selectedResults = _filteredHistory.where((r) => _selectedIds.contains(r.id)).toList();
    final files = <XFile>[];
    for (final result in selectedResults) {
      final file = File(result.capturedImagePath);
      if (await file.exists()) {
        files.add(XFile(file.path));
      }
    }
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images available to share')),
        );
      }
      return;
    }
    await Share.shareXFiles(files, text: 'GemEye graded stones');
  }

  Future<void> _deleteItem(GradeResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${result.stoneId}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: GemEyeColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.deleteGradeResult(result.id);
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.stoneId} deleted')),
      );
    }
  }

  void _showFilterSheet() {
    String tempConfidence = _confidenceFilter;
    String tempCertificate = _certificateFilter;
    String tempSort = _sortOption;
    DateTime? tempDateFrom = _dateFrom;
    DateTime? tempDateTo = _dateTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date range
                  const Text('Date Range', style: TextStyle(
                    fontFamily: GemEyeFonts.heading, fontSize: 14,
                    fontWeight: FontWeight.w600, color: GemEyeColors.textPrimary,
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: tempDateFrom ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setSheetState(() => tempDateFrom = picked);
                          },
                          child: Text(
                            tempDateFrom != null
                                ? '${tempDateFrom!.day}/${tempDateFrom!.month}/${tempDateFrom!.year}'
                                : 'From: Any',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: tempDateTo ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setSheetState(() => tempDateTo = picked);
                          },
                          child: Text(
                            tempDateTo != null
                                ? '${tempDateTo!.day}/${tempDateTo!.month}/${tempDateTo!.year}'
                                : 'To: Any',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confidence
                  const Text('Confidence', style: TextStyle(
                    fontFamily: GemEyeFonts.heading, fontSize: 14,
                    fontWeight: FontWeight.w600, color: GemEyeColors.textPrimary,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'High (80%+)', 'Medium (50%+)', 'Low (<50%)'].map((label) {
                      return ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: tempConfidence == label,
                        selectedColor: GemEyeColors.primarySurface,
                        onSelected: (_) => setSheetState(() => tempConfidence = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Certificate status
                  const Text('Certificate Status', style: TextStyle(
                    fontFamily: GemEyeFonts.heading, fontSize: 14,
                    fontWeight: FontWeight.w600, color: GemEyeColors.textPrimary,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Exported', 'Not exported'].map((label) {
                      return ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: tempCertificate == label,
                        selectedColor: GemEyeColors.primarySurface,
                        onSelected: (_) => setSheetState(() => tempCertificate = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sort
                  const Text('Sort', style: TextStyle(
                    fontFamily: GemEyeFonts.heading, fontSize: 14,
                    fontWeight: FontWeight.w600, color: GemEyeColors.textPrimary,
                  )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Newest first', 'Oldest first', 'Grade 1→7',
                      'Grade 7→1', 'Confidence ↓', 'Confidence ↑',
                    ].map((label) {
                      return ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: tempSort == label,
                        selectedColor: GemEyeColors.primarySurface,
                        onSelected: (_) => setSheetState(() => tempSort = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempDateFrom = null;
                            tempDateTo = null;
                            tempConfidence = 'All';
                            tempCertificate = 'All';
                            tempSort = 'Newest first';
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _dateFrom = tempDateFrom;
                            _dateTo = tempDateTo;
                            _confidenceFilter = tempConfidence;
                            _certificateFilter = tempCertificate;
                            _sortOption = tempSort;
                            _applyFilters();
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by stone ID...',
                  prefixIcon: Icon(Icons.search_rounded, color: GemEyeColors.textMuted),
                ),
              ),
            ),

            // Grade filter chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildGradeChip(0, 'All', null),
                  for (int i = 1; i <= 7; i++)
                    _buildGradeChip(i, 'G$i', gradeColors[i]!),
                ],
              ),
            ),

            // Count header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredHistory.length} stone${_filteredHistory.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textMuted,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: _filteredHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final result = _filteredHistory[index];
                        return _buildHistoryItem(result);
                      },
                    ),
            ),

            // Batch action bar
            if (_isSelectionMode && _selectedIds.isNotEmpty)
              _buildBatchActionBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text('Grading History'),
      automaticallyImplyLeading: false,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterSheet,
            ),
            if (_activeFilterCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: GemEyeColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_activeFilterCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedIds.length} selected'),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            _selectedIds.length == _filteredHistory.length
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
          ),
          onPressed: () {
            setState(() {
              if (_selectedIds.length == _filteredHistory.length) {
                _selectedIds.clear();
              } else {
                _selectedIds.addAll(_filteredHistory.map((r) => r.id));
              }
            });
          },
        ),
        TextButton(
          onPressed: _exitSelectionMode,
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildGradeChip(int grade, String label, Color? color) {
    final isSelected = _selectedGradeFilter == grade;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        selectedColor: GemEyeColors.primary,
        backgroundColor: GemEyeColors.primarySurface,
        checkmarkColor: Colors.white,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white38 : GemEyeColors.border,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : GemEyeColors.textPrimary,
              ),
            ),
          ],
        ),
        onSelected: (_) {
          setState(() => _selectedGradeFilter = grade);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildHistoryItem(GradeResult result) {
    final gradeColor = gradeColors[result.gradeNumber] ?? GemEyeColors.primary;
    final timeAgo = _formatTimeAgo(result.capturedAt);

    return Dismissible(
      key: Key(result.id),
      direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteItem(result);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: GemEyeColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(result.id);
            });
          }
        },
        onTap: () async {
          if (_isSelectionMode) {
            setState(() {
              if (_selectedIds.contains(result.id)) {
                _selectedIds.remove(result.id);
                if (_selectedIds.isEmpty) _isSelectionMode = false;
              } else {
                _selectedIds.add(result.id);
              }
            });
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(
                  imagePath: result.capturedImagePath,
                  gradeResult: result,
                ),
              ),
            );
            _loadHistory();
          }
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Checkbox(
                    value: _selectedIds.contains(result.id),
                    activeColor: GemEyeColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(result.id);
                        } else {
                          _selectedIds.remove(result.id);
                          if (_selectedIds.isEmpty) _isSelectionMode = false;
                        }
                      });
                    },
                  ),

                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: gradeColor,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade ${result.gradeNumber} - ${result.tradeName}',
                        style: const TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GemEyeColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.stoneId} · ${result.confidence.toStringAsFixed(0)}% · $timeAgo',
                        style: const TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 11,
                          color: GemEyeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                if (result.certificateNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: GemEyeColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Exported',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: GemEyeColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Export All', style: TextStyle(fontSize: 12)),
                onPressed: _exportSelected,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share', style: TextStyle(fontSize: 12)),
                onPressed: _shareSelected,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_rounded, size: 18, color: GemEyeColors.error),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: GemEyeColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GemEyeColors.error),
                ),
                onPressed: _deleteSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: GemEyeColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No stones graded yet',
            style: TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grade your first stone',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 13,
              color: GemEyeColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
