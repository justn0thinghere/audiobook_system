import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/language_state.dart';

/// Convenience helpers so any widget can call `context.tr('some.key')`
/// without manually pulling the LanguageState provider.
extension I18nContext on BuildContext {
  /// Use inside `build` — the widget rebuilds when the language changes.
  String tr(String key) => watch<LanguageState>().tr(key);

  /// Use in event handlers / callbacks (does not subscribe to changes).
  String trRead(String key) => read<LanguageState>().tr(key);
}
