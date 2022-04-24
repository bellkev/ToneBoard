import { getCursorRect } from './cursor.js';
import * as config from './config.js';

const TbKeyType = {
    LEFT: 'LEFT',
    RIGHT: 'RIGHT',
    ENTER: 'ENTER',
    SPACE: 'SPACE',
    BACKSPACE: 'BACKSPACE',
    WORD: 'WORD',
    SYMBOL: 'SYMBOL',
    OTHER: 'OTHER',
}

const TbAction = {
    COMPOSE_APPEND: 'COMPOSE_APPEND',
    COMPOSE_DELETE: 'COMPOSE_DELETE',
    NEXT_CANDIDATE: 'NEXT_CANDIDATE',
    PREVIOUS_CANDIDATE: 'PREVIOUS_CANDIDATE',
    COMMIT_CANDIDATE: 'COMMIT_CANDIDATE',
    COMMIT_RAW: 'COMMIT_RAW',
    CANCEL_WITH_DEFAULT: 'CANCEL_WITH_DEFAULT',
    CANCEL_WITH_REPLACEMENT: 'CANCEL_WITH_REPLACEMENT',
    REPLACE: 'REPLACE',
    DEFAULT: 'DEFAULT',
}

function toneBoardKey(e) {
    let type;
    let modifiers = ["Alt", "AltGraph", "Control", "Meta", "OS"];
    if (modifiers.some((m) => e.getModifierState(m))) {
        type = TbKeyType.OTHER;
    } else if (e.key == 'Tab' && e.getModifierState('Shift')) {
        type = TbKeyType.LEFT;
    } else if (e.key == 'Tab') {
        type = TbKeyType.RIGHT;
    } else if (e.key.match(/^[a-z1-5]$/)) {
        type = TbKeyType.WORD;
    } else if (e.key == 'Backspace') {
        type = TbKeyType.BACKSPACE;
    } else if (e.key == ' ') {
        type = TbKeyType.SPACE;
    } else if (e.key == 'Enter') {
        type = TbKeyType.ENTER;
    }
    return {key: e.key, type};
}

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

function adjustCandidateScroll(candidatesElement, selection) {
    // Scroll just enough (+ some padding) that the selected candidate is not clipped
    // Using the full candidatesElement width as coordinate system
    let visibleWidth = candidatesElement.offsetWidth;
    let left = el => el.offsetLeft
    let right = el => el.offsetLeft + el.offsetWidth
    let anchorLeft = el => candidatesElement.scrollLeft = left(el) - 5;
    let anchorRight = el => candidatesElement.scrollLeft = right(el) - visibleWidth + 5;
    // First scroll to the established anchor element
    let anchor = candidatesElement.children[selection.scrollAnchor];
    if (selection.anchorRight) {
        anchorRight(anchor)
    } else {
        anchorLeft(anchor)
    }
    // Then ensure the selected candidate is visible
    let visibleLeft = candidatesElement.scrollLeft;
    let visibleRight = visibleLeft + visibleWidth;
    let selected = candidatesElement.children[selection.selected];
    if (visibleRight < right(selected)) {
        anchorRight(selected)
        selection.scrollAnchor = selection.selected
        selection.anchorRight = true
    } else if (left(selected) < visibleLeft) {
        anchorLeft(selected)
        selection.scrollAnchor = selection.selected
        selection.anchorRight = false
    }
}

function render(inputState, view, caretRect) {
    let candidateMarkup = inputState.candidates.map((c, i) =>
        `<div class="tbcandidate ${i == inputState.selection.selected ? 'selected' : ''}">${c}</div>`
    ).join('');
    let {syllables, remainder} = toneBoardInput(inputState.rawInput);
    syllables.push(remainder);
    let markup = `
    <div id="tbview" class="${inputState.rawInput ? '' : 'hidden'}"
        style="left: ${caretRect.left}px; top: ${caretRect.bottom}px;" lang="zh-CN">
        <div id="tbinput">
            ${syllables.join(' ') || '&nbsp;'}
        </div>
        <div id="tbcandidates">
            ${candidateMarkup}<div class="tbcandidate placeholder">&nbsp;</div>
        </div>
    </div>
    `
    view.innerHTML = markup;
    adjustCandidateScroll(view.querySelector('#tbcandidates'), inputState.selection);
}

