abstract class PremiumRepository {
  bool getIsPremium();
  Future<void> setIsPremium(bool value);
  int getChatCount();
  Future<void> incrementChatCount();
  int getImageCount();
  Future<void> incrementImageCount();
  int getMemeCount();
  Future<void> incrementMemeCount();
  Future<void> resetCounts();
  bool getIsTrialActive();
  Future<void> setIsTrialActive(bool value);
  bool getIsAutoPayEnabled();
  Future<void> setIsAutoPayEnabled(bool value);
}

