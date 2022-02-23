import sqlite3

import build_dict as bd


UNIHAN_DATA={
    '吃': {'chi1': 1.0},
    '离': {'li2': 1.0},
    '还': {'hai2': 0.98, 'huan2': 0.02},
    '为': {'wei4': 0.6, 'wei2': 0.4},
    '哪': {'na3': 0.81, 'na5': 0.19},
    '吗': {'ma5': 0.94, 'ma2': 0.06},

}

ONE_GRAMS={
    '我': 30000000,
    '水': 3000000,
    '喝': 50000,
    '非常': 4000000,
    '呵': 1000,
    '咖': 4000,
    '咖啡': 100000,
    '喀': 30000,
    '吃': 500000,
    '离': 1500000,
    '环': 1000000,
    '还': 30000000,
}

CC=[
    ('東西南北', '东西南北', 'dong1 xi1 nan2 bei3'),
    ('我', '我', 'wo3'),
    ('喝', '喝', 'he1'),
    ('水', '水', 'shui3'),
    ('非常', '非常', 'fei1 chang2'),
    ('呵', '呵', 'he1'),
    ('%', '%', 'pa1'),
    ('々', '々', 'xx'),
    ('烏里雅蘇台', '乌里雅苏台', 'wu1 li3 ya3 su1 tai2'),
    ('咖', '咖', 'ka1'),
    ('咖啡', '咖啡', 'ka1 fei1'),
    ('喀', '喀', 'ka1'),
    ('離', '离', 'li2'),
    ('离', '离', 'chi1'),
    ('吃', '吃', 'chi1'),
    ('還', '还', 'huan2'),
    ('還', '还', 'hai2'),
    ('環', '环', 'huan2'),
    ('哪', '哪', 'na3'),
    ('哪', '哪', 'na5'),
    ('嗎', '吗', 'ma5'),
    ('嗎', '吗', 'ma3'),
    ('為', '为', 'wei2'),
    ('為', '为', 'wei4'),
]


class SimpleDB:

    def __init__(self, path):
        self.conn = sqlite3.connect(path)
        self.conn.row_factory = sqlite3.Row

    def load(self):
        bd.create_sqlite(self.conn, bd.candidate_dict_data(CC, ONE_GRAMS, UNIHAN_DATA))

    def query_all(self, reading):
        cur = self.conn.cursor()
        cur.execute("SELECT * FROM reading_char WHERE reading = ? ORDER BY frequency DESC", (reading,))
        return cur.fetchall()

    def query(self, reading):
        return [row['char'] for row in self.query_all(reading)]



DB=SimpleDB(":memory:")
DB.load()


def test_basic_word():
    assert '我' in DB.query('wo3')


def test_compound_word():
    assert '非常' in DB.query('fei1 chang2')


def test_partial_word():
    assert '东西南' in DB.query('dong1 xi1 nan2')


def test_ranking():
    candidates = DB.query('he1')
    assert candidates.index('喝') < candidates.index('呵')


def test_filter_non_hanzi():
    assert '%' not in DB.query('pa1')


def test_well_formed():
    assert '々' not in DB.query('xx')


def test_short():
    assert '乌里雅苏台' not in DB.query('wu1 li3 ya3 su1 tai2')


def test_compound_freq_for_sub_words():
    candidates = DB.query('ka1')
    assert candidates.index('咖') < candidates.index('喀')
    # Make sure subword candidates don't duplicate existing candidates
    candidates = DB.query('ka1')
    assert len([c for c in candidates if c=='咖']) == 1


def test_heteronym_freqs():
    candidates = DB.query('chi1')
    assert candidates.index('吃') < candidates.index('离')
    candidates = DB.query('huan2')
    assert candidates.index('环') < candidates.index('还')


def is_rare(char, reading):
    candidates = DB.query_all(reading)
    return [c for c in candidates if c['char'] == char][0]['rare_tone']

def test_rare_tones():
    # Flag candidates when there is an alternative tone that is much more common
    assert is_rare('哪', 'na5')
    assert not is_rare('哪', 'na3')
    # Only flag tone-only differences
    assert not is_rare('还', 'huan2')
    # Don't flag tones as rare when there is no especially common tone
    assert not is_rare('为', 'wei2')
