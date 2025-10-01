import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/simple_ai_processor.dart';

class SimpleUploadState {
  final bool isLoading;
  final bool isProcessing;
  final File? selectedImage;
  final String? processedImageUrl;
  final String? errorMessage;
  final double progress;

  SimpleUploadState({
    this.isLoading = false,
    this.isProcessing = false,
    this.selectedImage,
    this.processedImageUrl,
    this.errorMessage,
    this.progress = 0.0,
  });

  SimpleUploadState copyWith({
    bool? isLoading,
    bool? isProcessing,
    File? selectedImage,
    String? processedImageUrl,
    String? errorMessage,
    double? progress,
  }) {
    return SimpleUploadState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      selectedImage: selectedImage ?? this.selectedImage,
      processedImageUrl: processedImageUrl ?? this.processedImageUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

class SimpleUploadCubit extends Cubit<SimpleUploadState> {
  SimpleUploadCubit() : super(SimpleUploadState());

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        emit(state.copyWith(
          selectedImage: File(image.path),
          errorMessage: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to pick image: ${e.toString()}',
      ));
    }
  }

  Future<void> processImage() async {
    if (state.selectedImage == null) return;

    emit(state.copyWith(
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
    ));

    try {
      // Update progress
      emit(state.copyWith(progress: 0.1));

      // Process with Gemini AI directly using local assets
      print('Processing image with Gemini AI using local assets...');
      emit(state.copyWith(progress: 0.2));

      final processedImageFile = await SimpleAIProcessor.processImageWithAI(
        state.selectedImage!,
      );

      emit(state.copyWith(progress: 0.8));

      emit(state.copyWith(
        isProcessing: false,
        processedImageUrl: processedImageFile.path,
        progress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isProcessing: false,
        errorMessage: 'Processing failed: ${e.toString()}',
        progress: 0.0,
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  void reset() {
    emit(SimpleUploadState());
  }
}
