import 'package:get/get.dart';

import '../../../../core/config/app_config_data_source.dart';
import '../../../../core/config/config_repository.dart';
import '../../../../core/config/config_repository_impl.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../controllers/chat_controller.dart';
import '../../data/datasources/chat_storage_data_source.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/document_data_source.dart';
import '../../data/datasources/firestore_chat_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/analyze_plagiarism_use_case.dart';
import '../../domain/usecases/cancel_active_request_use_case.dart';
import '../../domain/usecases/check_grammar_use_case.dart';
import '../../domain/usecases/classify_message_use_case.dart';
import '../../domain/usecases/generate_image_use_case.dart';
import '../../domain/usecases/generate_image_edit_use_case.dart';
import '../../domain/usecases/generate_meme_use_case.dart';
import '../../domain/usecases/get_openai_api_key_use_case.dart';
import '../../domain/usecases/get_chat_thread_use_case.dart';
import '../../domain/usecases/load_chat_threads_use_case.dart';
import '../../domain/usecases/save_chat_thread_use_case.dart';
import '../../domain/usecases/send_message_use_case.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConfigRepository>()) {
      Get.lazyPut<ConfigRepository>(
        () => ConfigRepositoryImpl(Get.find<AppConfigDataSource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ChatRemoteDataSource>()) {
      Get.lazyPut(ChatRemoteDataSource.new, fenix: true);
    }
    if (!Get.isRegistered<ChatStorageDataSource>()) {
      Get.lazyPut<ChatStorageDataSource>(
        () => FirestoreChatDataSource(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<DocumentDataSource>()) {
      Get.lazyPut(DocumentDataSource.new, fenix: true);
    }
    if (!Get.isRegistered<ChatRepository>()) {
      Get.lazyPut<ChatRepository>(
        () => ChatRepositoryImpl(
          remoteDataSource: Get.find<ChatRemoteDataSource>(),
          storageDataSource: Get.find<ChatStorageDataSource>(),
          documentDataSource: Get.find<DocumentDataSource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetOpenAiApiKeyUseCase>()) {
      Get.lazyPut(
        () => const GetOpenAiApiKeyUseCase(),
        fenix: true,
      );
      Get.lazyPut(
        () => SendMessageUseCase(
          chatRepository: Get.find<ChatRepository>(),
          historyRepository: Get.find<HistoryRepository>(),
        ),
        fenix: true,
      );
      Get.lazyPut(
        () => CheckGrammarUseCase(
          chatRepository: Get.find<ChatRepository>(),
          historyRepository: Get.find<HistoryRepository>(),
        ),
        fenix: true,
      );
      Get.lazyPut(
        () => AnalyzePlagiarismUseCase(
          chatRepository: Get.find<ChatRepository>(),
          historyRepository: Get.find<HistoryRepository>(),
        ),
        fenix: true,
      );
      Get.lazyPut(
        () => LoadChatThreadsUseCase(Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => SaveChatThreadUseCase(Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => GetChatThreadUseCase(Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => CancelActiveRequestUseCase(Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () =>
            ClassifyMessageUseCase(chatRepository: Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => GenerateImageUseCase(chatRepository: Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => GenerateImageEditUseCase(chatRepository: Get.find<ChatRepository>()),
        fenix: true,
      );
      Get.lazyPut(
        () => GenerateMemeUseCase(repository: Get.find<ChatRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ChatController>()) {
      Get.lazyPut<ChatController>(
        () => ChatController(
          sendMessageUseCase: Get.find<SendMessageUseCase>(),
          checkGrammarUseCase: Get.find<CheckGrammarUseCase>(),
          analyzePlagiarismUseCase: Get.find<AnalyzePlagiarismUseCase>(),
          loadChatThreadsUseCase: Get.find<LoadChatThreadsUseCase>(),
          saveChatThreadUseCase: Get.find<SaveChatThreadUseCase>(),
          getChatThreadUseCase: Get.find<GetChatThreadUseCase>(),
          cancelActiveRequestUseCase: Get.find<CancelActiveRequestUseCase>(),
          classifyMessageUseCase: Get.find<ClassifyMessageUseCase>(),
          generateImageUseCase: Get.find<GenerateImageUseCase>(),
          generateImageEditUseCase: Get.find<GenerateImageEditUseCase>(),
          generateMemeUseCase: Get.find<GenerateMemeUseCase>(),
        ),
        fenix: true,
      );
    }
  }
}
