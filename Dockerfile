FROM paperist/alpine-texlive-ja:latest

# 1. 必要なツールと、基本となる biblatex、そして「biber」コマンドそのものをインストール
RUN apk update && apk add --no-cache \
    pandoc \
    curl \
    tar \
    xz \
    gcompat \
    texlive-bibtexextra \
    biber

# 2. tlmgrで apa スタイルをピンポイントインストール
RUN tlmgr init-usertree || true; \
    tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet; \
    tlmgr install biblatex-apa

# 3. pandoc-crossref のインストール
RUN set -eux; \
    LATEST_URL=$(curl -s "https://api.github.com/repos/lierdakil/pandoc-crossref/releases/latest" | grep "browser_download_url.*Linux-X64.tar.xz" | cut -d '"' -f 4); \
    curl -L "${LATEST_URL}" -o pandoc-crossref-Linux.tar.xz; \
    tar -xJf pandoc-crossref-Linux.tar.xz \
    && mv pandoc-crossref /usr/local/bin/ \
    && chmod +x /usr/local/bin/pandoc-crossref \
    && rm pandoc-crossref-Linux.tar.xz