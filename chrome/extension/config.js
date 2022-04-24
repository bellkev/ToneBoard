export const modes = {
    ON: 'on',
    OFF: 'off',
    AUTO: 'auto'
}

export function setMode(mode) {
    chrome.storage.local.set({mode});
}

export function getMode(f) {
    chrome.storage.local.get(['mode'], function(result) {
        f(result.mode || modes.AUTO);
    });
}

export function onModeChange(f) {
    // Fire the callback immediately and on change
    getMode(f);
    chrome.storage.onChanged.addListener((changes, area) => {
        if (area == 'local' && changes.mode) {
            f(changes.mode.newValue);
        }
    });
}