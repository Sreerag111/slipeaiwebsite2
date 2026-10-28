import 'app_config_data_source.dart';
import 'config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  const ConfigRepositoryImpl(this._dataSource);

  final AppConfigDataSource _dataSource;

  @override
  String getAuthBaseUrl() => _dataSource.authBaseUrl;
}
