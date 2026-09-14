// 2026-09-13: Local runtime fixture for the migrated refresh indicator.
// Uses the production sliver, pull widget and adaptive shell. No account or
// network fixtures are needed; Dart MCP drives the ScrollPosition drag API.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gsy_github_app_flutter/common/localization/extension.dart';
import 'package:gsy_github_app_flutter/common/localization/l10n/app_localizations.dart';
import 'package:gsy_github_app_flutter/common/style/gsy_adaptive_shell.dart';
import 'package:gsy_github_app_flutter/widget/gsy_tabbar_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_pull_new_load_widget.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_rive_pull_animation.dart';
import 'package:rive/rive.dart' as rive;

final smokeScroll = ScrollController();
final smokeRoot = GlobalKey<NavigatorState>();
final smokeControl = GSYPullLoadWidgetControl()
  ..needHeader = false
  ..needLoadMore = false
  ..dataList = List<int>.generate(24, (i) => i + 1);
Completer<void>? smokeRefresh;
Drag? smokeDrag;
int refreshCount = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  GSYAdaptiveNavigation.instance.attachRootNavigator(smokeRoot);
  runApp(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: smokeRoot,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l = context.l10n;
            return GSYTabBarWidget(
              type: TabType.bottom,
              title: Text(l.app_name),
              clearDetailStackOnDispose: true,
              tabItems: [Text(l.home_dynamic), Text(l.home_trend)],
              railDestinations: [
                GSYAdaptiveDestination(
                  icon: Icons.public,
                  label: l.home_dynamic,
                ),
                GSYAdaptiveDestination(
                  icon: Icons.trending_up,
                  label: l.home_trend,
                ),
              ],
              tabViews: [
                GSYPullLoadWidget(
                  smokeControl,
                  (context, index) => ListTile(
                    leading: const Icon(Icons.public),
                    title: Text('${context.l10n.home_dynamic} ${index + 1}'),
                  ),
                  () {
                    refreshCount++;
                    smokeRefresh = Completer<void>();
                    return smokeRefresh!.future;
                  },
                  null,
                  scrollController: smokeScroll,
                  userIos: true,
                ),
                Center(child: Text(l.home_trend)),
              ],
            );
          },
        ),
      ),
    ),
  );
}

void beginPull(double logicalDistance) {
  smokeDrag?.cancel();
  smokeDrag = smokeScroll.position.drag(DragStartDetails(), () {});
  updatePull(logicalDistance);
}

void updatePull(double logicalDistance) => smokeDrag!.update(
  DragUpdateDetails(
    globalPosition: Offset.zero,
    delta: Offset(0, logicalDistance),
    primaryDelta: logicalDistance,
  ),
);

void releasePull() {
  smokeDrag?.end(DragEndDetails(primaryVelocity: 0));
  smokeDrag = null;
}

void finishRefresh() {
  if (smokeRefresh != null && !smokeRefresh!.isCompleted) {
    smokeRefresh!.complete();
  }
}

// Read actual mounted production widgets for Dart MCP evidence. This does not
// override layout, scroll position, refresh state, or animation progress.
Map<String, Object?> smokeSnapshot() {
  final indicators = <Map<String, Object>>[];
  var navigators = 0;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Navigator) navigators++;
    if (widget is GSYRivePullAnimation) {
      indicators.add({
        'pulledExtent': widget.pulledExtent,
        'trigger': widget.refreshTriggerPullDistance,
        'playAuto': widget.playAuto,
      });
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return {
    'refreshCount': refreshCount,
    'refreshPending': smokeRefresh != null && !smokeRefresh!.isCompleted,
    'scrollOffset': smokeScroll.hasClients ? smokeScroll.offset : null,
    'dragActive': smokeDrag != null,
    'navigatorCount': navigators,
    'indicators': indicators,
  };
}
