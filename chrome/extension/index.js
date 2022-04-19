const NOOP = 'NOOP';
const BEGIN_INPUT = 'BEGIN_INPUT';
const CONTINUE_INPUT = 'CONTINUE_INPUT';
const COMMIT_INPUT = 'COMMIT_INPUT';
const CANCEL_INPUT = 'CANCEL_INPUT';

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

function render(inputState, uiState) {
    let candidateMarkup = inputState.candidates.map((c, i) =>
        `<div class="tbcandidate ${i == inputState.selected ? 'selected' : ''}">${c}</div>`
    ).join('');
    let {syllables, remainder} = toneBoardInput(inputState.rawInput);
    syllables.push(remainder);
    let rect = getCursorRect(uiState.inputElement);
    let markup = `
    <div id="tbview" class="${inputState.rawInput ? '' : 'hidden'}"
        style="left: ${rect.left}px; top: ${rect.bottom}px;" lang="zh-CN">
        <div id="tbinput">
            ${syllables.join(' ') || '&nbsp;'}
        </div>
        <div id="tbcandidates">
            ${candidateMarkup}<div class="tbcandidate placeholder">&nbsp;</div>
        </div>
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
            // TODO: actually insert at the cursor...
            el.value += toInput;
            e.preventDefault();
            let inputEvent = new Event('input', {bubbles: true, cancelable: false});
            el.dispatchEvent(inputEvent);
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
        // TODO: Add basic substitutions like full-width commas
        case NOOP:
            break;
    }
    uiState.inputElement = e.target;
    render(inputState, uiState);
}

const inputState = {
    candidates: [],
    rawInput: '',
    selected: 0,
}

const uiState = {}

uiState.view = document.createElement('DIV');
// render(inputState, uiState);
document.body.appendChild(uiState.view);

let dictUrl = chrome.runtime ? chrome.runtime.getURL("dict.json") : "extension/dict.json";


fetch(dictUrl)
.then(response => response.json())
.then(data => {
    window.dictData = data;
});

document.addEventListener('keydown', eventHandler);