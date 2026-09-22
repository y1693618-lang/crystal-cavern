#!/usr/bin/env python3
"""
docs/ フォルダの5ページを組み立てます。
GitHub Pages にそのまま置けるよう、1ファイルで完結させています
（外部の CSS もフォントも読み込みません。将来こわれる部分を作らないため）。

使い方：  python3 _build_docs.py
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
UPDATED_JA = "2026年9月22日"
UPDATED_EN = "22 September 2026"
EMAIL = "r451mjkl@icloud.com"          # ← 本当のアドレスが決まったらここだけ直す
APP_NAME_JA = "結晶洞窟"
APP_NAME_EN = "Crystal Cavern"

CSS = """
:root{
  --bg:#FFFFFF; --ink:#16130F; --dim:#4A443C; --line:#D7D0C6;
  --link:#0A5C55; --card:#F7F4EF;
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:#14110D; --ink:#F6F0E7; --dim:#C3B8A8; --line:#453B2E;
    --link:#7FE6D6; --card:#1E1912;
  }
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{
  margin:0; background:var(--bg); color:var(--ink);
  font-family:system-ui,-apple-system,"Hiragino Sans","Noto Sans JP",sans-serif;
  font-size:17px; line-height:1.85;
}
.wrap{max-width:44rem; margin:0 auto; padding:0 20px}
header{border-bottom:1px solid var(--line); padding:18px 0}
header .wrap{display:flex; gap:16px; align-items:center; flex-wrap:wrap}
.brand{font-weight:700; text-decoration:none; color:var(--ink)}
nav{margin-left:auto; display:flex; gap:16px; flex-wrap:wrap}
main{padding:36px 0 72px}
h1{font-size:1.75rem; line-height:1.4; margin:0 0 .4em}
h2{font-size:1.15rem; margin:2.2em 0 .5em; padding-top:.6em; border-top:1px solid var(--line)}
h3{font-size:1.02rem; margin:1.8em 0 .4em}
p,ul,ol{margin:0 0 1.1em}
ul,ol{padding-left:1.4em}
li{margin-bottom:.4em}
a{color:var(--link)}
.lede{color:var(--dim)}
.meta{color:var(--dim); font-size:.92rem}
.card{background:var(--card); border:1px solid var(--line); border-radius:10px; padding:18px 20px; margin:1.4em 0}
.card p:last-child{margin-bottom:0}
code{background:var(--card); border:1px solid var(--line); border-radius:4px; padding:.1em .35em; font-size:.92em}
footer{border-top:1px solid var(--line); padding:24px 0; color:var(--dim); font-size:.92rem}
.skip{position:absolute; left:-9999px}
.skip:focus{left:8px; top:8px; background:var(--bg); padding:10px; z-index:9; border:2px solid var(--link)}
"""


def page(lang, title, desc, nav, body, home_label):
    return f"""<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="color-scheme" content="light dark">
<style>{CSS}</style>
</head>
<body>
<a class="skip" href="#main">{'本文へ移動' if lang == 'ja' else 'Skip to content'}</a>
<header><div class="wrap">
  <a class="brand" href="{'index.html' if lang == 'ja' else '../index.html'}">{home_label}</a>
  <nav>{nav}</nav>
</div></header>
<main id="main"><div class="wrap">
{body}
</div></main>
<footer><div class="wrap">
  <p>{APP_NAME_JA} / {APP_NAME_EN}</p>
</div></footer>
</body>
</html>
"""


NAV_JA = ('<a href="privacy.html">プライバシーポリシー</a>'
          '<a href="support.html">サポート</a>'
          '<a href="en/privacy.html" hreflang="en" lang="en">English</a>')
NAV_EN = ('<a href="privacy.html">Privacy</a>'
          '<a href="support.html">Support</a>'
          '<a href="../privacy.html" hreflang="ja" lang="ja">日本語</a>')

# ---------------------------------------------------------------- index (ja)

INDEX_JA = f"""
<h1>{APP_NAME_JA}</h1>
<p class="lede">音を使わない、洞窟で結晶を掘るゲームです。このページは、iOS アプリ版のプライバシーポリシーとサポート窓口を置いています。</p>
<div class="card">
  <p><a href="privacy.html">プライバシーポリシー</a>　/　<a href="support.html">サポート・お問い合わせ</a></p>
  <p><a href="en/privacy.html" hreflang="en" lang="en">English version</a></p>
