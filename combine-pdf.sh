#!/bin/bash
set -euo pipefail

ARG1="${1:-}"

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
    
    # 💡 シェル標準の機能で先頭のスラッシュを削除（sed不要で高速・安全）
    CLEAN_PATH="${ARG1#/}"
    
    if [ -n "${CLEAN_PATH}" ]; then
        CONTAINER_ARGS+=("/data/${CLEAN_PATH}")
    fi

    # 💡 $(pwd) を使い、配列展開をシンプルに修正
    docker run --rm \
        -v "$(pwd)":/data \
        -w /data \
        my-pandoc \
        /data/_pandoc/combine-pdf.sh "${CONTAINER_ARGS[@]}"

else
    echo "💻 Docker が起動していないか、インストールされていません。ローカル環境で実行します。"
    
    # ローカルで実行する場合の引数をそのまま構築
    LOCAL_ARGS=()
    if [ -n "${ARG1}" ]; then
        LOCAL_ARGS+=("${ARG1}")
    fi

    # 💡 ローカルの bash で、そのまま combine-pdf.sh を実行する
    bash _pandoc/combine-pdf.sh "${LOCAL_ARGS[@]}"
fi