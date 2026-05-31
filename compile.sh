#!/bin/bash
set -euo pipefail

ARG1="${1:-}"
ARG2="${2:-}"


# ==============================================================================
# 1. Docker が起動しているかチェックする関数
# ==============================================================================
is_docker_available() {
  # docker info コマンドが正常に終了するかどうかで判定（エラー出力を非表示に）
  docker info > /dev/null 2>&1
}

# ==============================================================================
# 2. メイン処理の分岐
# ==============================================================================
if is_docker_available; then
    echo "🐳 Docker 環境を検知しました。コンテナで実行します。"

    CONTAINER_ARGS=()

    for arg in "$@"; do
        if [ -e "${arg}" ]; then
            # A. 引数がファイルまたはディレクトリとして実在する場合（科目モードのパスなど）
            # 冒頭の「/」を削って、コンテナのマウント先である「/data/」を頭に付与
            local clean_path="${arg#+/}" # 先頭のスラッシュを安全に削除
            CONTAINER_ARGS+=("/data/${clean_path}")
        else
            # B. 実在しない場合（pdf, all, clear などの拡張子・キーワード）
            # そのままの値で引き継ぐ
            CONTAINER_ARGS+=("${arg}")
        fi
    done
    # 3. Docker の実行
    docker run --rm \
        -v "${PWD}":/data \
        -w /data \
        my-pandoc \
        /data/_pandoc/compile.sh "${CONTAINER_ARGS[@]}"

else
    echo "💻 Docker が起動していないか、インストールされていません。ローカル環境で実行します。"
    bash _pandoc/compile.sh "$@"
fi