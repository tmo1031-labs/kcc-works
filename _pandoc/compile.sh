#!/bin/bash
set -euo pipefail # 💡 安全のための厳格モード（エラーで即停止、未定義変数禁止）
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

# ==============================================================================
# 1. 引数の解析（位置不問・複数ファイル対応）
# ==============================================================================
EXT_ARG="${EXT_DEFAULT_TARGET}" 
declare -a TARGET_FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    pdf|docx|tex|all|tex2pdf|clear)
      EXT_ARG="$1"
      ;;
    *)
      if [ -n "$1" ]; then
        TARGET_FILES+=("$1")
      fi
      ;;
  esac
  shift
done

readonly OUTPUT_EXT="${EXT_ARG}"

# ==============================================================================
# 2. ヘルパー関数群（テンプレート解決 & モード事前判定）
# ==============================================================================
resolve_template() {
  local filename="$1"
  local template_dir="$2"
  if [ -f "${template_dir}/${filename}" ]; then
    echo "${template_dir}/${filename}"
  else
    echo "${ENV_DIR}/${DIR_TEMPLATES}/${filename}"
  fi
}

# 💡 渡されたファイルが thesis モードの対象（is-thesis: true）か判定する関数
check_is_thesis_file() {
  local target_file="$1"
  
  if [ ! -f "${target_file}" ]; then
    return 1 # ファイルが存在しない場合は判定を抜ける
  fi

  # 1. 環境変数チェック
  if [ "${IS_THESIS:-}" = "true" ]; then
    return 0
  fi

  # 2. ファイル単体のフロントマターをチェック
  if [ -s "${target_file}" ] && grep -q "${PATTERN_IS_THESIS}" "${target_file}" 2>/dev/null; then
    return 0
  fi

  # 3. 該当フォルダ内または共通の MyDefaults.yaml をチェック
  local target_dir
  target_dir="$(cd "$(dirname "${target_file}")" && pwd)"
  local yaml_path="$(resolve_template "${FILE_DEFAULTS_YAML}" "${target_dir}/${DIR_TEMPLATES}")"
  
  if [ -s "${yaml_path}" ] && grep -q "${PATTERN_IS_THESIS}" "${yaml_path}" 2>/dev/null; then
    return 0
  fi

  return 1 # いずれにも合致しなければ subject モードとみなす
}

