import * as config from './config.js';

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
    config.getMode(setBadgeMode);
}

// This is all storage is used for now, so just listening for any change
chrome.storage.onChanged.addListener(loadBadgeMode);
chrome.runtime.onStartup.addListener(loadBadgeMode);
chrome.runtime.onInstalled.addListener(loadBadgeMode);
// Unclear from docs, but seems we can count on this running when extension is enabled
// Relevant: https://stackoverflow.com/questions/13979781/chrome-extension-how-to-handle-disable-and-enable-event-from-browser
loadBadgeMode();