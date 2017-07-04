import preact from 'preact';
import PrivilegesPanel from './privileges_panel';
import classnames from 'classnames';
import RulesPanel from "./rules_panel";

export default class AppContainer extends preact.Component {

    constructor (props) {
        super(props);

        this.switchToPrivileges = this.changePanel.bind(this, 'privileges');
        this.switchToRules = this.changePanel.bind(this, 'rules');
    }

    render ({app}, {loaded, load_fail, panel}) {
        if (!loaded) return <div className="splash-message">
            <code>... loading admission data ...</code>
        </div>;

        if (load_fail) return <div className="splash-message">
            <h4>failed to load admission data</h4>
            <code>{load_fail}</code>
        </div>;

        return <div className="admission-app-container">
            <ul className="panels-list">

                <li
                    onClick={this.switchToPrivileges}
                    className={classnames({'active': panel === 'privileges'})}>
                    Privileges Order
                </li>

                <li
                    onClick={this.switchToRules}
                    className={classnames({'active': panel === 'rules'})}>
                    Rules Listing
                </li>

            </ul>

            {this.renderPanel()}
        </div>;
    }

    componentDidMount () {
        const store = this.props.app.store;

        this.store_unsibscribe = store.subscribe(() => {
            const state = store.getState();
            this.setState({loaded: state.loaded, panel: state.panel});
        });

        setTimeout(this.props.onMounted, 0);
    }

    componentWillUnmount () {
        this.store_unsibscribe();
    }

    changePanel(panel) {
        this.props.app.store.dispatch({type: 'PANEL_CHANGE', panel: panel});
    }

    renderPanel () {
        const app = this.props.app;
        switch (this.state.panel) {
            case 'privileges':
                return <PrivilegesPanel app={app} />;
                break;

        }
    }
}