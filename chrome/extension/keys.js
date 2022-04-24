export const LEFT = 'LEFT';
export const RIGHT = 'RIGHT';
export const ENTER = 'ENTER';
export const SPACE = 'SPACE';
export const BACKSPACE = 'BACKSPACE';
export const SHIFT = 'SHIFT';
export const OTHER = 'OTHER';


export function normalizedKey(e) {
    // Return a "key" value similar to e.key
    // but normalized to allow arrow keys and Tab to have the same function,
    // to discard modified keys, etc
    let modifiers = ["Alt", "AltGraph", "Control", "Meta", "OS"];
    if (modifiers.some((m) => e.getModifierState(m))) {
        return OTHER;
    }
    if (e.key == 'Shift') {
        return SHIFT;
    }
    if (e.key == 'Tab' && e.getModifierState('Shift')) {
        return LEFT;
    }
    if (e.key == 'Tab') {
        return RIGHT;
    }
    if (e.key == 'Backspace') {
        return BACKSPACE;
    }
    if (e.key == ' ') {
        return SPACE;
    }
    if (e.key == 'Enter') {
        return ENTER;
    }
    return e.key;
}