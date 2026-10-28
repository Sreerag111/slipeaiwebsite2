import 'package:get/get.dart';

import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/domain/usecases/delete_chat_thread_use_case.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/clear_history_use_case.dart';
import '../../domain/usecases/delete_history_item_use_case.dart';
import '../../domain/usecases/load_history_use_case.dart';
import '../controllers/history_controller.dart';
import '../../../chat/data/datasources/chat_storage_data_source.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HistoryRepository>()) {
      Get.lazyPut<HistoryRepository>(
        () => HistoryRepositoryImpl(Get.find<ChatStorageDataSource>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LoadHistoryUseCase>()) {
      Get.lazyPut(
        () => LoadHistoryUseCase(Get.find<HistoryRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => DeleteHistoryItemUseCase(Get.find<HistoryRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => ClearHistoryUseCase(Get.find<HistoryRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => DeleteChatThreadUseCase(Get.find<ChatRepository>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<HistoryController>()) {
      Get.lazyPut<HistoryController>(
        () => HistoryController(
          loadHistoryUseCase: Get.find<LoadHistoryUseCase>(),
          deleteHistoryItemUseCase: Get.find<DeleteHistoryItemUseCase>(),
          clearHistoryUseCase: Get.find<ClearHistoryUseCase>(),
          deleteChatThreadUseCase: Get.find<DeleteChatThreadUseCase>(),
        ),
        fenix: true,
      );
    }
  }
}
