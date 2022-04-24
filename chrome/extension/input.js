import * as keys from './keys.js';


function newSelection() {
    return {
        selected: 0,
        scrollAnchor: 0,
        anchorRight: false
    }
}


export function newState() {
    return {
        candidates: [],
        rawInput: '',
        selection: newSelection()
    }
}


function resetState(state) {
    Object.assign(state, newState());
}


function parseRaw(rawInput) {
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


const actions = {
    composeAppend: (state, key) => {
        state.rawInput += key;
        return {preventDefault: true};
    },
    commitRaw: (state) => {
        let raw = state.rawInput;
        resetState(state);
        return {newText: raw, preventDefault: true}
    },
    commitCandidate: (state) => {
        let candidate = state.candidates[state.selection.selected];
        resetState(state);
        return {newText: candidate, preventDefault: true}
    },
    previousCandidate: (state) => {
        if (0 < state.selection.selected) {
            state.selection.selected--;
        }
        return {preventDefault: true};
    },
    nextCandidate: (state) => {
        if (state.selection.selected < state.candidates.length - 1) {
            state.selection.selected++;
        }
        return {preventDefault: true};
    },
    composeDelete: (state) => {
        state.rawInput = state.rawInput.slice(0,-1)
        return {preventDefault: true};
    },
    default: () => ({preventDefault: false})
}


function nextAction(inputState, key) {
    let composing = !!inputState.rawInput;
    let hasCandidates = !!inputState.candidates.length;
    if (key.match(/^[a-z0-9]$/)) {
        return actions.composeAppend;
    } else if (inputState.rawInput && key == keys.ENTER) {
        return actions.commitRaw;
    } else if (hasCandidates && key == keys.LEFT) {
        return actions.previousCandidate;
    } else if (hasCandidates && key == keys.RIGHT) {
        return actions.nextCandidate;
    } else if (hasCandidates && key == keys.SPACE) {
        return actions.commitCandidate;
    } else if (composing && key == keys.BACKSPACE) {
        return actions.composeDelete;
    } else {
        return actions.default;
    }
}


function refreshCandidates(inputState, dict) {
    let {syllables} = parseRaw(inputState.rawInput);
    let previous = inputState.candidates;
    let next = dict[syllables.join(' ')] || [];
    inputState.candidates = next;
    if (previous.join(',') != next.join(',')) {
        inputState.selection = newSelection();
    }
}


export function handleKeyEvent(inputState, e, dict) {
    let key = keys.normalizedKey(e);
    let action = nextAction(inputState, key);
    let ret = action(inputState, key);
    refreshCandidates(inputState, dict);
    return ret;

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
    // (Doing this first is necessary because the whole candidates element it re-rendered
    // on every event loop)
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


export function render(inputState, view, caretRect) {
    let candidateMarkup = inputState.candidates.map((c, i) =>
        `<div class="tbcandidate ${i == inputState.selection.selected ? 'selected' : ''}">${c}</div>`
    ).join('');
    let {syllables, remainder} = parseRaw(inputState.rawInput);
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