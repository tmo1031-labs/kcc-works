# kcc-works
慶應通信のレポート・卒論をMarkdownで書く環境

Markdownファイル（`.md` または `.txt` ）を、
Pandoc と LaTeX (LuaLaTeX/uplatex) を使用して、
綺麗な日本語の PDF や Word（`.docx`）に自動変換する環境です。

## 📂 ディレクトリ構成

```text
./                         # ルートディレクトリ
├── _pandoc/               
│   ├── compile.sh         # 変換を実行するコアスクリプト
│   └── templates/         # ここに変換用テンプレートを置く
│       ├── default.latex  # LaTeXファイル変換用テンプレート
│       ├── default.docx   # WORDファイル変換用テンプレート
│       ├── harvard.csl    # WORDファイル変換時の文献表スタイル(ハーバード式)
│       ├── mla.csl        # WORDファイル変換時の文献表スタイル(MLA式)
│       ├── mybibstyle.sty # 文献表のスタイルファイル
│       └── MyDefaults.yaml   # 変換スクリプトのオプションを指定する設定ファイル
├── subjects/               # 科目レポート等の置き場
│   ├── sample/             # サンプルレポート
│   ├── subject_A/          # [科目毎にディレクトリを置くと便利]
│   │   ├── report_1st/     # [レポート提出毎にディレクトリを置くと便利]
│   │   └── report_2nd/     # [例:再提出レポートの場合]
│   └── templates/          # [変換用テンプレートを科目と卒論で別ける場合の置き場]
├─ thesis/                  # 卒業論文の置き場
│   ├── 00.core/            # 卒業論文のコアディレクトリ
│   │   └── thesis.txt      # 卒業論文の本体
│   ├── 01.intro/           # [章単位で分割して置いてもいい]
│   ├── 99.bib/             # 文献表のBibTeX置き場
│   └── templates/          # [変換用テンプレートを科目と卒論で別ける場合の置き場]
├── Dockerfile              # 仮想環境構築の設定ファイル
└── compile.sh              # 仮想環境での変換実行スクリプト
```

## 🛠️ 事前準備

### リポジトリの複製

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
```bash
git remote set-url origin 【作ったPrivateリポジトリのURL】

例: git remote set-url origin https://github.com/★my-account★/my-works.git
```

4. 個人アカウントのリモートにローカルの内容を反映する。
   1. ターミナルに以下のコマンドを打ち、実行する。

```bash
git push -u origin main
```

### 実行環境作成

以下のいずれかの実行環境を作成してください。

1. ローカルPC での実行環境
2. Docker(仮想環境) での実行環境
3. Github Actions での実行環境

#### ローカルPCでの実行環境作成 (Mac の場合)

1. Homebrewの確認・インストール
ターミナルで brew -v を実行し、コマンドが見つからない場合は
以下のコマンドでHomebrewをインストールしてください。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. pandoc(とpandoc-crossref) のインストール

```bash
brew install pandoc pandoc-crossref
```
    
3. 正常にインストールされ、パスが通っているかを確認します。
```bash
pandoc --version
pandoc-crossref --version
```

4. LaTeX 環境のインストール【注意:激重】

```bash
brew install --cask mactex-no-gui
```
※インストール後、パスを反映させるためにターミナルの再起動が必要です。
(または `eval "$(/usr/libexec/path_helper)"`)

#### Docker(仮想環境) での実行環境

1. Docker のインストール
お使いの環境に合わせて Docker Desktop などをインストールし、バックグラウンドで起動しておいてください。

2. スクリプトの実行権限の付与（初回のみ）
ターミナルでリポジトリのルートに移動し、以下のコマンドを実行してスクリプトに実行権限を与えます。

```bash
chmod +x compile.sh combine-pdf.sh _pandoc/compile.sh _pandoc/combine-pdf.sh
```

3. Docker イメージのビルド（初回のみ）
設計図から環境の「型」を作成します。最初の1回だけ数分かかります。

```bash
docker build -t my-pandoc .
```

#### Github Actions での実行環境

1. 卒論のバージョン管理用に mainブランチに v0.1 などのタグを打っておくと便利です

## 🚀 使い方

コンパイルはすべてルートディレクトリで ./compile.sh を実行するだけです。
用途に合わせて2つのモードが自動で判定されます。

1. 科目レポート等の単体コンパイル (Single モード)
特定の Markdown 形式ファイルを指定してPDFに変換します。

```bash
# 基本形（デフォルトで PDF が出力されます）
./compile.sh subjects/sample/sample.txt

# Word (.docx) 形式で出力したい場合
./compile.sh subjects/sample/sample.txt docx

# 卒論構想 (is-prospectus オブションを true にすると、卒論構想をPDFにできます)
./compile.sh supervision/01.20XX_A/prospectus.txt 
```

2. 卒業論文等の結合コンパイル (Thesis モード)
引数を何も指定しない場合、自動的に thesis/00.core/thesis.txt の構成リストを読み込み、
章ごとに分かれた Markdown ファイルを1つの大きな PDF に結合して出力します。

```bash
# 論文全体を結合して PDF 化
./compile.sh

# 結合した LaTeX（.tex）ソースコードのみを出力したい場合
./compile.sh tex
```

3. PDF同士の結合
卒論のPDFと、卒論構想のPDFがあれば、2つを結合して1つのPDFにまとめられます。

```bash
# 卒論構想と卒論本文の結合
./combine-pdf.sh supervision/01.20XX_A/prospectus.pdf 
```

## 💡 トラブルシューティング

