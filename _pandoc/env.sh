#!/bin/bash

# ==============================================================================
# 共通のシェルオプション（シェル全体を安全にする）
# ==============================================================================
set -euo pipefail

# ==============================================================================
# ディレクトリパスの定義
# ==============================================================================
# env.sh 自体の位置を基準にルートを特定
readonly ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${ENV_DIR}/.." && pwd)"

readonly SUBJECTS_DIR="${ROOT_DIR}/subjects"
readonly THESIS_DIR="${ROOT_DIR}/thesis"

# ==============================================================================
# コンパイル時の環境変数
# ==============================================================================
readonly DIR_TEMPLATES="templates"
readonly DIR_CORE="00.core"

# 固定ファイル名
readonly FILE_THESIS_CONF="thesis.txt"
readonly FILE_THESIS_OUTPUT="thesis"
readonly FILE_DEFAULTS_YAML="MyDefaults.yaml"
readonly FILE_TEMPLATE_DOCX="default.docx"
readonly FILE_TEMPLATE_LATEX="default.latex"

# メタデータ・パース用正規表現 / 判定文字列
readonly PATTERN_IS_THESIS="is-thesis:[[:space:]]*true"
readonly PATTERN_VERSION_MARK='^version:'
readonly EXT_DEFAULT_TARGET="pdf"

# クリーンアップ対象の拡張子
readonly CLEAR_EXTS=(aux bbl bcf blg ent log out run.xml dvi toc lof lot fls fdb_latexmk)

# ==============================================================================
# 共通のユーティリティ関数（必要に応じて）
# ==============================================================================
log_info() {
    echo "Info: $*"
}

log_error() {
    echo "Error: $*" >&2
}