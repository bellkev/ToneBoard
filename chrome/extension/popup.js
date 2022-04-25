import * as config from './config.js';

function initRadios(mode) {
    let els = document.getElementsByTagName('input');
    for (let el of els) {
        el.checked = el.value == mode;
        el.addEventListener('change', (e) => {
            config.setMode(e.target.value);
        });
    }
}

function initLinks() {
    // Make links actually open in a new tab
    let links = document.getElementsByTagName('A');
    for (let link of links) {
        link.addEventListener('click', (e) => {
            chrome.tabs.create({active: true, url: e.target.href});
        })
    }
}

function init() {
    config.getMode(initRadios);
    initLinks();
}

window.addEventListener('DOMContentLoaded', init);