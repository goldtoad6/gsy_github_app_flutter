import 'package:flutter_test/flutter_test.dart';
import 'package:gsy_github_app_flutter/widget/pull/gsy_rive_pull_animation.dart';

void main() {
  test('migration preserves the legacy pull threshold and unbounded time', () {
    expect(gsyRefreshAnimationTime(10, 0, 140), 0);
    expect(gsyRefreshAnimationTime(10, 140, 140), closeTo(3.6, 1e-12));
    expect(gsyRefreshAnimationTime(10, 350, 140), closeTo(2.5, 1e-12));
    expect(gsyRefreshAnimationTime(10, 140 / .6, 140), closeTo(10, 1e-12));
    expect(gsyRefreshAnimationTime(10, 140 / .6 + .01, 140), lessThan(1e-7));
    // Flare applies the last pose beyond the duration, but keeps the raw time
    // when refresh switches into a looping animation. Do not clamp the model.
    expect(gsyRefreshAnimationTime(10, 600, 140), greaterThan(10));
  });
}
