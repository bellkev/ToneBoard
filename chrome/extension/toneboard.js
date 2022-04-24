import { getCursorRect } from './cursor.js';
import * as config from './config.js';
import * as input from './input.js';


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


function handleEvent(e, appState, view, dict) {
    // TODO: Handle switching to different areas, focus events
    let el = e.target;
    if (!shouldHandleEvent(el, appState.mode)) {
        return;
    }
    let {newText, preventDefault} = input.handleKeyEvent(appState.input, e, dict);
    // Update DOM
    // TODO: actually insert at the cursor...
    if (newText) {
        el.value += newText;
    }
    if (preventDefault) {
        e.preventDefault();
        // Try to prevent actions that happen on enter (e.g. Duolingo answer submission).
        // This works in practice, but may need to do more to make this handler run first
        // provide an alternative to the enter key for committing rawInput
        e.stopImmediatePropagation();
        let inputEvent = new Event('input', {bubbles: true, cancelable: false});
        el.dispatchEvent(inputEvent);
    }
    input.render(appState.input, view, getCursorRect(el));
}


export function init() {
    const view = document.createElement('DIV');
    document.body.appendChild(view);
    const appState = {
        input: input.newState(),
        // This is the mode that will be in effect testing as a non-extension
        mode: config.modes.AUTO
    }
    const dict = {};
    let dictUrl;
    if (chrome.runtime) {
        dictUrl = chrome.runtime.getURL("dict.json");
        config.onModeChange((mode) => {
            appState.mode = mode;
        });
    } else {
        dictUrl = window.dictUrl;
    }
    fetch(dictUrl)
        .then(response => response.json())
        .then(data => {
            Object.assign(dict, data);
        });
    document.addEventListener('keydown', (e) => {handleEvent(e, appState, view, dict)});
}