# 結晶洞窟 — iOS アプリ版（Windows から作る手順）

Mac も Xcode も使いません。

ファイルを GitHub に置き、Codemagic という無料のサービスが
Mac を借りてビルドしてくれます。あなたの作業はブラウザだけで終わります。

---

## ⚠ 先に読んでください

**この Swift のコードは、私の環境でコンパイルできていません。**
Mac も iOS の SDK も無いためです。

**一度でビルドが通らない可能性は十分にあります。**
エラーが出たら、そのメッセージをそのまま貼ってください。直します。

最後のほうに「よくあるエラー」をまとめました。

---

## 用意するもの

| いるもの | 持っている？ |
|---|---|
| GitHub アカウント | ✅ |
| Apple Developer アカウント（年 $99） | ✅ |
| Codemagic アカウント | これから作る（無料。GitHub でログインできます） |
| AdMob アカウント | これから作る（無料） |
| 実機の iPhone | 触覚の確認に必要です |

---

## 1. GitHub にファイルを置く

1. GitHub で新しいリポジトリを作ります
   - 名前：`crystal-cavern-ios`（なんでも構いません）
   - **Public にしてください。** 次の手順で使う GitHub Pages が、
     無料プランでは Public のリポジトリでしか動かないためです
2. この zip の中身を、そのままアップロードします

置いたあとの形はこうなります。

```
crystal-cavern-ios/
  README.md              この文書
  project.yml            Xcode プロジェクトの設計図   ← 1か所だけ直す
  codemagic.yaml         ビルドの手順書               ← 2か所だけ直す
  .gitignore
  CrystalCavern/
    *.swift              アプリのプログラム
    Info.plist           アプリの設定                 ← 1か所だけ直す
    PrivacyInfo.xcprivacy  プライバシーマニフェスト（必須）
    Assets.xcassets/     アプリアイコン、起動画面の色
    www/game.html        ゲーム本体
  docs/                  GitHub Pages に出すページ
    index.html
    privacy.html         プライバシーポリシー（日本語）
    support.html         サポート（日本語）
    en/privacy.html      英語
    en/support.html      英語
```

> **なぜ `.xcodeproj` が無いのか**
> Xcode のプロジェクトファイルは、ふつう Xcode で作ります。Windows では作れません。
> そこで代わりに `project.yml` という短い設計図を置き、
> ビルドのたびに Mac 側の **XcodeGen** がそこから組み立てます。
> あなたが Xcode を持つ必要はありません。

---

## 2. プライバシーポリシーをネット上に出す

App Store には「誰でも開ける URL」を登録する必要があります。
`docs/` フォルダをそのまま公開すれば済みます。

1. GitHub のリポジトリ → **Settings** → 左の **Pages**
2. Source を **Deploy from a branch** に
3. Branch を **main**、フォルダを **/docs** にして **Save**
4. 1〜2分待つと、上に URL が出ます

出てくる URL はこうなります。

```
https://<あなたのユーザー名>.github.io/crystal-cavern-ios/
```

App Store Connect に登録するのはこの2つです。

| 項目 | URL |
|---|---|
| Privacy Policy URL | `.../crystal-cavern-ios/privacy.html` |
| Support URL | `.../crystal-cavern-ios/support.html` |

**必ずブラウザで開いて、表示されることを確かめてください。**
開けない URL を登録すると、審査でそこだけを理由に止められます。

---

## 3. AdMob で自分の ID をもらう

