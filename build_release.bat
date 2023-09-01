@echo off

@rem Tester feature
if "%1%"=="tester" (
  git checkout master
  echo Building with tester feature
  @rem Use dart-define to specify the tester feature.
  @rem This sets the right dart environment variables which are then queried in constants.dart
  flutter build apk --split-per-abi --dart-define=DEFINE_HAS_TESTER_FEATURE=true
  exit /b
)
@rem Small feature: does not include google_ml_kit
if "%1%"=="small" (
    echo Building with small feature
  @rem Switch to feature branch and update it with master
  git checkout smaller
  git rebase -X ours master
  @rem Remove google_ml_kit just to be safe
  flutter pub remove google_mlkit_text_recognition
  @rem Actually build the dam thing
  flutter build apk --split-per-abi --dart-define=DEFINE_HAS_SMALL_FEATURE=true
  @rem Just to make sure, that people don't accidentally commit to the "smaller" feature branch
  git checkout master
  flutter pub get
  exit /b
)
@rem Default release build
git checkout master
flutter build apk --split-per-abi