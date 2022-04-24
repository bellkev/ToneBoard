import * as config from './config.js';

function setBadgeMode(mode) {
    let setBadge = (text, color) => {
        chrome.action.setBadgeBackgroundColor({color});
        chrome.action.setBadgeText({text});
    };
    switch (mode) {
        case config.modes.ON:
            setBadge('On', 'green');
            break;
        case config.modes.OFF:
            setBadge('Off', 'red');
            break;
        case config.modes.AUTO:
            setBadge('中', 'blue');
            break;
    }
}

function loadBadgeMode() {
    config.getMode(setBadgeMode);
}

// Unclear from docs, but seems we can count on this running when extension is enabled
// Relevant: https://stackoverflow.com/questions/13979781/chrome-extension-how-to-handle-disable-and-enable-event-from-browser
config.onModeChange(setBadgeMode);
chrome.runtime.onStartup.addListener(loadBadgeMode);
chrome.runtime.onInstalled.addListener(loadBadgeMode);
