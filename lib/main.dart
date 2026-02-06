import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'file_model.dart';
import 'usb_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB File Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const UsbExplorerScreen(),
    );
  }
}

class UsbExplorerScreen extends StatefulWidget {
  const UsbExplorerScreen({super.key});

  @override
  State<UsbExplorerScreen> createState() => _UsbExplorerScreenState();
}

class _UsbExplorerScreenState extends State<UsbExplorerScreen> {
  final UsbService _usbService = UsbService();
  
  String? _rootUri;
  // Stack to keep track of navigation history for "Browse Mode"
  final List<String> _uriStack = [];
  String? _currentUri;

  List<FileModel> _files = [];
  bool _isLoading = false;
  bool _isFilteredMode = false;
  
  // Selection Mode State
  final Set<FileModel> _selectedFiles = {};
  bool get _isSelectionMode => _selectedFiles.isNotEmpty;

  DateTime? _startDate;
  DateTime? _endDate;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDirectory() async {
    final uri = await _usbService.pickDirectory();
    if (uri != null) {
      setState(() {
        _rootUri = uri;
        _uriStack.clear();
        _uriStack.add(uri);
        _currentUri = uri;
        _isFilteredMode = false;
        _startDate = null;
        _endDate = null;
      });
      _loadFiles(uri);
    }
  }

  Future<void> _loadFiles(String uri) async {
    setState(() {
      _isLoading = true;
      _currentUri = uri;
    });

    final files = await _usbService.getFiles(uri);

    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _applyFilter() async {
    if (_rootUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a USB root folder first.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Start and End dates.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isFilteredMode = true;
    });

    // When filtering, we search recursively from the ROOT URI.
    // Timestamps in milliseconds
    final startMs = _startDate!.millisecondsSinceEpoch;
    // End date should include the whole end day, so we might want to set time to 23:59:59 or similar if user just picked a date.
    // Assuming DatePicker just gives date at 00:00. Let's make end date inclusive of that day.
    final endMs = _endDate!.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)).millisecondsSinceEpoch;

    final files = await _usbService.getFiles(
      _rootUri!,
      recursive: true,
      startDate: startMs,
      endDate: endMs,
    );

    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  void _toggleSelection(FileModel file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  void _selectAll() {
    setState(() {
      // Only select files, not directories, if that's the desired behavior.
      // But typically "Select All" selects everything visible.
      // For copy, we might only want files or folders too?
      // Native copy implementation currently handles file-to-file copy using streams.
      // Copying a folder would require recursion which native side doesn't do yet.
      // So let's only select files for now to avoid issues.
      _selectedFiles.addAll(_files.where((f) => !f.isDirectory));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  void _onFolderTap(FileModel folder) {
    if (_isSelectionMode) {
      // In selection mode, tapping a folder could select it?
      // Or just ignore/toggle if we supported folder selection.
      // For now, let's say we don't support folder selection for copy.
      return; 
    }
    
    if (_isFilteredMode) {
      // If in filtered mode, navigation behavior is ambiguous. 
      // Usually "Search Results" are just a flat list. 
      // But if user wants to peek inside, we could switch back to browse mode for that folder?
      // Let's just switch to browse mode for that folder.
      setState(() {
        _isFilteredMode = false;
        _uriStack.add(folder.uri);
      });
      _loadFiles(folder.uri);
    } else {
      // Normal browse navigation
      _uriStack.add(folder.uri);
      _loadFiles(folder.uri);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isFilteredMode) {
      // Exit filter mode, go back to root browse
      setState(() {
        _isFilteredMode = false;
        _uriStack.clear();
        if (_rootUri != null) _uriStack.add(_rootUri!);
        _currentUri = _rootUri;
      });
      if (_rootUri != null) _loadFiles(_rootUri!);
      return false;
    }

    if (_uriStack.length > 1) {
      _uriStack.removeLast();
      final previousUri = _uriStack.last;
      _loadFiles(previousUri);
      return false;
    }
    return true;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: _isSelectionMode
              ? Text('${_selectedFiles.length} Selected')
              : const Text('USB File Explorer'),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          actions: [
            if (_isSelectionMode)
               IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: _selectAll,
                tooltip: 'Select All Files',
              ),
            if (!_isSelectionMode && _rootUri != null)
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _pickDirectory,
                tooltip: 'Change Root Folder',
              ),
          ],
        ),
        body: Column(
          children: [
            if (_rootUri == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickDirectory,
                    icon: const Icon(Icons.usb),
                    label: const Text('Select USB Drive Root'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              )
            else ...[
              // Filter Selection Area
              Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectDate(true),
                              child: Text(_startDate == null
                                  ? 'Start Date'
                                  : DateFormat('yyyy-MM-dd').format(_startDate!)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _selectDate(false),
                              child: Text(_endDate == null
                                  ? 'End Date'
                                  : DateFormat('yyyy-MM-dd').format(_endDate!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _applyFilter,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter Files by Date (Recursive Scan)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mode Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: Text(
                  _isFilteredMode 
                    ? 'Mode: Filter Results (Recursive)' 
                    : 'Mode: Browser (${_uriStack.length > 1 ? ".../" : ""}${Uri.decodeComponent(_currentUri?.split('/').last ?? "")})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // File List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _files.isEmpty
                        ? const Center(child: Text('No files found.'))
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              final isSelected = _selectedFiles.contains(file);
                              return ListTile(
                                leading: Icon(
                                  file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                                  color: file.isDirectory ? Colors.amber : Colors.blueGrey,
                                ),
                                title: Text(file.name),
                                subtitle: Text(
                                  '${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(file.lastModified))} • ${_formatSize(file.size)}',
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.1),
                                trailing: _isSelectionMode && !file.isDirectory
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (val) => _toggleSelection(file),
                                      )
                                    : null,
                                onTap: () {
                                  if (_isSelectionMode) {
                                    if (!file.isDirectory) _toggleSelection(file);
                                  } else if (file.isDirectory) {
                                    _onFolderTap(file);
                                  }
                                },
                                onLongPress: () {
                                  if (!file.isDirectory) {
                                    _toggleSelection(file);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton(
                onPressed: _copySelectedFiles,
                child: const Icon(Icons.download),
              )
            : null,
      ),
    );
  }

  Future<void> _copySelectedFiles() async {
    // 1. Pick Destination
    final destUri = await _usbService.pickDirectory();
    if (destUri == null) return; // User cancelled

    if (!mounted) return;

    // 2. Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               CircularProgressIndicator(),
               SizedBox(height: 16),
               Text("Copying files..."),
            ],
          ),
        );
      },
    );

    int successCount = 0;
    int failCount = 0;
    
    // 3. Copy Loop
    for (final file in _selectedFiles) {
      final success = await _usbService.copyFile(file.uri, destUri);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Close progress dialog

    // 4. Show Result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copy Complete: $successCount success, $failCount failed"),
      ),
    );
    
    _clearSelection();
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length / 3).floor();
    // adjust for small sizes logic if needed, but simple log based or loop is better
    // quick impl:
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    if (bytes < 1073741824) return "${(bytes / 1048576).toStringAsFixed(2)} MB";
    return "${(bytes / 1073741824).toStringAsFixed(2)} GB";
  }
}
