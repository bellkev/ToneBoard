from collections import defaultdict, namedtuple
from functools import partial, reduce
from itertools import groupby
import json
import os
import re
import sqlite3
import unicodedata as ud


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


def norm_pinyin(s):
    tone, rest = extract_tone(s)
    return rest.replace('ü', 'v') + str(tone)


def load_unihan(path):
    ret = defaultdict(dict)
    with open(path) as f:
        chars = json.load(f)
        for char_data in chars:
            char = char_data['char']
            pinlu = char_data['kHanyuPinlu']
            reading_freqs = [(norm_pinyin(reading['phonetic']), reading['frequency']) for reading in pinlu]
            total_freq = sum(rf[1] for rf in reading_freqs)
            for rf in reading_freqs:
                ret[char][rf[0]] = rf[1] / total_freq
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


Word = namedtuple('Word', ['trad', 'simp', 'reading', 'freq'], defaults=[0])


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


def scale_char_freqs(unihan_data, words):
    for word in words:
        if word.freq and word.simp in unihan_data:
            multiplier = unihan_data[word.simp].get(word.reading, 0)
            yield word._replace(freq=word.freq * multiplier)
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


def candidate_dict(cc_data, ngram_data, unihan_data):
    pipe = pipeline(
        cc_words,
        partial(filter, filter_fn()),
        partial(add_freqs, ngram_data),
        expand_subwords,
        merge_freqs,
        partial(scale_char_freqs, unihan_data),
        lambda words: sorted(words, key=lambda x: x.freq, reverse=True)
    )
    reading_entries = defaultdict(list)
    for word in pipe(cc_data):
        reading_entries[word.reading].append(word.simp)
    return reading_entries


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
    unihan = load_unihan(sys.argv[1])
    one_grams = load_one_grams(sys.argv[2])
    cc = load_cc_cedict(sys.argv[3])
    d = candidate_dict(cc, one_grams, unihan)
    save_sqlite(d, sys.argv[4])
