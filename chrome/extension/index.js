window.addEventListener('DOMContentLoaded', () => {
    // Need to dynamically import because content scripts don't have first-class module support
    import('./toneboard.js')
        .then((tb) => {
            tb.init();
        });
});