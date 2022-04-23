'use strict';

function initRadios(mode) {
    let els = document.getElementsByTagName('input');
    for (let el of els) {
        el.checked = el.value == mode;
        el.addEventListener('change', (e) => {
            chrome.storage.local.set({mode: e.target.value});
        });
    }
}

function init() {
    chrome.storage.local.get(['mode'], function(result) {
        initRadios(result.mode || 'auto');
        });
}

window.addEventListener('DOMContentLoaded', init);