</div>
<h2>このゲームについて</h2>
<p>結晶洞窟は、結晶をタップして掘り、設備を増やして深い鉱脈へ進んでいくゲームです。<strong>音はいっさい使いません。</strong>作っている人間が聴覚障害のため、音で伝わる情報を最初から作らず、画面と手応えだけで遊べるようにしています。</p>
<ul>
  <li>文字の大きさを4段階から選べます（画面に描かれる数字も一緒に大きくなります）</li>
  <li>配色を5種類から選べます。うち2つは最大コントラストです</li>
  <li>色だけで意味を伝えている箇所はありません</li>
  <li>日本語・英語・中国語・韓国語・スペイン語に対応しています</li>
</ul>
"""

# ---------------------------------------------------------------- privacy (ja)

PRIVACY_JA = f"""
<h1>プライバシーポリシー（iOS アプリ版）</h1>
<p class="meta">最終更新日：{UPDATED_JA}</p>
<p class="lede">iOS アプリ「{APP_NAME_JA}」が、どんな情報をどう扱うかについての説明です。</p>

<h2>開発者が受け取る情報はありません</h2>
<p>このアプリには、会員登録もログインもありません。氏名・住所・電話番号・メールアドレスを入力していただく画面もありません。<strong>開発者があなたの個人情報を直接受け取ることはありません。</strong></p>
<p>例外は、下の「お問い合わせ」からメールをいただいた場合だけです。そのときは、メールに含まれる情報（アドレスと本文）を受け取ります。返信と不具合の調査にのみ使い、他へ渡すことはありません。</p>

<h2>ゲームの進行状況</h2>
<p>結晶の数、買った設備、言語や文字サイズの設定などは、<strong>端末の中にだけ保存されます。</strong>サーバーには送られません。開発者が見ることもできません。</p>
<p>消したいときは、ゲーム内のメニューにある「最初からやり直す」を使うか、アプリを削除してください。アプリを削除すると、保存された内容も一緒に消えます。</p>

<h2>広告について</h2>
<p>このアプリは、Google の <strong>AdMob</strong> を使ってリワード動画広告を表示します。</p>
<p>広告は任意です。「ボーナス」から自分で選んだときだけ再生されます。<strong>一度も見なくても、ゲームは最後まで遊べます。</strong></p>
<p>AdMob は、広告の表示・成果の計測・不正防止のために、端末の広告識別子（IDFA）やおおまかな利用状況などを収集することがあります。これは Google が行うもので、収集された情報が開発者に個人単位で渡ることはありません。</p>
<p>詳しくは <a href="https://policies.google.com/technologies/partner-sites?hl=ja" rel="noopener">Google のサービスを使用するサイトやアプリから収集した情報の Google による使用</a> をご覧ください。</p>

<h2>トラッキングの許可について</h2>
<p>初回の起動から少し経つと、まずアプリ自身の説明が出て、そのあとに iOS の「トラッキングを許可しますか」という確認が出ます。</p>
<p><strong>許可しなくても、ゲームの内容は何ひとつ変わりません。</strong>広告があなたの興味に合わせたものではなくなるだけです。あとから <code>設定 → プライバシーとセキュリティ → トラッキング</code> で変更できます。</p>
<p>EU・イギリスなど、同意の取得が必要な地域では、広告の同意確認画面が別に表示されます。</p>

<h2>通知について</h2>
<p>留守のあいだに貯まる分は8時間で上限に達します。そこで一度だけ「洞窟がいっぱいです」とお知らせします。通知は<strong>音を鳴らしません。</strong></p>
<p>許可は初回だけお尋ねし、断られた場合は二度と尋ねません。<code>設定 → 通知</code> からいつでも切れます。</p>

<h2>お子様の利用について</h2>
<p>このアプリは全年齢を対象としています。個人情報を集める機能がないため、お子様が遊んだ場合も情報が集まることはありません。</p>

