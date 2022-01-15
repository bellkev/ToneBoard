#! /usr/bin/env bash

set -eu

NGRAM_URL="http://storage.googleapis.com/books/ngrams/books/20200217/chi_sim/1-00000-of-00001.gz"
CC_CEDICT_URL="https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz"

# $1: source, $2: dest
download() {
  if [[ -f $2 ]]; then
    echo "File exists."
  else
    curl "$1" > "$2.gz"
    md5 "$2.gz"
    gunzip "$2.gz"
  fi
}

TMP_DIR="dict/tmp"
mkdir -p "$TMP_DIR"

echo "Preparing Unihan data..."
unihan-etl -z "$TMP_DIR/unihan.zip" -d "$TMP_DIR/unihan.json" -F json -f kHanyuPinlu
echo "Downloading ngram data..."
download "$NGRAM_URL" "$TMP_DIR/1grams.txt"
echo "Downloading CC-CEDICT..."
download "$CC_CEDICT_URL" "$TMP_DIR/cc_cedict.txt"
echo "Building dictionary..."
python dict/build_dict.py \
  "$TMP_DIR/unihan.json" "$TMP_DIR/1grams.txt" "$TMP_DIR/cc_cedict.txt" "app/dict.sqlite3"
