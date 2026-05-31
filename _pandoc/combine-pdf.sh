#!/bin/bash
# ----------------------------------------------------------------------------
# 引数のPDFファイルと卒論PDFとを結合する処理
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

if [ -n "${1:-}" ]; then
  # $1 がファイルパスだった場合（単体モード）
  TARGET_ARG="$1"
  # 引数から絶対パスを割り出す
  readonly TARGET_SRC="$(cd "$(dirname "${TARGET_ARG}")" && pwd)/$(basename "${TARGET_ARG}")"
  readonly OUTPUT_DIR="$(dirname "${TARGET_SRC}")"
else
  # 引数がない場合のフォールバック（必要に応じて変更してください）
  log_error "エラー: 結合するPDFファイルが指定されていません。"
  log_error "使用方法: ./combine-pdf.sh [結合したいPDFのパス]"
  exit 1
fi

readonly WORK_DIR="${SCRIPT_DIR}/.combine_work"

log_info "Starting PDF combination process..."

# 作業用一時ディレクトリのクリーンアップと作成
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

# ==============================================================================
# 2. 対象PDFの存在チェック
# ==============================================================================
readonly PDF_1="${TARGET_SRC}"
readonly PDF_2="${THESIS_DIR}/00.core/thesis.pdf"

for pdf in "${PDF_1}" "${PDF_2}"; do
    if [[ ! -f "${pdf}" ]]; then
        log_error "PDF file not found: ${pdf}"
        exit 1
    fi
done

# ==============================================================================
# 3. 結合用 .tex ファイルの動的生成
# ==============================================================================
readonly COMBINE_TEX="${WORK_DIR}/combined.tex"

ln -sf "${PDF_1}" "${WORK_DIR}/doc1.pdf"
ln -sf "${PDF_2}" "${WORK_DIR}/doc2.pdf"

cat << 'EOF' > "${COMBINE_TEX}"
\documentclass[autodetect-engine,ja=standard]{bxjsarticle}
\usepackage{pdfpages}
\pagestyle{plain}
\begin{document}
\includepdf[pages=-]{doc1.pdf}
\includepdf[pages=-]{doc2.pdf}
\end{document}
EOF

# ==============================================================================
# 4. コンパイルの実行と成果物の移動
# ==============================================================================
cd "${WORK_DIR}"
lualatex -interaction=nonstopmode combined.tex > /dev/null

readonly FINAL_OUTPUT="${OUTPUT_DIR}/integrated_thesis.pdf"
mv "${WORK_DIR}/combined.pdf" "${FINAL_OUTPUT}"

# ==============================================================================
# 5. 後片付け
# ==============================================================================
rm -rf "${WORK_DIR}"

log_info "Success! Combined PDF generated at: ${FINAL_OUTPUT}"