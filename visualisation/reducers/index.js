
const init_state = {
    loaded: false
};

function admissionApp (state, action) {
    if (state === undefined) { return init_state; }

    switch (action.type) {
        case 'APP_READY':
            return Object.assign({}, state, {
                loaded: true,
                panel: 'privileges'
            });
            break;

        case 'PANEL_CHANGE':
            return Object.assign({}, state, {
                panel: action.panel
            });
            break;

        default:
            return state;
            break;

    }
}

export default admissionApp;