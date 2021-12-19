from collections import defaultdict
import json
import re


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
    regex = re.compile('(?:[a-z]+[1-5]\s?)+')
    for traditional, simplified, reading in cc_data:
        norm_reading = reading.lower().replace('u:', 'v')
        is_well_formed = regex.fullmatch(norm_reading)
        # Rough check that these are all CJK chars
        # See http://www.unicode.org/Public/UNIDATA/Blocks.txt
        is_cjk_chars = all(ord(char) >= 0x3400 for char in simplified)
        is_short = len(simplified) <= 4
        if is_well_formed and is_cjk_chars and is_short:
            reading_entries[norm_reading].add(simplified)
    return {k: sorted(v, key=lambda x: ngram_data.get(x, 0), reverse=True)
            for k,v in reading_entries.items()}



if __name__ == '__main__':
    one_grams = load_one_grams('tmp/1grams.txt')
    cc = load_cc_cedict('tmp/cc_cedict.txt')
    with open('dict.json', 'w') as f:
        d = candidate_dict(cc, one_grams)
        json.dump(d, f, ensure_ascii=False)