# ==============================================================================
# 3. 共通コンパイルパイプライン関数
# ==============================================================================
compile_pipeline() {
  local mode="$1"
  local target_arg="$2"
  
  local template_dir=""
  local work_dir=""
  local base_filename=""
  local top_division_opt=""
  local conf_for_version=""
  declare -a md_files=()
  local thesis_dir="${THESIS_DIR}"
  
  # ----------------------------------------------------------------------------
  # 3.1 モード固有のコンテキスト初期化
  # ----------------------------------------------------------------------------
  if [ "${mode}" = "subject" ]; then
    echo "📄 Mode: [Subject File] - Start..."
    template_dir="${SUBJECTS_DIR}/${DIR_TEMPLATES}"
    
    if [ ! -f "${target_arg}" ]; then
      echo "❌ Error: ファイルが見つかりません: ${target_arg}" >&2
      return 1
    fi
    local target_src
    target_src="$(cd "$(dirname "${target_arg}")" && pwd)/${target_arg##*/}"
    work_dir="$(dirname "${target_src}")"
    base_filename="$(basename "${target_src}" | cut -d. -f1)"
    
    top_division_opt=""
    conf_for_version="${target_src}"
    md_files=("${target_src}")
    
    echo "=================================================="
    echo "📄 Mode: [Subject File] - Compiling ${base_filename}"
    echo "=================================================="
  else
    echo "🎓 Mode: [Thesis Assembly] - Start..."
    mode="thesis"
    top_division_opt="--top-level-division=chapter"

    # 引数ファイルが存在する場合、そのファイルの位置を基準にベースパスを動的解決
    if [ -n "${target_arg}" ] && [ -f "${target_arg}" ]; then
      local target_abs_src
      target_abs_src="$(cd "$(dirname "${target_arg}")" && pwd)/${target_arg##*/}"
      
      local relative_part="${target_abs_src#$ROOT_DIR}"
      local first_level
      first_level=$(echo "$relative_part" | cut -d'/' -f1-2)
      thesis_dir="${ROOT_DIR}${first_level}"
    fi

    template_dir="${thesis_dir}/${DIR_TEMPLATES}"

    # 論文全体の結合資材が置かれているコアディレクトリを確定
    local core_dir="${thesis_dir}/${DIR_CORE}"
    work_dir="${core_dir}"
    
    # 💡 1. 成果物のベースファイル名（出力名）を分岐
    if [ -n "${target_arg}" ] && [ -f "${target_arg}" ]; then
      # 引数がある場合：その引数ファイルの名前（拡張子なし）を出力名にする
      base_filename="$(basename "${target_arg}" | cut -d. -f1)"
    else
      # 引数がない場合：固定の出力名（thesis）にする
      base_filename="${FILE_THESIS_OUTPUT}"
    fi

    # 💡 2. 設定ファイル（thesis.txt）の存在チェック
    local thesis_conf="${core_dir}/${FILE_THESIS_CONF}"
    if [ ! -f "${thesis_conf}" ]; then
      echo "❌ Error: 設定ファイルが見つかりません: ${thesis_conf}" >&2
      return 0
    fi
    
    # バージョン抽出対象、および結合対象のベースとして設定ファイルを指定
    conf_for_version="${thesis_conf}"
    md_files+=("${thesis_conf}")
    
    # 💡 3. 引数の有無に関わらず、常に thesis.txt から構成チャプター群を読み込む（共通化）
    while IFS= read -r line; do
      if [ -n "${line}" ]; then
        md_files+=("${thesis_dir}/${line}")
      fi
    done < <(sed -n '/^[[:space:]]*thesis_files:/,$p' "${thesis_conf}" | grep -E '^[[:space:]]*-[[:space:]]+' | sed -E 's/[[:space:]]*- //')
    
    echo "=================================================="
    echo "🎓 Mode: [Thesis Assembly] - Target: ${base_filename}"
    echo "=================================================="
  fi

  # ----------------------------------------------------------------------------
  # 3.2 バージョン決定ロジック
  # ----------------------------------------------------------------------------
  local final_version=""
  if [ -n "${TAG_NAME:-}" ] && [ "${mode}" != "subject" ]; then
    final_version="${TAG_NAME}.${COMMIT_COUNT:-0}"
  else
    local file_version
    file_version=$(sed -n '/^---$/,/^---$/p' "${conf_for_version}" | grep -E "${PATTERN_VERSION_MARK}" | sed -E 's/^version:[[:space:]]*[\"'\'']?([^\"''[:space:]]+)[\"'\'']?/\1/' || true)
    final_version="${file_version:-v0.0.0}"
  fi
  echo "ℹ️ Document version: ${final_version}"

  # ----------------------------------------------------------------------------
  # 3.3 テンプレートパス解決 & 整合性検証
  # ----------------------------------------------------------------------------
  local yaml_path="$(resolve_template "${FILE_DEFAULTS_YAML}" "${template_dir}")"
  local template_docx="$(resolve_template "${FILE_TEMPLATE_DOCX}" "${template_dir}")"
  local template_latex="$(resolve_template "${FILE_TEMPLATE_LATEX}" "${template_dir}")"

  # ----------------------------------------------------------------------------
  # 3.4 ビルド環境への移動と検索パス（優先順位）の設定
  # ----------------------------------------------------------------------------
  local origin_dir="$PWD"
  cd "${work_dir}" || return 0

  # 共通の検索パスを1本作る（左から順に優先してファイルを探しに行きます）
  # 優先順位: 1.カレントディレクトリ(.) ＞ 2.モード専用テンプレート ＞ 3.共通テンプレート
  local search_paths=".:${template_dir}:${ENV_DIR}/${DIR_TEMPLATES}:${thesis_dir}/${DIR_CORE}:${thesis_dir}"

  # A. Pandoc 用の設定
  local pandoc_resource_path="${search_paths}"

  # B. LaTeX 関連用の環境変数エクスポート
  export TEXINPUTS="${search_paths}:"
  export BIBINPUTS="${search_paths}:"
  export BSTINPUTS="${search_paths}:"

  # ----------------------------------------------------------------------------
  # 3.5 各種コンパイルタスクの実行
  # ----------------------------------------------------------------------------
  # A. Docx 変換
  if [[ "${OUTPUT_EXT}" =~ ^(docx|all)$ ]]; then
    echo "--- Running Pandoc to generate Docx ---"
    pandoc -s --filter pandoc-crossref \
      -d "${yaml_path}" \
      --reference-doc="${template_docx}" \
      --resource-path="${pandoc_resource_path}" \
      --metadata version="${final_version}" \
      --citeproc \
      "${md_files[@]}" \
      -o "${base_filename}.docx"
  fi

  # B. LaTeX 変換
  if [[ "${OUTPUT_EXT}" =~ ^(tex|pdf|all)$ ]]; then
    echo "--- Running Pandoc to generate LaTeX ---"
    pandoc -s --filter pandoc-crossref \
      -d "${yaml_path}" \
      ${top_division_opt} \
      --template="${template_latex}" \
      --resource-path="${pandoc_resource_path}" \
      --metadata version="${final_version}" \
      --biblatex \
      -f markdown+pipe_tables \
      -t latex \
      "${md_files[@]}" \
      -o "${base_filename}.tex"
  fi

  # C. PDF 生成 (LuaLaTeX + Biber)
  if [[ "${OUTPUT_EXT}" =~ ^(pdf|all|tex2pdf)$ ]]; then
    echo "--- Compiling to PDF (latexmk) ---"  
    latexmk -pdflua -e '$biber=q/biber %O %S/' "${base_filename}.tex"
  fi

  # D. 中間ファイルのクリーンアップ
  if [ "${OUTPUT_EXT}" = "clear" ]; then
    echo "--- Cleaning up intermediate files ---"
    latexmk -c "${base_filename}.tex" || true
    
    for ext in "${CLEAR_EXTS[@]}"; do
      rm -f "${base_filename}.${ext}"
    done
  fi

  # 元のディレクトリに戻る
  cd "${origin_dir}"
  echo "✅ Processed successfully: ${base_filename}"
}

# ==============================================================================
# 4. 実行エントリポイント（動的モード選択・ループ駆動）
# ==============================================================================
if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  # 💡 引数がない場合は無条件で標準の thesis モードを実行
  compile_pipeline "thesis" ""
else
  # 💡 引数が渡された場合は、ファイルごとに内部のメタデータを解析して動的にモードを切り替える
  for FILE in "${TARGET_FILES[@]}"; do
    if check_is_thesis_file "${FILE}"; then
      # is-thesis: true が検出された場合は thesis モードへ
      compile_pipeline "thesis" "${FILE}" || echo "⚠️ ${FILE} のビルド（Thesisモード）に失敗したため、次のファイルを処理します。"
    else
      # それ以外は通常の subject モードへ
      compile_pipeline "subject" "${FILE}" || echo "⚠️ ${FILE} のビルド（Subjectモード）に失敗したため、次のファイルを処理します。"
    fi
  done
fi