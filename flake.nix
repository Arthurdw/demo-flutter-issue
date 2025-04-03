{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        buildToolsVersion = "34.0.0";
        sdkArgs = {
          buildToolsVersions = [ buildToolsVersion "28.0.3" ];
          platformVersions = [ "34" "28" ];
          # abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          abiVersions = [ "x86_64" ];
          includeSystemImages = true;
          includeEmulator = "if-supported";
          extraLicenses = [
            "android-sdk-preview-license"
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidComposition = pkgs.androidenv.composeAndroidPackages sdkArgs;
        androidEmulator = pkgs.androidenv.emulateApp {
          name = "android-sdk-emulator";
          configOptions = { "hw.keyboard" = "yes"; };
          sdkExtraArgs = sdkArgs;
        };
        androidSdk = androidComposition.androidsdk;
        platformTools = androidComposition.platform-tools;
        emulator_name = "demo-app";
        jdk = pkgs.jdk17;
      in {
        devShells.default = pkgs.mkShell rec {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_NDK_ROOT = "${ANDROID_SDK_ROOT}/ndk-bundle";
          JAVA_HOME = "${jdk}/lib/openjdk";

          buildInputs = with pkgs; [
            # For more packages/package search go to https://search.nixos.org/
            flutter
            jdk
            gradle

            # Android SDK
            androidSdk
            platformTools
            androidEmulator
          ];

          shellHook = ''
            # create emulator if it doesn't exist
            if ! avdmanager list avd | grep -q "${emulator_name}"; then
              echo "Creating emulator ${emulator_name}..."
              flutter emulator --create --name ${emulator_name}
            fi
          '';
        };
      });
}
