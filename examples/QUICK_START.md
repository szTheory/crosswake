# Crosswake Demo Quick Start

Welcome to the Crosswake example demo! This guide provides step-by-step instructions to test the bounded bridge proof and verify end-to-end functionality between your Phoenix LiveView server and the native mobile shells (iOS and Android).

## Prerequisites

Before you begin, ensure you have the following installed:
*   [Elixir](https://elixir-lang.org/install.html) and [Erlang](https://www.erlang.org/downloads)
*   [Xcode](https://developer.apple.com/xcode/) (for iOS)
*   [Android Studio](https://developer.android.com/studio) (for Android)

## 1. Start the Phoenix Server

First, you need to start the backend Phoenix application, which serves the LiveView pages that the mobile shells will load.

```bash
# Navigate to the Phoenix host example directory
cd examples/phoenix_host

# Install dependencies and set up the database (if needed)
mix setup

# Start the Phoenix server on localhost
mix phx.server
```

The server should now be running at `http://localhost:4000`. Leave this terminal running.

## 2. Start the Mobile Shells

You can run the demo on either iOS, Android, or both. They are configured to connect to your local Phoenix server.

### Run the iOS Shell

You can run the iOS shell using Xcode:

1.  Open the iOS workspace:
    ```bash
    open examples/ios_shell_host/ios_shell_host.xcodeproj
    ```
    *(Note: if using CocoaPods later, you might open `.xcworkspace` instead, but currently `.xcodeproj` is appropriate).*
2.  In Xcode, select your desired simulator (e.g., iPhone 15) and click the **Play (Run)** button or press `Cmd + R`.

Alternatively, you can build and run using `xcodebuild` from the terminal (if you have standard tools configured).

### Run the Android Shell

You can run the Android shell using Android Studio:

1.  Open **Android Studio**.
2.  Select **File -> Open...** and choose the `examples/android_shell_host` directory.
3.  Let the project sync (Gradle sync).
4.  Select an emulator or a connected physical device.
5.  Click the **Run (Play)** button or press `Shift + F10`.

Alternatively, if you have a device/emulator running, you can install via terminal:
```bash
cd examples/android_shell_host
./gradlew installDebug
```

## 3. Test the Native Bridge (Share Action)

Once the mobile app is running on your simulator or device:

1.  The app will load the default home page from the Phoenix server.
2.  Navigate to the Bridge Proof page by tapping the link or directly visiting the path if available in the UI. Ensure you navigate to: `/bridge-proof`.
3.  On the **Bridge Proof** page, you should see a button labeled **Trigger Native Share**.
4.  Tap the **Trigger Native Share** button.
5.  Verify that the native iOS or Android Share sheet opens with the title "Crosswake Demo".

Congratulations! You have successfully tested the LiveView-to-Native bridge communication.
