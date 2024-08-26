import 'package:get/get.dart';
import 'package:rhythm_box/translations/en_us.dart';
import 'package:rhythm_box/translations/zh_cn.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': i18nEnglish,
        'zh_CN': i18nSimplifiedChinese,
      };
}
