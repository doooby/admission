import './style.scss';
import 'whatwg-fetch';

import preact from 'preact';
import { createStore } from 'redux';
import admissionApp from './reducers';
import actions from './actions';
import AppContainer from './components/app_container';

document.addEventListener('DOMContentLoaded',function(){

    const app = {
        store: createStore(admissionApp),
        container: document.getElementById('admission-visualisation')
    };
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