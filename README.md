# Windows 11でAndroid版LINEを使う

Windows版LINEよりAndroid版の操作感を好む人向けに、Windows 11へWSABuildsとGoogle Playを導入し、Android版LINEを通知領域へ常駐させるまでの手順をまとめています。

このリポジトリにはWSA、Google Play、LINE本体は含めていません。配布元の正規ページから各自で取得してください。

## 先に知っておくこと

- Microsoft公式のWindows Subsystem for Android（WSA）は、2025年3月5日にサポートとMicrosoft Storeでの配布を終了しました。
- この手順で使う[MustardChef/WSABuilds](https://github.com/MustardChef/WSABuilds)はコミュニティーによる非公式ビルドです。Microsoft、Google、LINEヤフーによるサポートは受けられません。
- Windows Update、Google Play開発者サービス、LINE側の仕様変更により、将来動かなくなる可能性があります。
- GoogleアカウントとLINEアカウントを扱います。配布元、ファイル名、ハッシュ値を確認し、自己責任で利用してください。
- LINEのトーク履歴など、必要なデータは作業前にバックアップしてください。

Microsoftの案内: [Amazon AppstoreとWSAのサポート終了](https://support.microsoft.com/en-us/windows/apps/mobileapps/uninstall-the-amazon-appstore-and-mobile-apps-on-windows)

## この構成でできること

- Windows 11上でAndroid版LINEを起動
- Google PlayからLINEをインストール
- Google Play経由でLINEを自動更新
- Windowsへのサインイン時にLINEと常駐ヘルパーを自動起動
- LINEのウィンドウを隠して、右下の通知領域へLINEアイコンで常駐
- スタートメニューの「LINE (Android)」または通知領域アイコンのダブルクリックで再表示
- PowerShell画面を出さずに起動

## 動作確認環境

| 項目 | 内容 |
|---|---|
| OS | Windows 11 Home 23H2 / build 22631 / x64 |
| WSA | 2407.40000.4.0 |
| WSABuilds | LTS Build 7 Hotfix 1 |
| Android | 13 |
| LINE | `jp.naver.line.android` 26.13.1 |
| 確認日 | 2026-08-30 |

確認時に使ったファイル:

- `WSA_2407.40000.4.0_x64_Release-Nightly-GApps-13.0-NoAmazon.7z`
- SHA-256: `7db5aa71251c9665ca9fda451b6b6af6d0e430158578e354d9f964cab8c9ad7b`
- Playストア復旧用NoGApps版のSHA-256: `d3f4d324651dcdef8bfd7049c7a566994b7eae3f093d3fff2676ac9f205d8b04`

新規導入時は固定リンクではなく、[WSABuildsの最新リリース](https://github.com/MustardChef/WSABuilds/releases)と説明を確認してください。

## 1. 必要条件を確認する

- Windows 11 x64
- 8 GB以上のメモリ（16 GB推奨）
- SSD推奨
- NTFS形式のドライブ
- BIOS/UEFIでCPU仮想化が有効
- 管理者権限
- 7-ZipまたはWinRARの最新版

タスクマネージャーの「パフォーマンス」→「CPU」で、「仮想化: 有効」になっていることを確認します。

## 2. Windowsの仮想化機能を有効にする

「ターミナル（管理者）」または「PowerShell（管理者）」を開き、次を実行します。

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart
```

完了したらWindowsを再起動します。

## 3. WSABuildsを導入する

1. [MustardChef/WSABuilds Releases](https://github.com/MustardChef/WSABuilds/releases)を開きます。
2. Windows 11 x64用の最新安定版を選びます。
3. Google Playを使うため、ファイル名に `GApps` または `MindTheGapps` が含まれるものを選びます。
4. Amazon Appstoreが不要なら、`NoAmazon` または `RemovedAmazon` を選びます。
5. ダウンロードした7zファイルのSHA-256をリリース記載値と照合します。

```powershell
Get-FileHash "C:\Users\あなた\Downloads\ダウンロードしたファイル.7z" -Algorithm SHA256
```

7zを展開し、フォルダーを削除されない恒久的な場所へ移動します。例:

```text
C:\Users\あなた\Documents\WSA
```

WSABuildsは展開済みファイルをAppxとして登録する方式です。インストール後もこのフォルダーを移動・削除しないでください。また、exFATではなくNTFS上へ置いてください。

展開先の `Run.bat` を右クリックし、「管理者として実行」します。画面の指示に従い、WSAが起動するまで待ちます。

既存の公式WSAや別の改造版WSAがある場合は、WSABuildsのリリース説明に従って先に完全アンインストールしてください。データを引き継ぐ場合は、作業前に次のファイルをバックアップします。

```text
%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalCache\userdata.vhdx
```

## 4. Google PlayへログインしてLINEを入れる

1. スタートメニューから「Windows Subsystem for Android」を開きます。
2. WSAを一度起動し、初期化が完了するまで待ちます。
3. スタートメニューから「Play ストア」を開きます。
4. Googleアカウントでログインします。
5. Google Playで[LINE（公式）](https://play.google.com/store/apps/details?id=jp.naver.line.android)を検索します。
6. パッケージ名が `jp.naver.line.android` であることを確認し、インストールします。
7. LINEを起動してログインします。

非公式APK配布サイトからLINEを入れると、Google Playによる正常な更新や署名検証を利用できない場合があります。このガイドではGoogle Play版だけを使います。

## 5. LINEを自動更新する

Google Playを開き、右上のプロフィール画像から次の設定を行います。

1. 「設定」→「ネットワーク設定」→「アプリの自動更新」を開きます。
2. 「Wi-Fi経由のみ」または「すべてのネットワーク」を選びます。
3. LINEのGoogle Play詳細ページを開き、右上のメニューから「自動更新の有効化」がオンになっていることを確認します。

Google Playは更新を順次配信するため、公開直後に必ず更新されるわけではありません。Googleアカウントのログインエラー、ストレージ不足、WSAが長期間起動していない場合も自動更新されないことがあります。

手動確認は「Play ストア」→プロフィール画像→「アプリとデバイスの管理」→「アップデート利用可能」から行えます。公式説明は[Google Playヘルプ](https://support.google.com/googleplay/answer/113412?hl=ja)を参照してください。

このリポジトリの常駐ヘルパーを使うとWindowsログイン時にWSAが起動するため、Google Playのバックグラウンド更新が動ける状態を作りやすくなります。ただし、更新時刻を強制するものではありません。

## 6. LINEを通知領域へ常駐させる

このリポジトリを取得します。

```powershell
git clone https://github.com/hinatamaxxx/windows-11-android-line-wsa-guide.git
cd windows-11-android-line-wsa-guide
```

通常のPowerShellで次を実行します。管理者権限は不要です。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

インストーラーは次の設定だけを行います。

- `%LOCALAPPDATA%\WSA-LINE-Tray` へ常駐ヘルパーをコピー
- インストール済みAndroid版LINEのアイコンをWSAのローカルデータからコピー
- スタートメニューへ「LINE (Android)」を作成
- スタートアップへ常駐ヘルパーのショートカットを作成
- 常駐ヘルパーを起動

以後はスタートメニューの「LINE (Android)」を使います。必要なら右クリックして「タスクバーにピン留めする」を選んでください。WSAが自動生成した別のLINEアイコンを固定している場合は、混同を防ぐため固定を外します。

### 常駐アイコンの操作

- ダブルクリック: LINEを表示
- 右クリック→「Show LINE」: LINEを表示
- 右クリック→「Hide to tray」: LINEのウィンドウを非表示
- 右クリック→「Close LINE」: Android版LINEのウィンドウを閉じる
- 右クリック→「Exit tray helper」: ヘルパーだけを終了

Windows 11でアイコンが見えない場合は、「設定」→「個人用設定」→「タスクバー」→「その他のシステム トレイ アイコン」で表示を有効にします。

## Playストアがすぐ落ちる場合

まず次を順番に試します。

1. WSAの設定画面からWSAをシャットダウンする。
2. Windowsを再起動する。
3. WSAを起動し、初期化完了後にPlayストアを開く。
4. WSABuildsの同じリリースを再展開し、`Run.bat` で再登録する。
5. 改善しない場合は、`userdata.vhdx` をバックアップしてクリーンインストールする。

### LTS 7 Hotfix 1で実際に有効だった回避策

検証環境では、GApps版のクリーンインストール直後にPlayストアが落ち続けました。次の順序で復旧しました。

1. 同一リリース・同一アーキテクチャの `NoGApps-NoAmazon` 版を別フォルダーへ展開する。
2. 既存データをバックアップ後、WSAをアンインストールする。
3. NoGApps版の `Run.bat` を管理者として実行し、WSAを一度完全に初期化する。
4. WSAをシャットダウンする。
5. 同一リリースの `GApps-NoAmazon` 版ファイルをNoGApps版の展開先へ上書きする。
6. `Run.bat` を再度管理者として実行し、WSAを再登録する。
7. WSAを起動してからPlayストアを開く。

これは公式の標準手順ではなく、同じビルド同士でのみ試した回避策です。異なるWSAバージョンやx64/ARM64を混ぜないでください。先に[WSABuildsのIssues](https://github.com/MustardChef/WSABuilds/issues)で同じ症状と最新の解決策を確認してください。

## WSA本体を更新する

LINEはGoogle Playで自動更新できますが、WSABuilds本体は原則として手動更新です。

1. [WSABuilds Releases](https://github.com/MustardChef/WSABuilds/releases)で新しいリリースと注意事項を確認します。
2. `userdata.vhdx` をバックアップします。
3. 同じエディション、アーキテクチャ、GApps構成の更新版を選びます。
4. リリースに記載された更新手順を優先します。
5. 更新後にPlayストア、LINE、通知、常駐ヘルパーを確認します。

WSABuilds側の更新を完全自動化すると、壊れたリリースや構成違いまで無人適用する危険があります。このガイドではLINEだけを自動更新し、WSA本体はバックアップを取って手動更新する方針です。

## 開発者モードとADB

通常利用ではWSAの開発者モードは不要です。ADBで確認や修復を行った場合は、作業後に開発者モードをオフにし、ADBサーバーも終了します。

```powershell
adb kill-server
```

開発者モードを常時有効にしないことで、不要なローカルADB接続口を閉じられます。

## 常駐ヘルパーを削除する

リポジトリのフォルダーで次を実行します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

常駐ヘルパーと作成したショートカットだけを削除します。LINE、WSA、トーク履歴は削除しません。

## よくある問題

### PowerShellの画面が出る

スタートメニューの「LINE (Android)」を使ってください。このショートカットは `wscript.exe` を経由してPowerShellを非表示で実行します。WSAが自動生成したLINEショートカットとは別物です。

### LINEが開かず、アイコンだけ常駐する

通知領域のLINEアイコンをダブルクリックします。改善しない場合はWSAを一度シャットダウンし、スタートメニューの「LINE (Android)」から起動し直します。

### アイコンが汎用アイコンになる

Android版LINEを一度起動した後、`install.ps1` を再実行してください。WSAが生成した `jp.naver.line.android.ico` を再取得します。

### 通知が来ない

AndroidのLINE設定、WSAの通知設定、Windowsの通知設定、省電力設定を確認します。WSA自体が停止している間はAndroid側のバックグラウンド通知を受け取れません。

## 免責とライセンス

このガイドと常駐ヘルパーは無保証です。アカウント、データ、端末に生じた損害について作者は責任を負いません。

常駐ヘルパーのコードは[MIT License](LICENSE)です。LINEおよびLINEロゴはLINEヤフー株式会社の商標または登録商標です。このリポジトリは同社と提携・承認関係にありません。
