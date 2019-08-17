# SkyWay CallKit Sampler

SkyWay と CallKit を使ったアプリのサンプルコードです。

![image](./callkit-native-ui.png)

# 対応OS

iOS 10+

# ビルド手順

## CocoaPods

チェックアウトしたディレクトリで以下のコマンドを実行

```bash
$ pod install
```

## API KEY

skyway-callkit-sampler.xcworkspace を開いて AppDelegate.swift に SkyWay の API KEY と Domain をセットします

```swift
-    var skywayAPIKey:String?
-    var skywayDomain:String?
+    let skywayAPIKey = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
+    let skywayDomain = "localhost"
```

## AppID、Provisioning Profile

TARGETS から skyway-callkit-sampler を選んで Signing（署名）を設定します

## Build

実機を選んでビルド（CallKitはSimulatorに対応していません）
