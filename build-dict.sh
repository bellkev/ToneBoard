#! /usr/bin/env bash

set -eu

NGRAM_URL="http://storage.googleapis.com/books/ngrams/books/20200217/chi_sim/1-00000-of-00001.gz"
CC_CEDICT_URL="https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz"

# $1: source, $2: dest
download() {
  curl "$1" > "$2.gz"
  md5 "$2.gz"
  gunzip "$2.gz"
}

mkdir -p tmp

echo "Downloading ngram data..."
download "$NGRAM_URL" "tmp/1grams.txt"
echo "Downloading CC-CEDICT..."
download "$CC_CEDICT_URL" "tmp/cc_cedict.txt"
echo "Building dictionary..."
python build_dict.py
