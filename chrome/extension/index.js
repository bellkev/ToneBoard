const NOOP = 'NOOP';
const BEGIN_INPUT = 'BEGIN_INPUT';
const CONTINUE_INPUT = 'CONTINUE_INPUT';
const COMMIT_INPUT = 'COMMIT_INPUT';
const CANCEL_INPUT = 'CANCEL_INPUT';

const inputState = {
    candidates: [],
    rawInput: '',
    selected: 0,
}

const uiState = {}

function toneBoardInput(rawInput) {
    let syllables = [];
    let remainder = '';
    [...rawInput].forEach((c) => {
        if ('12345'.includes(c)) {
            syllables.push(remainder + c);
            remainder = '';
        } else {
            remainder += c;
        }
    });
    return {syllables, remainder};
}

function makeView() {
    let el = document.createElement('DIV');
    el.id = 'tbview';
    el.lang = 'zh-CN';
    return el;
}

function render(inputState, uiState) {
    let candidateMarkup = inputState.candidates.map((c, i) =>
        `<div class="tbcandidate ${i == inputState.selected ? 'selected' : ''}">${c}</div>`
    ).join('');
    let {syllables, remainder} = toneBoardInput(inputState.rawInput);
    syllables.push(remainder);
    let markup = `
    <div id="tbinput">
        ${syllables.join(' ') || '&nbsp;'}
    </div>
    <div id="tbcandidates">
        ${candidateMarkup}<div class="tbcandidate placeholder">&nbsp;</div>
    </div>
    `
    uiState.view.innerHTML = markup;
}

function updateState(inputState, e) {
    // TODO: Operate on key (code) here instead of events
    let result, toInput;
    if (e.key == 'Backspace' && inputState.rawInput) {
        inputState.rawInput = inputState.rawInput.slice(0,-1);
        result = inputState.rawInput ? CONTINUE_INPUT : CANCEL_INPUT;
    } else if (e.key == 'Tab' && inputState.candidates.length) {
        // TODO: Allow selection with more than just tab (arrow keys, etc)
        let shift = e.getModifierState('Shift');
        if (shift && 0 < inputState.selected) {
            inputState.selected--;
        } else if (!shift && inputState.selected < inputState.candidates.length - 1) {
            inputState.selected++;
        }
        result = CONTINUE_INPUT;
    } else if (e.code == 'Space' && inputState.candidates.length) {
        // Commit text...
        toInput = inputState.candidates[inputState.selected];
        inputState.candidates = [];
        inputState.rawInput = '';
        inputState.selected = 0;
        result = COMMIT_INPUT;
    } else if (e.key.match(/^[a-z1-5]$/)) {
        let initial = inputState.rawInput;
        inputState.rawInput += e.key;
        result = initial ? CONTINUE_INPUT : BEGIN_INPUT;
    } else {
        result = NOOP;
    }
    return {result, toInput};
}

function eventHandler(e) {
    // TODO: Handle switching to different areas, focus events
    let el = e.target;
    let isTextInput = el.tagName == 'INPUT' && el.type == 'text';
    let isTextArea = el.tagName == 'TEXTAREA';
    if (!(isTextInput || isTextArea)) {
        return;
    }
    // TODO: Add zh-CN/zh-Hans...
    if (!el.attributes['lang'] || el.attributes['lang'].value != 'zh') {
        return;
    }
    let modifiers = ["Alt", "AltGraph", "Control", "Meta", "OS"];
    if (modifiers.some((m) => e.getModifierState(m))) {
        return;
    }
    // TODO: Name these better...
    let {result, toInput} = updateState(inputState, e);
    console.log(result);
    switch (result) {
        case COMMIT_INPUT:
            el.value += toInput;
            e.preventDefault();
            break;
        case CANCEL_INPUT:
            e.preventDefault();
            break;
        case BEGIN_INPUT:
        case CONTINUE_INPUT:
            let {syllables} = toneBoardInput(inputState.rawInput);
            // TODO: Update selection?
            inputState.candidates = dictData[syllables.join(' ')] || [];
            e.preventDefault();
            break;
        case NOOP:
            break;
    }
    render(inputState, uiState);
}

uiState.view = makeView();
render(inputState, uiState);
document.body.appendChild(uiState.view);

let dictUrl = "extension/dict.json";

if (chrome.runtime) {
    dictUrl = chrome.runtime.getURL("dict.json")
}

fetch(dictUrl)
.then(response => response.json())
.then(data => {
    window.dictData = data;
});

document.addEventListener('keydown', eventHandler)