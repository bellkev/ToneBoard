from collections import defaultdict, namedtuple
from functools import partial, reduce
from itertools import groupby
import json
import os
import re
import sqlite3
import unicodedata as ud


COMMON_TONE_THRESHOLD=0.75

TONE_FREQUENCY_TWEAKS={
    '喂': {'wei4': 0.5, 'wei2': 0.5},
    '李': {'li3': 1.0},
}


def extract_tone(s):
    unicode_tone = {
    '\u0304': 1,
    '\u0301': 2,
    '\u030C': 3,
    '\u0300': 4,
    }
    tone = 5
    rest = ''
    for c in s:
        norm = ud.normalize('NFD', c)
        toneless = ''
        for cn in norm:
            if cn in unicode_tone:
                tone = unicode_tone[cn]
            else:
                toneless += cn
        rest += ud.normalize('NFC', toneless)
    return tone, rest


def standardize_pinyin(s):
    tone, rest = extract_tone(s)
    return rest.replace('ü', 'v') + str(tone)


def normalize_number_values(d):
    '''Normalize the values in a key:number dict so that they add to 1'''
    total = sum(d.values())
    for k in d.keys():
        d[k] /= total


def load_unihan(path):
    ret = {}
    with open(path) as f:
        chars = json.load(f)
        for char_data in chars:
            char = char_data['char']
            pinlu = char_data['kHanyuPinlu']
            reading_freqs = {standardize_pinyin(reading['phonetic']): reading['frequency'] for reading in pinlu}
            normalize_number_values(reading_freqs)
            ret[char] = reading_freqs
    ret.update(TONE_FREQUENCY_TWEAKS)
    return ret


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
                if year > 1990:
                    ret[one_gram] += count
    return ret


def load_cc_cedict(path):
    regex = re.compile(r'^(\S+) (\S+) \[(.*?)\]')
    with open(path) as f:
        for line in f:
            if not line or line[0] == '#':
                continue
            match = regex.search(line)
            yield match.groups()


Word = namedtuple('Word', ['trad', 'simp', 'reading', 'freq', 'rare_tone'], defaults=[0, False])


def cc_words(cc_data):
    for traditional, simplified, reading in cc_data:
        # TODO: Test for norm_reading
        norm_reading = reading.lower().replace('u:', 'v')
        yield Word(traditional, simplified, norm_reading)


def filter_fn():
    regex = re.compile(r'(?:[a-z]+[1-5]\s?)+')
    def f(word):
        is_well_formed = regex.fullmatch(word.reading)
        # Rough check that these are all CJK chars
        # See http://www.unicode.org/Public/UNIDATA/Blocks.txt
        is_cjk_chars = all(ord(char) >= 0x3400 for char in word.simp)
        is_short = len(word.simp) <= 4
        return is_well_formed and is_cjk_chars and is_short
    return f


def add_freqs(ngram_data, words):
    return (word._replace(freq=ngram_data.get(word.simp, 0)) for word in words)


def is_rare_tone(reading, reading_freqs):
    toneless = lambda x: x[:-1]
    similar_reading_freqs = {k: v for (k, v) in reading_freqs.items() if toneless(reading) == toneless(k)}
    normalize_number_values(similar_reading_freqs)
    exists_common = any(val >= COMMON_TONE_THRESHOLD for val in similar_reading_freqs.values())
    is_common = similar_reading_freqs.get(reading, 0) >= COMMON_TONE_THRESHOLD
    return exists_common and not is_common


def scale_char_freqs(unihan_data, words):
    for word in words:
        if word.simp in unihan_data:
            reading_stats = unihan_data[word.simp]
            multiplier = reading_stats.get(word.reading, 0)
            is_rare = is_rare_tone(word.reading, reading_stats)
            yield word._replace(freq=word.freq * multiplier, rare_tone=is_rare)
        else:
            yield word


def expand_subwords(words):
    for word in words:
        reading_segments = word.reading.split(' ')
        # Add each subword as well as the word itself
        for i in range(1, len(word.simp) + 1):
            yield Word(word.trad[0:i], word.simp[0:i], ' '.join(reading_segments[0:i]), word.freq)


def merge_freqs(words):
    word_reading_char = lambda word: (word.reading, word.simp)
    # TODO: At this point the traditional reading is basically ignored. It would be better
    # to create some kind of "Candidate" record that is simplified/traditional specific
    freq_reducer = lambda w1,w2: w1._replace(freq=w1.freq + w2.freq)
    sorted_words = sorted(words, key=word_reading_char)
    for k, group in groupby(sorted_words, key=word_reading_char):
        yield reduce(freq_reducer, group)


def pipeline(*fns):
    def f(x):
        ret = x
        for fn in fns:
            ret = fn(ret)
        return ret
    return f


def candidate_dict_data(cc_data, ngram_data, unihan_data):
    pipe = pipeline(
        cc_words,
        partial(filter, filter_fn()),
        partial(add_freqs, ngram_data),
        expand_subwords,
        merge_freqs,
        partial(scale_char_freqs, unihan_data),
    )
    return pipe(cc_data)


def create_sqlite(conn, data):
    cursor = conn.cursor()
    cursor.execute("""CREATE TABLE IF NOT EXISTS reading_char(
                          reading TEXT,
                          char TEXT,
                          frequency REAL,
                          rare_tone INTEGER);""")
    cursor.execute("CREATE INDEX reading_char_reading ON reading_char(reading);")
    rows = [word._asdict() for word in data]
    cursor.executemany("INSERT INTO reading_char VALUES (:reading, :simp, :freq, :rare_tone)", rows)
    conn.commit()


def save_sqlite(data, path):
    try:
        os.remove(path)
    except FileNotFoundError:
        pass
    conn = sqlite3.connect(path)
    create_sqlite(conn, data)
    conn.close()


if __name__ == '__main__':
    import sys
    unihan = load_unihan(sys.argv[1])
    one_grams = load_one_grams(sys.argv[2])
    cc = load_cc_cedict(sys.argv[3])
    d = candidate_dict_data(cc, one_grams, unihan)
    save_sqlite(d, sys.argv[4])
