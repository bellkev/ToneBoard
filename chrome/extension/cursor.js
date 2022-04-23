const TEXT_ATTRS = ['font-family', 'font-size', 'font-weight',
'font-style', 'text-transform', 'text-decoration', 'letter-spacing',
'word-spacing', 'line-height', 'text-align', 'vertical-align', 'margin',
'padding', 'border-width', 'border-style', 'overflow', 'overflow-wrap'];

export function getCursorRect(el) {
    // TODO: Handle an <input> element that overflows...
    let cursorLocation = el.selectionStart;
    let dummy = document.createElement('PRE');
    let dummyCursor = document.createElement('SPAN');
    dummyCursor.innerHTML = '&ZeroWidthSpace;'
    let cssText = TEXT_ATTRS.map((a)=>`${a}:${getComputedStyle(el)[a]}`).join(';');
    let rect = el.getBoundingClientRect();
    // Note: <input> seems to always behave like white-space: pre-wrap, so hardcoding that rather than copying
    cssText = `${cssText};
               left:${rect.left}px; right:${window.innerWidth - rect.right}px;
               top:${rect.top}px; bottom:${window.innerHeight - rect.bottom}px;
               position: fixed; visibility: hidden; white-space: pre-wrap;`;
    dummy.style.cssText = cssText;
    let before = el.value.slice(0, cursorLocation);
    dummy.innerHTML = before;
    dummy.appendChild(dummyCursor);
    document.body.appendChild(dummy);
    dummy.scrollTop = el.scrollTop;
    dummy.scrollLeft = el.scrollLeft;
    let ret = dummyCursor.getBoundingClientRect();
    document.body.removeChild(dummy);
    return ret;
}