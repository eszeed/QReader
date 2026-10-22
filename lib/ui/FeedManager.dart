import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rss_reader/data/feed_source.dart';
import 'package:rss_reader/utils/opml_parser.dart';

class FeedManager extends StatefulWidget {
  const FeedManager({super.key});

  @override
  State<FeedManager> createState() => _FeedManager();
}

class _FeedManager extends State<FeedManager> {
  List<FeedSource> _sources = [];
  bool _loading = true;

  // 批量选择模式
  bool _selectMode = false;
  final Set<String> _selectedUrls = {};

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    final sources = await loadFeedSources();
    setState(() {
      _sources = sources;
      _loading = false;
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedUrls.clear();
    });
  }

  void _toggleSelect(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
      } else {
        _selectedUrls.add(url);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedUrls.addAll(_sources.map((s) => s.url));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedUrls.clear();
    });
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedUrls.isEmpty) return;
    final count = _selectedUrls.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 $count 个订阅源吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _sources.removeWhere((s) => _selectedUrls.contains(s.url));
      _selectedUrls.clear();
      _selectMode = false;
    });
    await saveFeedSources(_sources);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $count 个订阅源')),
      );
    }
  }

  // ── 单个订阅源的增删改 ──

  void _showAddDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加订阅源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '例如：少数派',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'RSS 地址',
                hintText: 'https://example.com/feed',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();

              if (name.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和地址不能为空')),
                );
                return;
              }

              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的 URL（以 http(s):// 开头）')),
                );
                return;
              }

              final newSource = FeedSource(name: name, url: url);
              _sources.add(newSource);
              await saveFeedSources(_sources);

              setState(() {});
              Navigator.of(ctx).pop();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final source = _sources[index];
    final nameController = TextEditingController(text: source.name);
    final urlController = TextEditingController(text: source.url);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑订阅源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'RSS 地址',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();

              if (name.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和地址不能为空')),
                );
                return;
              }

              setState(() {
                _sources[index] = FeedSource(name: name, url: url);
              });
              await saveFeedSources(_sources);
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) {
    final source = _sources[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除订阅源「${source.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() {
                _sources.removeAt(index);
              });
              await saveFeedSources(_sources);
              Navigator.of(ctx).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ── OPML 导入 ──

  Future<void> _importOpml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['opml', 'xml'],
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final progress = ValueNotifier<_ImportProgress>(_ImportProgress());
    bool cancelled = false;

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<_ImportProgress>(
        valueListenable: progress,
        builder: (_, p, __) => AlertDialog(
          title: Text(p.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: p.value),
              const SizedBox(height: 12),
              Text(p.message, style: const TextStyle(fontSize: 13)),
              if (p.detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.detail,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );

    try {
      progress.value = _ImportProgress(
        value: 0.0,
        title: '正在读取文件',
        message: '读取 OPML 文件内容...',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      String content;
      try {
        content = await File(filePath).readAsString();
      } catch (e) {
        progress.value = _ImportProgress(
          value: 1.0, title: '读取失败', message: '读取文件失败：$e',
        );
        return;
      }
      if (cancelled) return;

      progress.value = _ImportProgress(
        value: 0.2,
        title: '正在解析',
        message: '解析 OPML 文件中的订阅源...',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      List<FeedSource> imported;
      try {
        imported = parseOpml(content);
      } catch (e) {
        progress.value = _ImportProgress(
          value: 1.0, title: '解析失败', message: '解析 OPML 失败：$e',
        );
        return;
      }
      if (cancelled) return;

      if (imported.isEmpty) {
        progress.value = _ImportProgress(
          value: 1.0, title: '导入完成', message: '未在 OPML 文件中找到订阅源',
        );
        return;
      }

      final existingUrls = _sources.map((s) => s.url).toSet();
      final newFeeds =
          imported.where((f) => !existingUrls.contains(f.url)).toList();
      final skippedCount = imported.length - newFeeds.length;

      if (newFeeds.isEmpty) {
        progress.value = _ImportProgress(
          value: 1.0,
          title: '导入完成',
          message: '共解析到 ${imported.length} 个订阅源，全部已存在，无需导入',
        );
        return;
      }

      final mergedSources = List<FeedSource>.from(_sources);
      for (int i = 0; i < newFeeds.length; i++) {
        if (cancelled) return;
        final feed = newFeeds[i];
        final p = 0.4 + 0.6 * (i + 1) / newFeeds.length;
        progress.value = _ImportProgress(
          value: p,
          title: '正在导入',
          message: '导入中 (${i + 1}/${newFeeds.length})',
          detail: feed.name,
        );
        mergedSources.add(feed);
        if ((i + 1) % 10 == 0 || i == newFeeds.length - 1) {
          await saveFeedSources(mergedSources);
        }
      }

      if (!cancelled && mounted) {
        setState(() {
          _sources = mergedSources;
        });
        progress.value = _ImportProgress(
          value: 1.0,
          title: '导入完成',
          message: '成功导入 ${newFeeds.length} 个订阅源'
              '${skippedCount > 0 ? '，跳过 $skippedCount 个已存在的订阅源' : ''}',
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${newFeeds.length} 个订阅源')),
          );
        }
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      progress.dispose();
    }
  }

  // ── 构建 UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectMode,
              ),
              title: Text('已选择 ${_selectedUrls.length} 项'),
              actions: [
                TextButton(
                  onPressed: _selectedUrls.length == _sources.length
                      ? _deselectAll
                      : _selectAll,
                  child: Text(
                    _selectedUrls.length == _sources.length ? '取消全选' : '全选',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            )
          : AppBar(
              title: const Text('订阅源管理'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: '导入 OPML',
                  onPressed: _importOpml,
                ),
                IconButton(
                  icon: const Icon(Icons.checklist_outlined),
                  tooltip: '批量管理',
                  onPressed: _toggleSelectMode,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '添加订阅源',
                  onPressed: _showAddDialog,
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rss_feed, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无订阅源',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('点击右上角 + 添加你的第一个 RSS 订阅源'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _selectMode
                          ? ListView.builder(
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _sources.length,
                              itemBuilder: (context, index) {
                                final source = _sources[index];
                                final isSelected =
                                    _selectedUrls.contains(source.url);
                                return _SourceTile(
                                  key: ValueKey(source.url),
                                  source: source,
                                  selectMode: true,
                                  isSelected: isSelected,
                                  onToggleSelect: () =>
                                      _toggleSelect(source.url),
                                  onEdit: () {},
                                  onDelete: () {},
                                );
                              },
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _sources.length,
                              onReorderItem: (oldIndex, newIndex) async {
                                setState(() {
                                  if (oldIndex < newIndex) newIndex -= 1;
                                  final item = _sources.removeAt(oldIndex);
                                  _sources.insert(newIndex, item);
                                });
                                await saveFeedSources(_sources);
                              },
                              itemBuilder: (context, index) {
                                final source = _sources[index];
                                final isSelected =
                                    _selectedUrls.contains(source.url);
                                return _SourceTile(
                                  key: ValueKey(source.url),
                                  source: source,
                                  selectMode: false,
                                  isSelected: isSelected,
                                  onToggleSelect: () =>
                                      _toggleSelect(source.url),
                                  onEdit: () => _showEditDialog(index),
                                  onDelete: () => _confirmDelete(index),
                                );
                              },
                            ),
                    ),
                    if (_selectMode)
                      _BatchDeleteBar(
                        selectedCount: _selectedUrls.length,
                        onDelete: _confirmBatchDelete,
                      ),
                  ],
                ),
    );
  }
}

// ── 订阅源列表项 ──

class _SourceTile extends StatelessWidget {
  final FeedSource source;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SourceTile({
    super.key,
    required this.source,
    required this.selectMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: selectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
              )
            : const CircleAvatar(child: Icon(Icons.rss_feed)),
        title: Text(source.name),
        subtitle: Text(
          source.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: selectMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: '编辑',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: '删除',
                    onPressed: onDelete,
                  ),
                ],
              ),
        onTap: selectMode ? onToggleSelect : null,
      ),
    );
  }
}

// ── 批量删除底栏 ──

class _BatchDeleteBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;

  const _BatchDeleteBar({
    required this.selectedCount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount > 0
                  ? '已选择 $selectedCount 个订阅源'
                  : '请选择要删除的订阅源',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: selectedCount > 0 ? onDelete : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

// ── OPML 导入进度 ──

class _ImportProgress {
  final double value;
  final String title;
  final String message;
  final String detail;

  const _ImportProgress({
    this.value = 0.0,
    this.title = '导入中',
    this.message = '',
    this.detail = '',
  });
}
