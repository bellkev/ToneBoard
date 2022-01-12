import build_dict as bd


ONE_GRAMS={
    '我': 30000000,
    '水': 3000000,
    '喝': 50000,
    '非常': 4000000,
    '呵': 1000,
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
]

DICT=bd.candidate_dict(CC, ONE_GRAMS)


def test_basic_word():
    assert '我' in DICT['wo3']


def test_compound_word():
    assert '非常' in DICT['fei1 chang2']


def test_partial_word():
    assert '东西南' in DICT['dong1 xi1 nan2']


def test_ranking():
    candidates = DICT['he1']
    assert candidates.index('喝') < candidates.index('呵')


def test_filter_non_hanzi():
    assert '%' not in DICT.get('pa1', [])


def test_well_formed():
    assert '々' not in DICT.get('xx', [])


def test_short():
    assert '乌里雅苏台' not in DICT.get('wu1 li3 ya3 su1 tai2', [])