1. [AdMob](https://admob.google.com/) にログイン
2. **アプリ → アプリを追加** → iOS
   - 「App Store に公開済みですか？」は **いいえ** を選べます。
     公開前でも登録できます
3. できたアプリの **アプリ ID** を控えます（`ca-app-pub-〜〜~〜〜`）
4. そのアプリの中で **広告ユニット → リワード** を作ります
5. できた **広告ユニット ID** を控えます（`ca-app-pub-〜〜/〜〜`）

`~`（チルダ）と `/`（スラッシュ）で種類が違います。見分ける目印です。

### 差し替えるのは公開の直前です

**開発中はテスト用の ID のままにしてください。** 理由は2つあります。

- 自分の広告を自分でクリックすると **AdMob の規約違反**になります。
  アカウントが止まると、収益が全部消えます
- テスト ID なら、在庫の有無に関係なく必ず広告が出ます。
  動作の確認がしやすくなります

| 場所 | いまの値（Google のテスト用） |
|---|---|
| `CrystalCavern/Info.plist` の `GADApplicationIdentifier` | `ca-app-pub-3940256099942544~1458002511` |
| `CrystalCavern/AdsManager.swift` の `adUnitID` | `ca-app-pub-3940256099942544/1712485313` |

TestFlight で手応えを確かめ終わって、**App Store に出す直前**に、
この2つを自分の ID に差し替えます。

---

## 4. App Store Connect にアプリの枠を作る

1. [App Store Connect](https://appstoreconnect.apple.com/) → **マイ App** → **＋**
2. 入力します
   - プラットフォーム：iOS
   - 名前：結晶洞窟
   - 言語：日本語
   - **バンドル ID**：ここで新しく作ります（例 `com.あなたの名前.crystalcavern`）
   - SKU：なんでも構いません（例 `crystalcavern`）

3. 決めたバンドル ID を、**2つのファイル**に書きます

| ファイル | 場所 |
|---|---|
| `project.yml` | `PRODUCT_BUNDLE_IDENTIFIER:` の行 |
| `codemagic.yaml` | `bundle_identifier:` の行 |

**この2つが違っているとビルドが失敗します。** よくある詰まりどころです。

---

## 5. App Store Connect の API キーを作る

Codemagic が、あなたの代わりに署名して TestFlight に送るための鍵です。
Apple ID とパスワードでは代われません。

1. App Store Connect → **ユーザーとアクセス** → **統合** → **App Store Connect API**
2. **＋** でキーを作ります
   - 名前：`Codemagic`
   - アクセス：**App Manager**
3. **.p8 ファイルをダウンロードします。ダウンロードは一度きりです。**
   消すと作り直しになります
4. 同じ画面の **Issuer ID** と、キーの **Key ID** も控えます

---

## 6. Codemagic をつなぐ

1. [codemagic.io](https://codemagic.io/) に GitHub アカウントでログイン
2. リポジトリ `crystal-cavern-ios` を選びます
3. **Teams（または App の設定）→ Integrations → App Store Connect**
   - 名前：`CrystalCavernKey`
   - Issuer ID / Key ID / .p8 ファイルを入れます

4. `codemagic.yaml` の `app_store_connect:` を、
   ここで付けた名前（`CrystalCavernKey`）に合わせます

5. `codemagic.yaml` の `recipients:` を自分のメールアドレスに直します

6. **Start new build** を押します

うまくいけば 10〜20 分で TestFlight に届きます。

> Codemagic の無料枠には、1か月あたりのビルド時間の上限があります。
> 何度も失敗すると減っていくので、**直すときは一度にまとめて直す**のが得です。

---

## 7. 実機で確かめる

TestFlight アプリを iPhone に入れて、自分のビルドを入れます。
**シミュレータでは触覚が出ません。実機で確かめてください。**

- [ ] 起動して、ゲームが表示される
- [ ] **結晶をタップすると、指に軽い振動が返る** ← これが最重要
- [ ] 設備を買うと、少し強い振動
- [ ] 機内モードにしても、ゲームが普通に動く
- [ ] 起動2秒後に、広告についての説明が出る
- [ ] 「続ける」を押すと、システムの追跡許可の画面が出る
- [ ] 「ボーナス」タブが出ている（アプリ内では自動で有効になります）
- [ ] ボーナスを押すと、テスト広告が全画面で流れる
- [ ] 最後まで見ると報酬が入る／途中で閉じると入らない
- [ ] ホーム画面に戻して8時間置くと、通知が一度だけ届く
- [ ] お問い合わせのリンクを押すと、Safari が開く（アプリの中では開かない）

---

## 8. App Store に出す

ここで初めて、**AdMob の ID を本物に差し替えます**（手順3）。
GitHub に上げ直すと、Codemagic が自動でビルドし直します。

### 審査への説明文（Review Notes）

そのまま貼れる文面です。**4.2 で落とされないために、ここは必ず書いてください。**

```
This app is a native iOS game. The gameplay is bundled in the app and runs
entirely offline — no network connection is required to play.

The developer is deaf. The game deliberately contains no audio of any kind,
and this iOS version replaces that missing channel with the Taptic Engine:
tapping the crystal, buying a building, catching an event orb, reaching a new
seam and rebirthing each produce a distinct haptic pattern. This is the main
reason the app exists and is not available in the browser version.

The app also uses local notifications to tell the player when their offline
earnings have reached their cap, and AdMob rewarded video, which is entirely
optional — the game can be completed without watching a single advert.

Accessibility: four text sizes that scale every element including canvas-drawn
numbers, five colour schemes (two at maximum contrast), no information conveyed
by colour alone, and full keyboard support. Available in five languages.
```

### 登録する項目

| 項目 | 内容 |
|---|---|
| Support URL | 手順2 の `support.html` |
| Privacy Policy URL | 手順2 の `privacy.html` |
| Age Rating | 4+（暴力なし、課金なし、UGC なし） |
| App Privacy | **Identifiers → Device ID** を「**追跡に使用する**」で申告。それ以外は無し |
| EULA | **Apple の標準 EULA のままで問題ありません** |

**App Privacy の申告を忘れると審査で止まります。**
AdMob を入れている以上、「何も集めていません」では通りません。

---

## よくあるエラー

### `No such module 'GoogleMobileAds'`

パッケージの取得に失敗しています。Codemagic のログで
`swift-package-manager-google-mobile-ads` の行を探してください。
一時的な失敗なら、もう一度ビルドすれば直ります。

### `Cannot find 'MobileAds' in scope`

SDK のバージョン差です。**v11 以前は名前の先頭に `GAD` が付きます。**
`project.yml` では v13.10.0 を指定しているので出ないはずですが、
念のため対応表を置きます。

| このコードの書き方（v12 以降） | v11 以前の書き方 |
|---|---|
| `MobileAds.shared.start()` | `GADMobileAds.sharedInstance().start()` |
| `RewardedAd` | `GADRewardedAd` |
| `Request()` | `GADRequest()` |
| `FullScreenContentDelegate` | `GADFullScreenContentDelegate` |
| `FullScreenPresentingAd` | `GADFullScreenPresentingAd` |

### `ConsentInformation` / `ConsentForm` が見つからない

`ConsentManager.swift` だけで起きるエラーです。
同意確認の部品も、バージョン3で名前が変わりました。

| このコードの書き方（v3 以降） | v2 以前の書き方 |
|---|---|
| `ConsentInformation.shared` | `UMPConsentInformation.sharedInstance` |
| `ConsentForm` | `UMPConsentForm` |
| `RequestParameters()` | `UMPRequestParameters()` |

**急ぐときは、次の2つを消してもビルドは通ります。**

1. `CrystalCavern/ConsentManager.swift` を削除
2. `CrystalCavernApp.swift` の `await ConsentManager.shared.gather()` の行を削除

ただし、これは **EU・イギリスの人に広告を出すために Google が必須にしている
同意確認**です。App Store に出すまでには戻してください。

### `Provisioning profile ... doesn't match`

`project.yml` と `codemagic.yaml` のバンドル ID が食い違っています（手順4）。

### 起動した瞬間に落ちる

`Info.plist` の `GADApplicationIdentifier` が空か、形が違っています。
`~`（チルダ）入りのアプリ ID であることを確かめてください。

### 画面が真っ黒のまま

`CrystalCavern/www/game.html` が入っていないか、置き場所が違います。
`project.yml` の `type: folder` の指定が、Xcode でいう「青いフォルダ」にあたります。

### 触覚が返ってこない

- シミュレータでは出ません。実機で試してください
- `設定 → サウンドと触覚 → システムの触覚` が切れていませんか
- 低電力モードでは弱くなります
- iPad には触覚の機能がありません

---

## ゲームを更新したとき

`CrystalCavern/www/game.html` を新しいものに差し替えて、GitHub に上げるだけです。
Swift 側を触る必要はありません。

ウェブ版とアプリ版で **同じ `game.html` を使えます。**
ゲーム側が、自分がアプリの中にいるかどうかを自動で判断します。
ブラウザで開けば触覚も通知も広告も呼ばれず、アプリで開けば全部つながります。

---

## 差し替える場所のまとめ

全部で **6か所** です。

| いつ | ファイル | 場所 |
|---|---|---|
| 最初 | `project.yml` | `PRODUCT_BUNDLE_IDENTIFIER` |
| 最初 | `codemagic.yaml` | `bundle_identifier` |
| 最初 | `codemagic.yaml` | `app_store_connect`（Codemagic で付けた名前） |
| 最初 | `codemagic.yaml` | `recipients`（自分のメールアドレス） |
| 公開の直前 | `CrystalCavern/Info.plist` | `GADApplicationIdentifier` |
| 公開の直前 | `CrystalCavern/AdsManager.swift` | `adUnitID` |

そのほか、`docs/_build_docs.py` の `EMAIL` を本当のアドレスに変えて
`python3 _build_docs.py` を実行すると、5ページのメールアドレスが一度に直ります。
（Windows に Python が無ければ、5つの HTML を手で直しても同じです）
