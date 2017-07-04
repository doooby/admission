import 'normalize.css';
import './style.scss';
import 'whatwg-fetch';

import preact from 'preact';
import { createStore } from 'redux';
import admissionApp from './reducers';
import actions from './actions';
import AppContainer from './components/app_container';

document.addEventListener('DOMContentLoaded',function(){

    app.store = createStore(admissionApp);
    app.container = document.getElementById('admission-visualisation');
    window.app = app;

    preact.render(
        <AppContainer
            ref={c => app.container_component = c}
            app={app}
            onMounted={start_app}/>,
        app.container
    );

    function start_app () {
        fetch(app.container.dataset.url, {
            credentials: 'include'

        }).then(response => {
            if (!response.ok) {
                app.container_component.setState({loaded: true, load_fail: response.statusText});
                return;
            }

            response.json().then(data => {
                app.admission = data;
                app.store.dispatch({type: 'APP_READY'});

            }).catch(err => {
                app.container_component.setState({loaded: true, load_fail: err.message});

            });

        }).catch(err => {
            app.container_component.setState({loaded: true, load_fail: err.message});

        });
    }

});

const app = {

    getPrivilegeData (key) {
        const {name, level} = app.keyToPrivilege(key);
        return this.admission.privileges
            .find(p => p.name === name && p.level === level);
    },

    listPrivilegesNames () {
        return this.admission.privileges
            .map(p => p.name)
            .filter((name, i, arr) => {
                return i === arr.indexOf(name);
            });
    },

    listPrivilegeLevels (name) {
        if (!name) return [];
        return this.admission.privileges
            .filter(p => p.name === name)
            .map(p => p.level);
    },

    privilegeToKey: function ({name, level}) {
        if (!level || level === 'base') return name || '';
        return `${name}-${level}`
    },

    keyToPrivilege (key) {
        if (!key) return {name: '', level: ''};
        let [name, level] = key.split('-');
        if (!level) level = 'base';
        return {name, level};
    },



};