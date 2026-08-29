# Android版LINEをWindows 11で使う

PC版LINEがどうにも使いづらかったので、Windows 11にAndroid版LINEを入れてみました。

このガイドでは、Android版LINEのインストールだけでなく、Windowsへのログインと同時に起動し、タスクバー右下の通知領域へLINEアイコンで常駐させるところまで扱います。LINEアプリはGoogle Playから自動更新されます。

## いちばん簡単なやり方

細かい手順を自分で追うより、**CodexやClaude Codeなどのコーディングエージェントに、このページのURLを渡して頼む**のが楽です。

たとえば、次のように頼んでください。

```text
このガイドを読んで、私のWindows 11にAndroid版LINEを入れてください。
Google PlayからLINEを自動更新できるようにして、Windows起動時に自動起動し、
タスクバー右下の通知領域へLINEアイコンで常駐するところまで設定してください。

https://github.com/hinatamaxxx/windows-11-android-line-wsa-guide
```

途中でWindowsの再起動、Googleアカウントへのログイン、LINEへのログインが必要になります。その部分だけは自分で操作してください。管理者権限を求められたときも、表示されている内容を確認してから許可しましょう。

正直に言うと、このガイドを公開している私もWSAの仕組みを隅々まで理解しているわけではありません。実際に動いた手順を、あとから再現できるようにまとめたものです。

Microsoftのサポートが終わった機能と非公式ビルドを使います。突然動かなくなったり、Windows Updateの影響を受けたりする可能性があります。大切なトーク履歴などは先にバックアップし、**自己責任で試してください**。

## どんな状態になるの？

設定が終わると、次のようになります。

- Windows 11でAndroid版LINEが動く
- LINEはGoogle Playからインストールされる
- LINEの新しいバージョンはGoogle Play経由で自動更新される
- Windowsへログインすると、LINEと常駐用ヘルパーが自動で立ち上がる
- LINEの画面を閉じても、タスクバー右下の通知領域にLINEアイコンが残る
- LINEアイコンをダブルクリックすると、LINEの画面が戻ってくる
- スタートメニューの「LINE (Android)」から普通に起動できる
- 起動時にPowerShellの黒い画面は出ない

## 先に知っておいてほしいこと

WindowsでAndroidアプリを動かすために使われていた「Windows Subsystem for Android」、通称WSAは、2025年3月5日でMicrosoftのサポートとMicrosoft Storeでの配布が終わりました。