<h2>本ポリシーの変更</h2>
<p>内容は必要に応じて変更することがあります。重要な変更があった場合は、このページに掲載します。</p>

<h2>お問い合わせ</h2>
<p>このポリシーについてのご質問は <a href="mailto:{EMAIL}">{EMAIL}</a> までお願いします。</p>
"""

# ---------------------------------------------------------------- support (ja)

SUPPORT_JA = f"""
<h1>サポート・お問い合わせ</h1>
<p class="lede">不具合の報告、ご質問、ご要望はこちらへお願いします。</p>

<div class="card">
  <p><strong>メール：</strong><a href="mailto:{EMAIL}">{EMAIL}</a></p>
  <p>個人で作っているため、お返事に数日いただくことがあります。</p>
</div>

<h2>不具合を知らせるとき</h2>
<p>ゲーム内の <strong>メニュー → 動作環境をコピー</strong> を押すと、調査に必要な情報がまとめてコピーされます。メールに貼り付けてお送りください。</p>
<p>コピーされるのは次のものです。<strong>氏名・メールアドレス・位置情報・端末の識別子は含まれません。</strong></p>
<ul>
  <li>ゲームのバージョン、選択中の言語・配色・文字サイズ</li>
  <li>画面の大きさ</li>
  <li>進行状況（深度、累計の採掘量など）</li>
  <li>お使いの端末とソフトウェアの種類</li>
</ul>

<h2>よくある質問</h2>

<h3>進行状況が消えました</h3>
<p>アプリを削除すると、保存された内容も一緒に消えます。機種変更の前に、ゲーム内の <strong>メニュー → セーブコード</strong> を控えておいてください。新しい端末でそのコードを入れれば、続きから遊べます。</p>

<h3>振動が返ってきません</h3>
<ul>
  <li><code>設定 → サウンドと触覚 → システムの触覚</code> が切れていないか確認してください</li>
  <li>低電力モードでは弱くなります</li>
  <li>iPad には触覚の機能がありません</li>
</ul>

<h3>広告が出ません</h3>
<p>在庫がないときや通信が不安定なときは出ないことがあります。少し時間をおいて試してください。広告は任意のものなので、出なくてもゲームは進みます。</p>

<h3>音が出ません</h3>
<p>仕様です。このゲームは最初から音をいっさい使っていません。作っている人間が聴覚障害のため、音で伝わる情報を作らず、画面と振動だけで遊べる形にしています。</p>
"""

# ---------------------------------------------------------------- privacy (en)

PRIVACY_EN = f"""
<h1>Privacy Policy (iOS app)</h1>
<p class="meta">Last updated: {UPDATED_EN}</p>
<p class="lede">How the iOS app “{APP_NAME_EN}” handles information.</p>

<h2>The developer receives nothing</h2>
<p>There is no account and no sign-in. Nothing in the app asks for your name, address, phone number or email. <strong>The developer never receives your personal information.</strong></p>
<p>The one exception is if you write to the support address below. In that case the email itself — your address and what you wrote — is received, used only to reply and to investigate the problem, and passed to no one.</p>

<h2>Game progress</h2>
<p>Your crystals, buildings, language and text size are stored <strong>on your device only.</strong> Nothing is sent to a server, and the developer cannot see it.</p>
<p>To erase it, use <strong>Menu → Start over</strong> inside the game, or delete the app; deleting the app deletes the saved data with it.</p>

<h2>Advertising</h2>
<p>This app shows rewarded video adverts through Google <strong>AdMob</strong>.</p>
<p>Adverts are optional. One plays only when you choose a bonus yourself. <strong>The game can be finished without watching a single one.</strong></p>
<p>To serve adverts, measure them and prevent fraud, AdMob may collect your device's advertising identifier (IDFA) and coarse usage data. This is done by Google; the developer never receives it at an individual level.</p>
<p>See <a href="https://policies.google.com/technologies/partner-sites" rel="noopener">How Google uses information from sites or apps that use our services</a>.</p>

