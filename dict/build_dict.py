from collections import defaultdict
import json
import os
import re
import sqlite3


def load_one_grams(path):
    ret = defaultdict(int)
    with open(path) as f:
        for line in f:
            # Not worth using csv.reader because of odd format, quoting
            row = line.split('\t')
            # Ignore POS tags
            one_gram = row[0].split('_')[0]
            for entry in row[1:]:
                year, count, _ = map(int, entry.split(','))
                ret[one_gram] += count
    return ret


def load_cc_cedict(path):
    ret = []
    regex = re.compile(r'^(\S+) (\S+) \[(.*?)\]')
    with open(path) as f:
        for line in f:
            if not line or line[0] == '#':
                continue
            match = regex.search(line)
            ret.append(match.groups())
    return ret


def candidate_dict(cc_data, ngram_data):
    reading_entries = defaultdict(set)
    regex = re.compile(r'(?:[a-z]+[1-5]\s?)+')
    for traditional, simplified, reading in cc_data:
        norm_reading = reading.lower().replace('u:', 'v')
        is_well_formed = regex.fullmatch(norm_reading)
        # Rough check that these are all CJK chars
        # See http://www.unicode.org/Public/UNIDATA/Blocks.txt
        is_cjk_chars = all(ord(char) >= 0x3400 for char in simplified)
        is_short = len(simplified) <= 4
        if is_well_formed and is_cjk_chars and is_short:
            reading_segments = norm_reading.split(' ')
            # Add each subword as well as the word itself
            for i in range(1, len(simplified) + 1):
                reading_entries[' '.join(reading_segments[0:i])].add(simplified[0:i])
    return {k: sorted(v, key=lambda x: ngram_data.get(x, 0), reverse=True)
            for k,v in reading_entries.items()}


def save_json(d, path):
    with open(path, 'w') as f:
        json.dump(d, f, ensure_ascii=False)


def save_sqlite(d, path):
    try:
        os.remove(path)
    except FileNotFoundError:
        pass
    conn = sqlite3.connect(path)
    cursor = conn.cursor()
    # Not bothering to normalize, as only 1-2% of candidates appear under
    # multiple readings
    cursor.execute("""CREATE TABLE IF NOT EXISTS reading_candidates(
                      reading TEXT PRIMARY KEY,
                      candidates TEXT
                   ) WITHOUT ROWID;""")
    rows = [(reading, ' '.join(candidates)) for (reading, candidates) in d.items()]
    cursor.executemany("INSERT INTO reading_candidates VALUES (?, ?)", rows)
    conn.commit()
    conn.close()



if __name__ == '__main__':
    import sys
    one_grams = load_one_grams(sys.argv[1])
    cc = load_cc_cedict(sys.argv[2])
    d = candidate_dict(cc, one_grams)
    save_sqlite(d, sys.argv[3])
