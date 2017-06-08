
const init_state = {
    loaded: false
};

function admissionApp (state, action) {
    if (state === undefined) { return init_state; }

    switch (action.type) {
        case 'APP_READY':
            return Object.assign({}, state, {
                loaded: true
            });
            break;

        default:
            return state;
            break;

    }
}

export default admissionApp;