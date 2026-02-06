import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/usb_repository.dart';
import '../../domain/usecases/copy_file_usecase.dart';
import '../../domain/usecases/get_files_usecase.dart';
import '../../domain/usecases/pick_directory_usecase.dart';
import '../../data/datasources/saf_datasource.dart';
import '../../data/repositories/usb_repository_impl.dart';

// --- Dependency Injection ---
final safDatasourceProvider = Provider<SafDatasource>((ref) => SafDatasourceImpl());
final usbRepositoryProvider = Provider<UsbRepository>((ref) => UsbRepositoryImpl(ref.read(safDatasourceProvider)));

final getFilesUseCaseProvider = Provider((ref) => GetFilesUseCase(ref.read(usbRepositoryProvider)));
final pickDirectoryUseCaseProvider = Provider((ref) => PickDirectoryUseCase(ref.read(usbRepositoryProvider)));
final copyFileUseCaseProvider = Provider((ref) => CopyFileUseCase(ref.read(usbRepositoryProvider)));

// --- State ---
enum UsbStatus { initial, loading, success, failure }

class UsbState extends Equatable {
  final UsbStatus status;
  final String? errorMessage;
  final String? rootUri;
  final String? currentUri;
  final List<String> uriStack;
  final List<FileEntity> files;
  final Set<FileEntity> selectedFiles;
  final bool isSelectionMode;
  final bool isFilteredMode;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCopying;
  final int copyTotalFiles;
  final int copyDoneCount;
  final String? copyCurrentFilename;

  const UsbState({
    this.status = UsbStatus.initial,
    this.errorMessage,
    this.rootUri,
    this.currentUri,
    this.uriStack = const [],
    this.files = const [],
    this.selectedFiles = const {},
    this.isSelectionMode = false,
    this.isFilteredMode = false,
    this.startDate,
    this.endDate,
    this.isCopying = false,
    this.copyTotalFiles = 0,
    this.copyDoneCount = 0,
    this.copyCurrentFilename,
  });

  UsbState copyWith({
    UsbStatus? status,
    String? errorMessage,
    String? rootUri,
    String? currentUri,
    List<String>? uriStack,
    List<FileEntity>? files,
    Set<FileEntity>? selectedFiles,
    bool? isSelectionMode,
    bool? isFilteredMode,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCopying,
    int? copyTotalFiles,
    int? copyDoneCount,
    String? copyCurrentFilename,
  }) {
    return UsbState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      rootUri: rootUri ?? this.rootUri,
      currentUri: currentUri ?? this.currentUri,
      uriStack: uriStack ?? this.uriStack,
      files: files ?? this.files,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      isFilteredMode: isFilteredMode ?? this.isFilteredMode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCopying: isCopying ?? this.isCopying,
      copyTotalFiles: copyTotalFiles ?? this.copyTotalFiles,
      copyDoneCount: copyDoneCount ?? this.copyDoneCount,
      copyCurrentFilename: copyCurrentFilename ?? this.copyCurrentFilename,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        rootUri,
        currentUri,
        uriStack,
        files,
        selectedFiles,
        isSelectionMode,
        isFilteredMode,
        startDate,
        endDate,
        isCopying,
        copyTotalFiles,
        copyDoneCount,
        copyCurrentFilename,
      ];
}

// --- Controller ---
class UsbController extends StateNotifier<UsbState> {
  final GetFilesUseCase getFilesUseCase;
  final PickDirectoryUseCase pickDirectoryUseCase;
  final CopyFileUseCase copyFileUseCase;

  UsbController({
    required this.getFilesUseCase,
    required this.pickDirectoryUseCase,
    required this.copyFileUseCase,
  }) : super(const UsbState());

  Future<void> pickDirectory() async {
    final result = await pickDirectoryUseCase(NoParams());
    result.fold(
      (failure) => state = state.copyWith(status: UsbStatus.failure, errorMessage: failure.message),
      (uri) {
        if (uri != null) {
          state = UsbState(
            rootUri: uri,
            currentUri: uri,
            uriStack: [uri],
            status: UsbStatus.loading,
          );
          loadFiles(uri);
        }
      },
    );
  }

  Future<void> loadFiles(String uri) async {
    state = state.copyWith(status: UsbStatus.loading, currentUri: uri);
    final result = await getFilesUseCase(GetFilesParams(uri: uri));
    result.fold(
      (failure) => state = state.copyWith(status: UsbStatus.failure, errorMessage: failure.message),
      (files) => state = state.copyWith(status: UsbStatus.success, files: files),
    );
  }

