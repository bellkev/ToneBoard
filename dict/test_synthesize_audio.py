from synthesize_audio import polly_pinyin


PINYIN_CASES={
    'wo3': 'wo3',
    'wo3 men5': 'wo3-men0',
    'na3 r5': 'nar3',
    'diao4 r5 lang2': 'diaor4-lang2',
    'nv3 peng2 you5': 'nyu3-peng2-you0',
    'r5': 'er0'
}


def test_polly_pinyin():
    for input, output in PINYIN_CASES.items():
        assert polly_pinyin(input) == output
