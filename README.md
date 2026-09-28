# Android版LINEをWindows 11で使う

PC版LINEがどうにも使いづらかったので、Windows 11にAndroid版LINEを入れてみました。

このガイドでは、Android版LINEのインストールだけでなく、Windowsへのログインと同時に起動し、タスクバー右下の通知領域へLINEアイコンで常駐させるところまで扱います。LINEアプリはGoogle Playから自動更新されます。

## 2026年9月28日追記：Windows版LINE向けの非表示起動ツールも公開しました

Windows版LINEを使い、PC起動時に画面を出さず通知領域へ常駐させたい方に向けて、**[LINE Tray Startup](https://github.com/hinatamaxxx/line-startup-to-tray)** を公開しました。

**Windows版LINE（デスクトップ版）専用の補助ツール**です。Android版LINEを使う場合は、このページのWSA向け手順へ進んでください。

### Windows版向けツールのセットアップ

1. Windows版LINEにログインし、LINE本体の **自動ログインをON** にします。その後、通知領域のLINEを右クリックして **「終了」** します。
2. [配布ページ](https://github.com/hinatamaxxx/line-startup-to-tray/releases/tag/v0.2.0-preview.2)の **Assets** から `LineTrayStartup-Setup-0.2.0-preview.2.exe` をダウンロードします。
3. EXEを開き、**「セットアップ」** を押します。完了後は **「LINEを起動」** ボタンを押し、通知領域にアイコンが現れることと、ダブルクリックでLINEを開けることを確認してください。

管理者権限やコマンド入力は不要です。セットアップ後は、Windowsへのサインイン時に、本ツール経由でWindows版LINEを通知領域へ自動起動する設定になります。

このツールは、LINEがウィンドウを表示しようとするタイミングで表示要求を抑え、LINE本来の「閉じる」処理で通知領域へ移します。一定間隔でウィンドウを探す監視ループは使っていません。LINEの実行ファイルやログイン情報は変更しません。

現在は **プレビュー版** です。Windows 11 x64・LINE 26.4.2.3957で、非表示起動、アイコンからの再表示、ログイン維持を確認しています。**PC再起動を伴う最終確認は未実施**で、LINEの更新により動作しなくなる場合もあります。

詳しい使い方、対応環境、設定を元に戻す方法は、[LINE Tray Startupの利用案内](https://github.com/hinatamaxxx/line-startup-to-tray#readme)にまとめています。仕組みを詳しく知りたい方は、[実装の説明](https://github.com/hinatamaxxx/line-startup-to-tray/blob/main/docs/architecture.md)もご覧ください。

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

## 2026年9月12日追記：LINEが固まる問題は、WSAの更新で改善しました

しばらく使っていたところ、LINEが固まったり、操作が重くなったりするようになりました。調べてもらい、**WSABuildsをLTS 7 Hotfix 1からLTS 8へ更新したところ、私の環境では改善しました**。

今回はLINEを入れ直さず、ログイン状態とトーク履歴を残したまま更新できています。自動起動や右下への常駐設定もそのままです。

同じ症状で困っている方は、下の[「LINEが固まる・操作が重い場合」](#lineが固まる操作が重い場合)を確認してください。LINEアプリの自動更新とは別に、WSA本体の更新が必要でした。

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
| WSABuilds | LTS Build 8（LTS 7 Hotfix 1から更新） |
| Android | Android 13 |
| LINE | Google Play版 / `jp.naver.line.android`（初回導入時は26.13.1。更新後のLINEバージョンは未記録） |
| 確認日 | 初回導入：2026年8月30日 / LTS 8への更新・フリーズ改善：2026年9月12日 |

2026年9月12日の更新には、[LTS 8のリリースページ](https://github.com/MustardChef/WSABuilds/releases/tag/Windows_11_2407.40000.4.0_LTS_8)にある次のファイルを使いました。

```text
WSA_2407.40000.4.0_x64_Release-Nightly-GApps-13.0-NoAmazon.7z
```

配布元の値と一致を確認したSHA-256は次のとおりです。

```text
09e27a35ac19a8ca14967ad76afb64b6b1fe855a67f13a389618b4d6b1bd8f48
```

**ファイル名と、Windowsに表示されるWSAのバージョン番号 `2407.40000.4.0` は、以前の版と同じです。** ファイル名だけで判断せず、リリース名がLTS 8であることとSHA-256を確認してください。別のリリースや別構成のファイルに、このSHA-256は使えません。

以下は初回導入時の記録です。今回のLTS 8更新用ではありません。

LTS 7 Hotfix 1のGApps版のSHA-256：

```text
7db5aa71251c9665ca9fda451b6b6af6d0e430158578e354d9f964cab8c9ad7b
```

当時、Playストアの復旧に使ったLTS 7 Hotfix 1のNoGApps版のSHA-256：

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

すでに公式版WSAや別の改造版WSAを入れている場合は、WSABuildsの説明に従って移行します。**アンインストールするとアプリデータを失うおそれがあるため、先にバックアップしてください。** すでにWSABuildsを使っていて更新するだけなら、この新規導入手順ではなく、下の[「WSA本体の更新について」](#wsa本体の更新について)へ進みます。

アプリデータの保存先は次のフォルダーです。WSAを完全に停止してから、別の場所へコピーします。

```text
%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalCache
```

データファイルは必ずしも `userdata.vhdx` という名前ではありません。今回の環境では `userdata.2.vhdx` と `metadata.2.vhdx` がありました。名前を決め打ちせず、実際にあるファイルを確認してください。詳しい注意点は下の更新手順にまとめています。

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

**Google Playが更新するのはLINEなどのAndroidアプリです。WSABuilds本体や、このガイドの常駐ヘルパーは自動更新されません。** 今回のフリーズ対策は、WSA本体を更新する必要がありました。

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
5. 直らない場合は、下のWSA更新手順を参考にアプリデータをバックアップし、復元方法も確認してからクリーンインストールを検討する。

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

## 常駐ヘルパーを最新版にする

2026年8月31日に、次の2点を修正しました。

- LINEの起動待ち中もWindowsの終了通知に応答できるようにし、シャットダウンや再起動を待たせる原因になりうる処理をなくしました。
- バックグラウンド起動時に空のウィンドウだけが残る問題を修正しました。LINEをいったん最小化してから隠すことで、WSAの空の枠が残らないようにしています。

通常起動でLINEを再表示できること、アイコンだけで常駐できること、終了通知を送るテストでヘルパーが速やかに終了することを確認しています。実際の利用環境でも、シャットダウンの問題と空ウィンドウの解消を確認できました。

すでにこのリポジトリの `install.ps1` で設定した場合は、次の手順で更新してください。WSAやLINEを入れ直す必要はありません。

1. 右下のLINEアイコンを右クリックし、`Exit tray helper` でヘルパーを終了します。
2. Gitで取得した場合は、リポジトリのフォルダーで次を実行します。

   ```powershell
   git pull --ff-only
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

3. ZIPで取得した場合は、GitHubの「Code」→「Download ZIP」から最新版をダウンロードし、展開したフォルダーで `install.ps1` を実行します。

実行中のヘルパーは、ファイルを上書きするだけでは新しい処理に切り替わりません。先に `Exit tray helper` で終了するのがポイントです。LINEのアカウントやトーク履歴は変更しません。

## WSA本体の更新について

LINEアプリはGoogle Playに自動更新を任せられますが、WSABuilds本体は手動で更新するほうが安全です。

### LINEが固まる・操作が重い場合

2026年9月12日、トーク画面でLINEが固まり、操作も重くなる症状が出ました。

応答停止の記録を調べると、動く画像を表示する処理が、AndroidアプリをこのPCで動かすための「互換処理」の中で止まっていました。技術的には、APNG画像の描画・複製処理から呼ばれた `libhoudini.so` 内で、LINEの画面操作を受け持つ処理が止まっていた、という状況です。

配布元では、[LTS 8（2026年9月4日公開）](https://github.com/MustardChef/WSABuilds/releases/tag/Windows_11_2407.40000.4.0_LTS_8)で、9月1日以降に起きるアプリの起動失敗や停止などに関わるARM互換処理の不具合を修正したと案内しています。今回の記録と合っており、更新後に操作感も改善したため、これが主な原因だった可能性が高いと考えています。

LINEのデータを消したり、メモリ設定を変えたり、アニメーションをオフにしたりはしていません。常駐ヘルパーの修正でもないので、**このリポジトリの `install.ps1` を実行し直すだけでは、今回の対策にはなりません**。

私の環境では改善しましたが、すべてのフリーズが同じ原因とは限りません。長期間の安定動作を保証するものでもありません。

### データを残して更新する手順

以下は、すでにWSABuildsを使っている環境で、同じ構成の新しいリリースへ更新する場合の手順です。配布元に別の注意事項があれば、そちらを優先してください。

1. [WSABuildsのリリースページ](https://github.com/MustardChef/WSABuilds/releases)で更新内容を確認し、現在と同じCPU向け・Google Playあり／なしの構成を選びます。今回はWindows 11 x64向けのLTS 8、GAppsあり・Amazonなしを使いました。
2. ダウンロードしたファイルのSHA-256を配布元の値と比較し、別フォルダーに展開しておきます。
3. 右下のLINEアイコンから `Exit tray helper` を選び、常駐ヘルパーを終了します。LINEなどのAndroidアプリを閉じ、WSAの設定画面からWSAをシャットダウンします。設定画面も閉じます。
4. タスクマネージャーで `vmmemWSA` が終了したことを確認してから、バックアップを取ります。**アプリの画面を閉じただけでは、WSA本体は動いていることがあります。**
5. 現在のWSAインストールフォルダーを丸ごと、別のバックアップ用フォルダーへコピーします。さらに、上で案内した `LocalCache` フォルダーもコピーします。今回の環境では、その中の `userdata.2.vhdx` と `metadata.2.vhdx` を保存しました。十分な空き容量を確保し、コピーがエラーなく終わったことを確認してください。大切なトークは、LINE側で利用できるバックアップ・引き継ぎ方法も確認しておくと安心です。
6. 展開した新しいWSAの中身を、現在使っているWSAフォルダーへ上書きします。**バックアップ先ではなく、実際のインストール先です。** 今回はアンインストールやアプリデータの削除はしていません。
7. 上書きしたWSAフォルダー内の `Run.bat` を、配布元の説明に従って実行し、WSAを再登録します。
8. 登録が終わったら、普段のLINEショートカットから起動します。ログイン状態、トーク表示、スクロールやスタンプ表示を確認し、Playストア、通知、右下への常駐も確認してください。

今回の作業では、手順7の再登録を配布元にも記載されている次のコマンドで行いました。通常の `Run.bat` で登録できていれば、追加で実行する必要はありません。使う場合は、**更新したWSAフォルダーで**PowerShellを開いて実行します。

```powershell
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register .\AppxManifest.xml
```

上書き時に「ファイルが使用中」と出たら、そのまま続けないでください。WSAの設定画面や、同じWSAインストール先の `WSACrashUploader.exe` が残っていることがあります。対象を確認して終了してから、上書きと再登録をやり直します。無関係なプロセスまでまとめて強制終了する必要はありません。

更新後の確認では、LINEのログイン状態を保ったままトークとスタンプが表示され、実際に操作しても「固まる・重い」症状が改善しました。自動起動・常駐の設定ファイルは変更していません。通知や長期間の安定性まで、この確認だけで保証できるわけではありません。

**バックアップにはLINEのトークなどの個人情報が含まれます。GitHubや質問サイトへアップロードしないでください。** 復元が必要になった場合も、まずWSAを完全に止め、現時点のデータを別に保存してください。古いデータを上書きで戻すと、バックアップ後の変更を失うおそれがあります。

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

### トークを開くと固まる・スクロールが重い

上の[「LINEが固まる・操作が重い場合」](#lineが固まる操作が重い場合)を確認してください。2026年9月の私の環境では、WSABuildsをLTS 8へ更新して改善しました。LINEの再インストールやデータ削除をする前に、WSA本体のリリースを確認するのがおすすめです。

### PC起動後、何も表示されていないウィンドウが残る

以前のヘルパーでは、LINEを直接隠したときに、WSA側の空の枠だけがデスクトップに残ることがありました。上の「常駐ヘルパーを最新版にする」の手順で更新してください。

### シャットダウン時にアプリが終了を妨げていると表示される

以前のヘルパーには、LINEの起動待ちで最大45秒間、Windowsからの通知へ応答できなくなる処理がありました。最新版では待ち方を変え、Windowsの終了通知にも応答するようにしています。まずはヘルパーを更新してください。

それでも表示される場合は、その画面に出るアプリ名を確認してください。ヘルパー以外のアプリが原因の可能性もあるため、Windows全体の終了待ち時間を短くしたり、すべてのアプリを強制終了したりする設定は行っていません。

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