  Future<void> navigateToFolder(FileEntity folder) async {
    final stack = List<String>.from(state.uriStack)..add(folder.uri);
    state = state.copyWith(
      isFilteredMode: false,
      uriStack: stack,
      currentUri: folder.uri,
      status: UsbStatus.loading,
    );
    loadFiles(folder.uri);
  }

  Future<void> navigateBack() async {
    if (state.isFilteredMode) {
      // Exit filter mode
      state = state.copyWith(
        isFilteredMode: false,
        currentUri: state.rootUri,
        uriStack: state.rootUri != null ? [state.rootUri!] : [],
        status: UsbStatus.loading
      );
      if (state.rootUri != null) loadFiles(state.rootUri!);
      return;
    }

    if (state.uriStack.length > 1) {
      final newStack = List<String>.from(state.uriStack)..removeLast();
      final prevUri = newStack.last;
      state = state.copyWith(uriStack: newStack, currentUri: prevUri, status: UsbStatus.loading);
      loadFiles(prevUri);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  Future<void> applyFilter() async {
    if (state.rootUri == null || state.startDate == null || state.endDate == null) return;

    state = state.copyWith(status: UsbStatus.loading, isFilteredMode: true);
    
    final startMs = state.startDate!.millisecondsSinceEpoch;
    final endMs = state.endDate!.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)).millisecondsSinceEpoch;

    final result = await getFilesUseCase(GetFilesParams(
      uri: state.rootUri!,
      recursive: true,
      startDate: startMs,
      endDate: endMs,
    ));

    result.fold(
      (failure) => state = state.copyWith(status: UsbStatus.failure, errorMessage: failure.message),
      (files) => state = state.copyWith(status: UsbStatus.success, files: files),
    );
  }

  void toggleSelection(FileEntity file) {
    final newSelection = Set<FileEntity>.from(state.selectedFiles);
    if (newSelection.contains(file)) {
      newSelection.remove(file);
    } else {
      newSelection.add(file);
    }
    state = state.copyWith(selectedFiles: newSelection, isSelectionMode: newSelection.isNotEmpty);
  }

  void selectAll() {
    final newSelection = state.files.where((f) => !f.isDirectory).toSet();
    state = state.copyWith(selectedFiles: newSelection, isSelectionMode: newSelection.isNotEmpty);
  }

  void clearSelection() {
    state = state.copyWith(selectedFiles: {}, isSelectionMode: false);
  }

  Future<void> copySelectedFiles() async {
    if (state.selectedFiles.isEmpty) return;

    final destUriEither = await pickDirectoryUseCase(NoParams());
    
    destUriEither.fold(
      (failure) => null, // Handle error or cancel
      (destUri) async {
        if (destUri == null) return;
        
        final total = state.selectedFiles.length;
        state = state.copyWith(
          isCopying: true,
          copyTotalFiles: total,
          copyDoneCount: 0,
        );
        
        int successCount = 0;
        final filesToCopy = state.selectedFiles.toList();

        // Copy logic is inherently async but currently sequential to update UI.
        // For distinct parallel behavior without blocking UI thread, Future is enough if IO is async.
        // SafDatasource use Platform Channel which is async.
        
        for (final file in filesToCopy) {
          state = state.copyWith(copyCurrentFilename: file.name);
          
          final result = await copyFileUseCase(CopyFileParams(sourceUri: file.uri, destFolderUri: destUri));
          
          if (result.fold((l) => false, (r) => r)) {
            successCount++;
          }

          state = state.copyWith(copyDoneCount: state.copyDoneCount + 1);
        }

        // Completion
        state = state.copyWith(
          isCopying: false,
          copyTotalFiles: 0,
          copyDoneCount: 0,
          copyCurrentFilename: null,
          isSelectionMode: false,
          selectedFiles: {},
          errorMessage: "Download completed successfully: $successCount / $total files.",
        );
      }
    );
  }
}

final usbControllerProvider = StateNotifierProvider<UsbController, UsbState>((ref) {
  return UsbController(
    getFilesUseCase: ref.watch(getFilesUseCaseProvider),
    pickDirectoryUseCase: ref.watch(pickDirectoryUseCaseProvider),
    copyFileUseCase: ref.watch(copyFileUseCaseProvider),
  );
});
