import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/usb_provider.dart';
import '../widgets/file_list_item.dart';

class UsbBrowserScreen extends ConsumerStatefulWidget {
  const UsbBrowserScreen({super.key});

  @override
  ConsumerState<UsbBrowserScreen> createState() => _UsbBrowserScreenState();
}

class _UsbBrowserScreenState extends ConsumerState<UsbBrowserScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usbControllerProvider);
    final controller = ref.read(usbControllerProvider.notifier);

    // Error Listener
    ref.listen(usbControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return PopScope(
      canPop: state.rootUri == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await controller.navigateBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: state.isSelectionMode
              ? Text('${state.selectedFiles.length} Selected')
              : const Text('USB File Explorer'),
          leading: state.isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.clearSelection,
                )
              : (state.uriStack.length > 1 || state.isFilteredMode) 
                 ? IconButton(
                     icon: const Icon(Icons.arrow_back),
                     onPressed: controller.navigateBack,
                   )
                 : null,
          actions: [
            if (state.isSelectionMode)
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: controller.selectAll,
                tooltip: 'Select All Files',
              ),
            if (!state.isSelectionMode && state.rootUri != null)
              IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: controller.pickDirectory,
                tooltip: 'Change Root Folder',
              ),
          ],
        ),
        body: Column(
          children: [
            if (state.rootUri == null)
              Expanded(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: controller.pickDirectory,
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
              // Filter Area
              _buildFilterArea(context, state, controller),

              // Mode/Breadcrumb
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 color: Colors.grey[200],
                 child: Text(
                   state.isFilteredMode 
                     ? 'Mode: Filter Results (Recursive)' 
                     : 'Mode: Browser (${state.uriStack.length > 1 ? ".../" : ""}${Uri.decodeComponent(state.currentUri?.split('/').last ?? "")})',
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),

              // File List
              Expanded(
                child: state.status == UsbStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.files.isEmpty
                        ? const Center(child: Text('No files found.'))
                        : ListView.builder(
                            itemCount: state.files.length,
                            itemBuilder: (context, index) {
                              final file = state.files[index];
                              final isSelected = state.selectedFiles.contains(file);
                              return FileListItem(
                                file: file,
                                isSelected: isSelected,
                                isSelectionMode: state.isSelectionMode,
                                onTap: () {
                                  if (state.isSelectionMode) {
                                    if (!file.isDirectory) controller.toggleSelection(file);
                                  } else if (file.isDirectory) {
                                    controller.navigateToFolder(file);
                                  }
                                },
                                onLongPress: () {
                                  if (!file.isDirectory) {
                                    controller.toggleSelection(file);
                                  }
                                },
                                onCheckboxChanged: (val) => controller.toggleSelection(file),
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
        floatingActionButton: state.isSelectionMode
            ? FloatingActionButton(
                onPressed: () => _copyFiles(controller),
                child: const Icon(Icons.download),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterArea(BuildContext context, UsbState state, UsbController controller) {
    return Card(
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
                    onPressed: () async {
                       final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) controller.setDateRange(picked, state.endDate);
                    },
                    child: Text(state.startDate == null
                        ? 'Start Date'
                        : DateFormat('yyyy-MM-dd').format(state.startDate!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) controller.setDateRange(state.startDate, picked);
                    },
                    child: Text(state.endDate == null
                        ? 'End Date'
                        : DateFormat('yyyy-MM-dd').format(state.endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (state.startDate != null && state.endDate != null) 
                  ? controller.applyFilter 
                  : null,
                icon: const Icon(Icons.filter_list),
                label: const Text('Filter Files by Date (Recursive Scan)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyFiles(UsbController controller) async {
    // Show Progress Dialog
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

    // Copy Action
    final successCount = await controller.copySelectedFiles();

    if (!mounted) return;
    Navigator.of(context).pop(); // Close dialog

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copy Complete: $successCount files copied.")),
    );
  }
}
