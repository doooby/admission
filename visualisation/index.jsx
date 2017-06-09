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

    listPrivilegesNames: function () {
        return this.admission.privileges
            .map(p => p.name)
            .filter((name, i, arr) => {
                return i === arr.indexOf(name);
            });
    },

    listPrivilegeLevels: function (name) {
        if (!name) return [];
        return this.admission.privileges
            .filter(p => p.name === name)
            .map(p => p.level);
    },

    debounce: function (func, wait, immediate) {
        let timeout, context, args;

        if (immediate) {
            return function () {
                let call_now = true;
                context = this;
                args = arguments;

                if (timeout) {
                    call_now = false;
                    clearTimeout(timeout);
                }
                timeout = setTimeout(function () {
                    timeout = null;
                }, wait);
                if (call_now) func.apply(context, args);
            };

        } else {
            return function () {
                context = this;
                args = arguments;

                if (timeout) clearTimeout(timeout);

                timeout = setTimeout(function () {
                    timeout = null;
                    func.apply(context, args);
                }, wait);
            };
        }
    },

    throttle: function (callback, time, immediate) {
        let timeout, call_at_end, context, args;

        return function () {
            context = this;
            args = arguments;

            // throttling block
            if (timeout) {
                call_at_end = true;
                return;
            }

            // throttler - fire only if there was event in the mean-time
            let timeout_f = function () {
                timeout = null;
                if (call_at_end) {
                    call_at_end = false;
                    timeout = setTimeout(timeout_f, time);
                    callback.apply(context, args);
                }
            };

            call_at_end = true;
            if (immediate) timeout_f();
            else timeout = setTimeout(timeout_f, time);
        };
    }

};