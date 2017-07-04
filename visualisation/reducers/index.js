
const init_state = {
    loaded: false
};

function admissionApp (state, action) {
    if (state === undefined) { return init_state; }

    if (!state.loaded) {
        if (action.type === 'APP_READY') {
            return Object.assign({}, state, {
                loaded: true,
                panel: 'rules'
            });
        }

        return state;
    }

    switch (action.type) {

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