<h2>Tracking permission</h2>
<p>Shortly after first launch the app explains what tracking is for, and then iOS asks whether you allow it.</p>
<p><strong>Declining changes nothing about the game.</strong> It only makes the adverts less relevant. You can change your mind later under <code>Settings → Privacy &amp; Security → Tracking</code>.</p>
<p>In the EU, the UK and other regions where consent is required, a separate advertising consent screen is shown.</p>

<h2>Notifications</h2>
<p>What accumulates while you are away reaches its limit after eight hours. The app tells you once, at that point. The notification is <strong>silent</strong>.</p>
<p>Permission is requested once only, and never again if you decline. You can turn it off at any time under <code>Settings → Notifications</code>.</p>

<h2>Children</h2>
<p>The app is suitable for all ages. Because it has no way of collecting personal information, nothing is collected when a child plays it.</p>

<h2>Changes to this policy</h2>
<p>This policy may change. Any significant change will be posted on this page.</p>

<h2>Contact</h2>
<p>Questions about this policy: <a href="mailto:{EMAIL}">{EMAIL}</a></p>
"""

# ---------------------------------------------------------------- support (en)

SUPPORT_EN = f"""
<h1>Support</h1>
<p class="lede">Bug reports, questions and requests are all welcome here.</p>

<div class="card">
  <p><strong>Email:</strong> <a href="mailto:{EMAIL}">{EMAIL}</a></p>
  <p>This is made by one person, so a reply may take a few days.</p>
</div>

<h2>Reporting a problem</h2>
<p>In the game, <strong>Menu → Copy diagnostics</strong> gathers everything needed to investigate. Paste it into your email.</p>
<p>It contains the following, and <strong>no name, email address, location or device identifier</strong>:</p>
<ul>
  <li>Game version, and the language, colour scheme and text size in use</li>
  <li>Screen size</li>
  <li>Progress (depth, total mined, and so on)</li>
  <li>The kind of device and software you are using</li>
</ul>

<h2>Common questions</h2>

<h3>My progress disappeared</h3>
<p>Deleting the app deletes the saved data with it. Before changing device, write down your code from <strong>Menu → Save code</strong>; entering it on the new device restores everything.</p>

<h3>I feel no vibration</h3>
<ul>
  <li>Check that <code>Settings → Sounds &amp; Haptics → System Haptics</code> is on</li>
  <li>Low Power Mode weakens it</li>
  <li>iPad has no haptic engine</li>
</ul>

<h3>No advert appears</h3>
<p>Adverts sometimes have no inventory, or the connection is poor. Try again in a while. They are optional, so the game continues either way.</p>

<h3>There is no sound</h3>
<p>That is intended. This game uses no audio at all. Its developer is deaf, so nothing is conveyed by sound — the screen and the haptics carry everything.</p>
"""


def write(path, text):
    full = os.path.join(HERE, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote", path)


write("index.html", page("ja", f"{APP_NAME_JA} — iOS アプリ版",
                         "音を使わない結晶掘りゲーム、結晶洞窟 iOS アプリ版のプライバシーポリシーとサポート窓口です。",
                         NAV_JA, INDEX_JA, APP_NAME_JA))
write("privacy.html", page("ja", f"プライバシーポリシー — {APP_NAME_JA}",
                           "iOS アプリ版 結晶洞窟における情報の取り扱い。保存先、広告、トラッキング許可、通知について説明します。",
                           NAV_JA, PRIVACY_JA, APP_NAME_JA))
write("support.html", page("ja", f"サポート — {APP_NAME_JA}",
                           "結晶洞窟 iOS アプリ版のお問い合わせ窓口と、よくある質問です。",
                           NAV_JA, SUPPORT_JA, APP_NAME_JA))
write("en/privacy.html", page("en", f"Privacy Policy — {APP_NAME_EN}",
                              "How the Crystal Cavern iOS app handles information: storage, advertising, tracking permission and notifications.",
                              NAV_EN, PRIVACY_EN, APP_NAME_EN))
write("en/support.html", page("en", f"Support — {APP_NAME_EN}",
                              "Support contact and common questions for the Crystal Cavern iOS app.",
                              NAV_EN, SUPPORT_EN, APP_NAME_EN))