そこで今回は、コミュニティーがメンテナンスしている[MustardChef/WSABuilds](https://github.com/MustardChef/WSABuilds)を使います。これはMicrosoft、Google、LINEヤフーの公式ツールではありません。

そのため、次の点を理解したうえで使ってください。

- MicrosoftやLINEの公式サポートへ問い合わせても対応してもらえません
- WindowsやLINEの仕様変更で使えなくなる可能性があります
- GoogleアカウントとLINEアカウントを扱うため、ファイルは必ず正しい配布元から入手してください
- LINEやWSAの中にある大切なデータは、作業前にバックアップしてください

Microsoftによる案内はこちらです。

- [Amazon AppstoreとWSAのサポート終了について](https://support.microsoft.com/ja-jp/windows/apps/mobileapps/uninstall-the-amazon-appstore-and-mobile-apps-on-windows)

## 今回、実際に動いた環境

| 項目 | 内容 |
|---|---|
| Windows | Windows 11 Home 23H2 / build 22631 / x64 |
| WSA | 2407.40000.4.0 |
| WSABuilds | LTS Build 7 Hotfix 1 |
| Android | Android 13 |
| LINE | 26.13.1 / `jp.naver.line.android` |
| 確認日 | 2026年8月30日 |

使ったWSABuildsのファイルは次のものです。

```text
WSA_2407.40000.4.0_x64_Release-Nightly-GApps-13.0-NoAmazon.7z
```

確認したSHA-256は次のとおりです。

```text
7db5aa71251c9665ca9fda451b6b6af6d0e430158578e354d9f964cab8c9ad7b
```

Playストアの復旧に使ったNoGApps版のSHA-256はこちらです。

```text
d3f4d324651dcdef8bfd7049c7a566994b7eae3f093d3fff2676ac9f205d8b04
```

これから新しく入れる場合は、同じファイルに決め打ちせず、[WSABuildsの最新リリース](https://github.com/MustardChef/WSABuilds/releases)に書かれている説明を優先してください。

---

## ここから手作業で進める場合の手順

CodexやClaude Codeへ任せず、自分で作業する場合はこちらを上から順番に進めます。

## 1. パソコンが対応しているか確認する

目安は次のとおりです。

- Windows 11の64ビット版
- メモリ8 GB以上、できれば16 GB以上
- SSD推奨
- WSAを置くドライブがNTFS形式
- BIOSまたはUEFIでCPUの仮想化が有効
- Windowsの管理者権限を使える
- 新しいバージョンの7-ZipまたはWinRAR

仮想化については、タスクマネージャーを開いて「パフォーマンス」→「CPU」と進み、「仮想化: 有効」になっていれば大丈夫です。

「無効」になっている場合は、パソコンのBIOSまたはUEFI設定でIntel VT-x、Intel Virtualization Technology、AMD-V、SVMなどの項目を有効にします。名称はメーカーによって違います。

## 2. Windowsの仮想化機能を有効にする

スタートボタンを右クリックし、「ターミナル（管理者）」を開きます。次の2行を順番に実行してください。

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:HypervisorPlatform /all /norestart
```

処理が終わったらWindowsを再起動します。

## 3. WSABuildsをダウンロードする

1. [WSABuildsのリリースページ](https://github.com/MustardChef/WSABuilds/releases)を開きます。
2. Windows 11 x64向けの新しい安定版を探します。
3. Google Playを使いたいので、ファイル名に `GApps` または `MindTheGapps` が入っているものを選びます。
4. Amazon Appstoreがいらない場合は、`NoAmazon` または `RemovedAmazon` と書かれているものを選びます。

似た名前のファイルがたくさんあります。x64とARM64、GAppsありとなしを間違えないようにしてください。

ダウンロードが終わったら、ファイルが壊れていないかSHA-256を確認します。PowerShellで次のように実行します。

```powershell
Get-FileHash "C:\Users\あなたの名前\Downloads\ダウンロードしたファイル.7z" -Algorithm SHA256
```

表示された値を、リリースページに書かれている値と見比べます。

## 4. WSABuildsをインストールする

ダウンロードした7zファイルを展開し、消したり移動したりしない場所へ置きます。

たとえば、次のような場所です。

```text
C:\Users\あなたの名前\Documents\WSA
```

WSABuildsは、展開したファイルをその場所からWindowsへ登録して使います。インストール後にフォルダーを削除したり、別の場所へ移したりすると動かなくなります。また、exFATではなくNTFSのドライブへ置いてください。

展開したフォルダーの中にある `Run.bat` を右クリックし、「管理者として実行」を選びます。あとは画面の指示に従い、WSAが起動するまで待ちます。

すでに公式版WSAや別の改造版WSAを入れている場合は、WSABuildsの説明に従って先にアンインストールします。以前のデータを残したい場合は、次のファイルを別の場所へコピーしておきます。

```text
%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalCache\userdata.vhdx
```

## 5. Google PlayからLINEを入れる

1. スタートメニューから「Windows Subsystem for Android」を開きます。
2. 最初の起動には少し時間がかかるので、初期化が終わるまで待ちます。
3. スタートメニューから「Play ストア」を開きます。
4. Googleアカウントでログインします。
5. Playストアで「LINE」を検索します。
6. 提供元とパッケージ名 `jp.naver.line.android` を確認してインストールします。
7. LINEを開き、自分のアカウントでログインします。

LINEはこちらの[Google Play公式ページ](https://play.google.com/store/apps/details?id=jp.naver.line.android)から確認できます。

よく分からないAPK配布サイトからLINEをダウンロードするのはおすすめしません。Google Playから入れておけば、署名を確認した正規アプリを使え、更新もGoogle Playへ任せられます。

## 6. LINEを自動更新する

Playストアを開き、右上にある自分のプロフィール画像を押します。

1. 「設定」を開きます。
2. 「ネットワーク設定」を開きます。
3. 「アプリの自動更新」を選びます。
4. 「Wi-Fi経由のみ」または「すべてのネットワーク」を選びます。

次にLINEのPlayストア画面を開き、右上のメニューにある「自動更新の有効化」がオンになっていることを確認します。

更新があるか自分で確認したいときは、「Play ストア」→プロフィール画像→「アプリとデバイスの管理」→「アップデート利用可能」と進みます。

Google Playの自動更新は、最新版が出た瞬間に必ず始まるわけではありません。Googleアカウントのエラー、空き容量不足、WSAが長い間起動していない場合などは更新されないことがあります。

- [Google Play公式ヘルプ: Androidアプリを更新する方法](https://support.google.com/googleplay/answer/113412?hl=ja)

このあと設定する常駐ヘルパーは、Windowsへのログイン時にWSAを起動します。そのため、Google Playがバックグラウンドで更新を確認しやすい状態になります。ただし、決まった時刻に更新を強制するものではありません。

## 7. LINEをタスクバー右下へ常駐させる

ここからは、このリポジトリに入っている常駐ヘルパーを使います。

Gitが使える場合は、PowerShellで次のように取得します。

```powershell
git clone https://github.com/hinatamaxxx/windows-11-android-line-wsa-guide.git
cd windows-11-android-line-wsa-guide
```

Gitを使わない場合は、GitHubページ右上付近にある「Code」→「Download ZIP」からダウンロードし、ZIPを展開してください。

取得したフォルダーでPowerShellを開き、次を実行します。ここは管理者権限なしで大丈夫です。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

このスクリプトが行うことは次のとおりです。

- `%LOCALAPPDATA%\WSA-LINE-Tray` に常駐ヘルパーをコピーする
- WSAが作ったAndroid版LINEのアイコンをコピーする
- スタートメニューに「LINE (Android)」を作る
- Windowsのスタートアップに常駐ヘルパーを登録する
- 常駐ヘルパーをその場で起動する

設定後は、スタートメニューの「LINE (Android)」からLINEを開いてください。よく使う場合は右クリックして、タスクバーへピン留めすると便利です。

WSAが自動で作ったLINEショートカットをすでにピン留めしている場合は、見分けがつきにくいので古いほうのピン留めを外し、新しい「LINE (Android)」を固定し直してください。

### 右下のLINEアイコンでできること

- ダブルクリック: LINEの画面を表示
- `Show LINE`: LINEの画面を表示
- `Hide to tray`: LINEの画面を隠して、アイコンだけ残す
- `Close LINE`: Android版LINEの画面を閉じる
- `Exit tray helper`: 常駐ヘルパーを終了する

アイコンが隠れている場合は、「設定」→「個人用設定」→「タスクバー」→「その他のシステム トレイ アイコン」を開き、LINEの表示をオンにします。

---

## Playストアが起動してもすぐ落ちる場合

今回の環境では、最初にここで引っかかりました。まずは次の順番で試してください。

1. WSAの設定画面からWSAをシャットダウンする。
2. Windowsを再起動する。
3. WSAを先に起動し、初期化が終わってからPlayストアを開く。
4. 同じWSABuildsをもう一度展開し、`Run.bat` で再登録する。
5. 直らない場合は、`userdata.vhdx` をバックアップしてからクリーンインストールする。

### 今回、実際に直った方法

LTS 7 Hotfix 1では、GApps版を普通にクリーンインストールしただけだと、Playストアが落ち続けることがありました。今回のパソコンでは、次の手順で直りました。

1. 同じリリース、同じx64版の `NoGApps-NoAmazon` を別フォルダーへ展開する。
2. 必要なデータをバックアップしてから、現在のWSAをアンインストールする。
3. NoGApps版の `Run.bat` を管理者として実行する。
4. WSAを一度起動し、初期化が終わるまで待つ。
5. WSAをシャットダウンする。
6. 同じリリースの `GApps-NoAmazon` 版を、NoGApps版の展開先へ上書きする。
7. `Run.bat` をもう一度管理者として実行し、WSAを再登録する。
8. WSAを起動してからPlayストアを開く。

これはWSABuildsの標準的なインストール手順ではなく、今回の環境で効いた回避策です。違うバージョン同士、x64とARM64などを混ぜるのは避けてください。

同じ症状が出ている人がいるか、先に[WSABuildsのIssues](https://github.com/MustardChef/WSABuilds/issues)を確認することをおすすめします。新しい解決方法が案内されている場合は、そちらを優先してください。

## WSA本体の更新について

LINEアプリはGoogle Playに自動更新を任せられますが、WSABuilds本体は手動で更新するほうが安全です。

更新するときは、次の流れがおすすめです。

1. [WSABuildsのリリースページ](https://github.com/MustardChef/WSABuilds/releases)で新しい版と注意事項を確認する。
2. `userdata.vhdx` をバックアップする。
3. 現在と同じx64/ARM64、GAppsあり/なしの構成を選ぶ。
4. リリースページに書かれた更新手順に従う。
5. 更新後にPlayストア、LINE、通知、常駐ヘルパーを確認する。

WSABuildsまで完全自動更新にすると、問題のあるリリースや違う構成を気づかず入れてしまうおそれがあります。このガイドでは、LINEだけを自動更新し、WSABuildsはバックアップを取ってから手動更新する方針にしています。

## ADBを使った場合は、あとで閉じる

普通にLINEを使うだけなら、WSAの開発者モードやADBは必要ありません。

トラブル調査のためにADBを使った場合は、作業が終わったらWSAの開発者モードをオフにし、次のコマンドでADBも終了しておきます。

```powershell
adb kill-server
```

## 常駐設定を元に戻す

このリポジトリを展開したフォルダーで、次を実行します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

削除されるのは、このリポジトリが入れた常駐ヘルパーとショートカットだけです。LINE、WSA、トーク履歴は削除しません。

## 困ったとき

### LINEを起動したらPowerShellの画面が出てきた

スタートメニューの「LINE (Android)」から起動してください。このショートカットは、PowerShellを画面に出さないためのランチャーを経由します。WSAが最初から作っているLINEショートカットとは別物です。

### LINEが開かず、右下にアイコンだけ出ている

右下のLINEアイコンをダブルクリックしてください。それでも開かない場合は、WSAをいったんシャットダウンし、スタートメニューの「LINE (Android)」から起動し直します。

### LINEの緑色アイコンにならない

Android版LINEを一度起動してから、`install.ps1` をもう一度実行してください。WSAが作ったLINEアイコンを取り込み直します。

### LINEの通知が来ない

次の設定を順番に確認します。

- Android版LINEの通知設定
- WSA内のAndroid通知設定
- Windows 11の通知設定
- WindowsとWSAの省電力設定

WSAそのものが止まっている間は、Android版LINEもバックグラウンドで動けません。

## 最後に

この方法は、サポートが終了したWSAを非公式ビルドで動かすものです。「このとおりにすれば、どのパソコンでもずっと動く」と保証できるものではありません。

私の環境では動きましたが、環境によってはうまくいかないこともあると思います。バックアップを取り、表示された内容を確認しながら、自己責任で試してください。

常駐ヘルパーのコードは[MIT License](LICENSE)で公開しています。LINEおよびLINEロゴはLINEヤフー株式会社の商標または登録商標です。このリポジトリはLINEヤフー株式会社、Microsoft、Google、MustardChef/WSABuildsと提携・承認関係にありません。
