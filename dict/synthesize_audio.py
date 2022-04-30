import json
from collections import defaultdict
import os

import boto3


def r_color(syl):
    toneless = syl[:-1]
    tone = syl[-1]
    return toneless + 'r' + tone


def polly_pinyin(s):
    '''Convert from CC-CEDICT's Pinyin standard to Amazon Polly's'''
    if s == 'r5':
        return 'er0'
    cc_syllables = s.split(' ')
    polly_syllables = []
    for syl in cc_syllables:
        if syl == 'r5':
            polly_syllables[-1] = r_color(polly_syllables[-1])
        else:
            polly_syl = syl.replace('5', '0').replace('v', 'yu')
            polly_syllables.append(polly_syl)
    return '-'.join(polly_syllables)


def reading_ssml(s):
    '''Generate SSML for a given reading from the ToneBoard dictionary'''
    return '<speak><phoneme alphabet="x-amazon-pinyin" ph="%s" /></speak>' % polly_pinyin(s)


def synthesize(path, s):
    text_type = 'text'
    if s.startswith('<speak>'):
        text_type = 'ssml'
    polly = boto3.client('polly')
    resp = polly.synthesize_speech(
        Engine='standard',
        LanguageCode='cmn-CN',
        OutputFormat='mp3',
        SampleRate='22050',
        Text=s,
        TextType=text_type,
        VoiceId='Zhiyu'
    )
    print('Response:', resp)
    with open(path, 'wb') as f:
        f.write(resp['AudioStream'].read())


def multichar_subdirs(chars):
    bytes = ['%X' % b for b in chars.encode('utf-8')]
    return ['multi_char'] + bytes[:3]


def ensure_audio(base_path, chars, reading):
    '''
    Synthesize audio for a given char/reading combo.
    The generated audio should approximate actual speech, including tone sandhi.
    CC-CEDICT tones do not include sandhi, so the current scheme is to count on Polly
    to provide reasonable readings based on actual characters.
    SSML is only generated for simple, single-character syllables, as there is a lot of reading
    re-use here and sandhi should not be an issue.
    TODO: There are some edge cases where Polly will not provide the desired pronunciation,
    such as missing erhua in 吊儿郎 (incomplete form of 吊儿郎当).
    TODO: Also handle multi-character words with multiple pronunciation variants (about 500 of these total)
    '''
    if len(chars) == 1:
        key = reading
        synth_text = reading_ssml(reading)
        subdirs = ['single_char']
    else:
        key = chars
        synth_text = chars
        subdirs = multichar_subdirs(chars)
    dir = os.path.join(base_path, *subdirs)
    os.makedirs(dir, exist_ok=True)
    path = os.path.join(dir, '%s.mp3' % key)
    if os.path.isfile(path):
        print('%s exists, skipping...' % path)
        return
    synthesize(path, synth_text)


def load_json(path):
    '''Load JSON version of the ToneBoard dictionary from disk'''
    with open(path) as f:
        return json.load(f)


def load_chars_readings(path):
    d = load_json(path)
    ret = defaultdict(list)
    for reading, values in d.items():
        for chars in values:
            ret[chars].append(reading)
    return dict(ret)


def ensure_all_audio(json_path, audio_path):
    chars_readings = load_chars_readings(json_path)
    crs = [(chars, reading) for (chars, readings) in chars_readings.items() for reading in readings]
    for i, cr in enumerate(crs):
        chars, reading = cr
        print('Synthesizing %s (%s) (%d/%d)...' % (chars, reading, i, len(crs)))
        ensure_audio(audio_path, chars, reading)


if __name__ == '__main__':
    import sys
    json_path = sys.argv[1]
    audio_path = sys.argv[2]
    ensure_all_audio(json_path, audio_path)