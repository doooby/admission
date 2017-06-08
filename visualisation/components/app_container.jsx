import preact from 'preact';

export default class AppContainer extends preact.Component {

    render (_, {loaded, load_fail}) {
        if (!loaded) return <div className="splash-message">
            <code>... loading admission data ...</code>

        </div>;

        if (load_fail) {
            return <div className="splash-message">
                <h4>failed to load admission data</h4>
                <code>{load_fail}</code>
            </div>;
        }

        return <div>

        </div>;
    }

    componentDidMount () {
        const store = this.props.app.store;

        this.store_unsibscribe = store.subscribe(() => {
            const state = store.getState();
            this.setState({loaded: state.loaded});
        });

        setTimeout(this.props.onMounted, 0);
    }

    componentWillUnmount () {
        this.store_unsibscribe();
    }

}