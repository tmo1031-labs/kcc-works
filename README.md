# kcc-works
慶應通信のレポート・卒論をMarkdownで書く環境

## 使い方

### 初期設定

1. 自分のGithub個人アカウントに「完全に空のPrivateリポジトリ」を作る。
   1. 個人アカウントで New repository を作成します。
    * Repository name: 好きな名前（組織のリポジトリと同じでも違ってもOKです）。
    * 公開範囲: 必ず 「Private」 を選択します。
    * 注意： README、.gitignore、Licenseの追加チェックは**すべて外して、完全に空っぽ（Empty）**の状態で作成してください。
   2. 作ったPrivateリポジトリのURLをコピーして控えておく。
   例: https://github.com/★my-account★/my-works.git
2. このPublicリポジトリをローカルに通常クローンする。
   1. VSCode で新規ウインドウを開き、「ソース管理」から「リポジトリをクローンする」を選択。
   2. 上部のバーの「Githubから複製」を選択、"tmo1031-labs/kcc-works"を検索して選択。
   3. ローカルの保存先のフォルダを選択し、「リポジトリの宛先として選択」を押す。
   4. ローカルのリポジトリができる。
3. リモートのプッシュ先を変える。
   1. VSCodeでローカルリポジトリを開き、ターミナルウィンドウを表示させる。
   (メニューバー -> 表示 -> ターミナル を押す)
   2. ターミナルに以下のコマンドを打ち、実行する。
   git remote set-url origin 【作ったPrivateリポジトリのURL】
   例: git remote set-url origin https://github.com/★my-account★/my-works.git
4. 個人アカウントのリモートにローカルの内容を反映する。
   1. ターミナルに以下のコマンドを打ち、実行する。
   git push -u origin main