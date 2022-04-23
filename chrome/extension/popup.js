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

function init() {
    config.getMode(initRadios);
}

window.addEventListener('DOMContentLoaded', init);