function nextAction(inputState, tbKey) {
    let composing = !!inputState.rawInput;
    let hasCandidates = !!inputState.candidates.length;
    if (tbKey.type == TbKeyType.WORD) {
        return TbAction.COMPOSE_APPEND;
    } else if (inputState.rawInput && tbKey.type == TbKeyType.ENTER) {
        return TbAction.COMMIT_RAW;
    } else if (hasCandidates && tbKey.type == TbKeyType.LEFT) {
        return TbAction.PREVIOUS_CANDIDATE;
    } else if (hasCandidates && tbKey.type == TbKeyType.RIGHT) {
        return TbAction.NEXT_CANDIDATE;
    } else if (hasCandidates && tbKey.type == TbKeyType.SPACE) {
        return TbAction.COMMIT_CANDIDATE;
    } else if (composing && tbKey.type == TbKeyType.BACKSPACE) {
        return TbAction.COMPOSE_DELETE;
    } else {
        return TbAction.DEFAULT;
    }
}

function newInputState() {
    return {
        candidates: [],
        rawInput: '',
        selection: {
            selected: 0,
            scrollAnchor: 0,
            anchorRight: false
        }
    }
}

function executeAction(inputState, action, key) {
    let clearInputState = () => {Object.assign(inputState, newInputState())};
    if (action == TbAction.PREVIOUS_CANDIDATE && inputState.selection.selected > 0) {
        inputState.selection.selected--;
    } else if (action == TbAction.NEXT_CANDIDATE && inputState.selection.selected < inputState.candidates.length - 1) {
        inputState.selection.selected++;
    } else if (action == TbAction.COMPOSE_APPEND) {
        inputState.rawInput += key;
    } else if (action == TbAction.COMPOSE_DELETE) {
        inputState.rawInput = inputState.rawInput.slice(0,-1)
    } else if (action == TbAction.COMMIT_CANDIDATE) {
        let candidate = inputState.candidates[inputState.selection.selected];
        clearInputState();
        return candidate;
    } else if (action == TbAction.COMMIT_RAW) {
        let raw = inputState.rawInput;
        clearInputState();
        return raw;
    }

}

function refreshCandidates(inputState, dict) {
    let {syllables} = toneBoardInput(inputState.rawInput);
    // TODO: Update selection?
    inputState.candidates = dict[syllables.join(' ')] || [];
}

function shouldHandleEvent(el, mode) {
    if (mode == config.modes.OFF) {
        return false;
    }
    let isTextInput = el.tagName == 'INPUT' && el.type == 'text';
    let isTextArea = el.tagName == 'TEXTAREA';
    if (!(isTextInput || isTextArea)) {
        return false;
    }
    if (mode == config.modes.ON) {
        return true;
    }
    // TODO: Add zh-CN/zh-Hans...
    // TODO: Attribute is not always sufficient, consider checking placeholder as well
    return el.attributes['lang']?.value == 'zh';
}

function eventHandler(e, state, view, dict) {
    // TODO: Handle switching to different areas, focus events
    let el = e.target;
    if (!shouldHandleEvent(el, state.mode)) {
        return;
    }
    let inputState = state.input;
    let tbKey = toneBoardKey(e);
    let action = nextAction(inputState, tbKey);
    // Update new inputState and determine any NON-DEFAULT text to insert at caret
    let newText = executeAction(inputState, action, e.key);
    refreshCandidates(inputState, dict);
    // Update DOM
    // TODO: actually insert at the cursor...
    if (newText) {
        el.value += newText;
    }
    if (action != TbAction.DEFAULT && action != TbAction.CANCEL_WITH_DEFAULT) {
        e.preventDefault();
        // Try to prevent actions that happen on enter (e.g. Duolingo answer submission).
        // This works in practice, but may need to do more to make this handler run first
        // provide an alternative to the enter key for committing rawInput
        e.stopImmediatePropagation();
        let inputEvent = new Event('input', {bubbles: true, cancelable: false});
        el.dispatchEvent(inputEvent);
    }
    render(inputState, view, getCursorRect(el));
}

export function init() {
    const view = document.createElement('DIV');
    document.body.appendChild(view);
    const state = {
        input: newInputState(),
        mode: config.modes.AUTO
    }
    const dict = {};
    let dictUrl;
    if (chrome.runtime) {
        dictUrl = chrome.runtime.getURL("dict.json");
        config.onModeChange((mode) => {
            state.mode = mode;
        });
    } else {
        dictUrl = window.dictUrl;
    }
    fetch(dictUrl)
    .then(response => response.json())
    .then(data => {
        Object.assign(dict, data);
    });
    document.addEventListener('keydown', (e) => {eventHandler(e, state, view, dict)});
}