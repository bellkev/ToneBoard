window.addEventListener('DOMContentLoaded', () => {
    import('./toneboard.js')
        .then((tb) => {
            tb.init();
        });
});