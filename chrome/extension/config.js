export function setMode(mode) {
    chrome.storage.local.set({mode});
}

export function getMode(f) {
    chrome.storage.local.get(['mode'], function(result) {
        f(result.mode || 'auto');
    });
}