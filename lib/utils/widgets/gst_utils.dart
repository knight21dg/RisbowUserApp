import '../../config/settings_data_instance.dart';

class GstUtils {
  static const double _defaultCgst = 9;
  static const double _defaultSgst = 9;

  static bool get _settingsLoaded => SettingsData.instance.system != null;

  static double get totalPercent {
    final cgstStr = SettingsData.instance.system?.cgstPercent;
    final sgstStr = SettingsData.instance.system?.sgstPercent;
    if (cgstStr != null && sgstStr != null) {
      return (double.tryParse(cgstStr) ?? 0) + (double.tryParse(sgstStr) ?? 0);
    }
    return _defaultCgst + _defaultSgst;
  }

  static bool get hasGst => totalPercent > 0;

  static double getCgstPercent() {
    final val = SettingsData.instance.system?.cgstPercent;
    if (val != null) return double.tryParse(val) ?? 0;
    return _defaultCgst;
  }

  static double getSgstPercent() {
    final val = SettingsData.instance.system?.sgstPercent;
    if (val != null) return double.tryParse(val) ?? 0;
    return _defaultSgst;
  }

  static double getBasePrice(double inclusivePrice) {
    if (!hasGst || inclusivePrice <= 0) return inclusivePrice;
    return inclusivePrice / (1 + totalPercent / 100);
  }

  static double getTaxAmount(double inclusivePrice) {
    if (!hasGst || inclusivePrice <= 0) return 0;
    return inclusivePrice - getBasePrice(inclusivePrice);
  }

  static double getCgstAmount(double inclusivePrice) {
    return getTaxAmount(inclusivePrice) / 2;
  }

  static double getSgstAmount(double inclusivePrice) {
    return getTaxAmount(inclusivePrice) / 2;
  }

  static double getInclusivePrice(double exclusivePrice) {
    if (!hasGst || exclusivePrice <= 0) return exclusivePrice;
    return exclusivePrice * (1 + totalPercent / 100);
  }

  static double getCgstAmountFromExclusive(double exclusivePrice) {
    if (!hasGst || exclusivePrice <= 0) return 0;
    return exclusivePrice * getCgstPercent() / 100;
  }

  static double getSgstAmountFromExclusive(double exclusivePrice) {
    if (!hasGst || exclusivePrice <= 0) return 0;
    return exclusivePrice * getSgstPercent() / 100;
  }
}
