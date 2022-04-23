'use strict';

function setBadgeMode(mode) {
    let setBadge = (text, color) => {
        chrome.action.setBadgeBackgroundColor({color});
        chrome.action.setBadgeText({text});
    };
    switch (mode) {
        case 'on':
            setBadge('On', 'green');
            break;
        case 'off':
            setBadge('Off', 'red');
            break;
        case 'auto':
            setBadge('中', 'blue');
            break;
    }
}

function loadBadgeMode() {
    chrome.storage.local.get(['mode'], function(result) {
        // TODO: Don't duplicate this...
        setBadgeMode(result.mode || 'auto');
        });
}

chrome.storage.onChanged.addListener((changes) => {
    if (!changes.mode) {
        return;
    }
    setBadgeMode(changes.mode.newValue);
});

chrome.runtime.onStartup.addListener(loadBadgeMode);
chrome.runtime.onInstalled.addListener(loadBadgeMode);
// Unclear from docs, but seems we can count on this running when extension is enabled
// Relevant: https://stackoverflow.com/questions/13979781/chrome-extension-how-to-handle-disable-and-enable-event-from-browser
loadBadgeMode();