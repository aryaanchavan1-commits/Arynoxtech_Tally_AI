@echo off
set JAVA_HOME=D:\OpenJDK21U-jdk_x64_windows_hotspot_21.0.11_10\jdk-21.0.11+10
set PATH=%JAVA_HOME%\bin;%PATH%
set ANDROID_HOME=D:\Android\Sdk
set ANDROID_SDK_ROOT=D:\Android\Sdk
set GRADLE_USER_HOME=D:\.gradle
set TEMP=D:\tmp
set TMP=D:\tmp

echo Building APK...
cd /d D:\Arynoxtech_Tally\flutter_app
flutter build apk --release
if %ERRORLEVEL% EQU 0 (
    echo APK built successfully!
    echo Location: build\app\outputs\flutter-apk\
) else (
    echo Build failed.
)
pause
