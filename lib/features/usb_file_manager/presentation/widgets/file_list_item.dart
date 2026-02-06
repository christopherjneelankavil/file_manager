import 'package:flutter/material.dart';
import '../../domain/entities/file_entity.dart';
import '../../../../shared/helpers/file_helper.dart';

class FileListItem extends StatelessWidget {
  final FileEntity file;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onCheckboxChanged;

  const FileListItem({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        file.isDirectory ? Icons.folder : Icons.insert_drive_file,
        color: file.isDirectory ? Colors.amber : Colors.blueGrey,
      ),
      title: Text(file.name),
      subtitle: Text(
        '${FileHelper.formatDate(file.lastModified)} • ${FileHelper.formatSize(file.size)}',
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withAlpha(25),
      trailing: isSelectionMode && !file.isDirectory
          ? Checkbox(
              value: isSelected,
              onChanged: onCheckboxChanged,
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
