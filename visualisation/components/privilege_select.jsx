import preact from 'preact';
import InputWithSelect from './input_with_select';

export default class PrivilegeSelect extends preact.Component {

    constructor (props) {
        super(props);

        this.state = props.app.keyToPrivilege(props.defaultValue);

        this.onNameSelected = this.onNameSelected.bind(this);
        this.onLevelSelected = this.onLevelSelected.bind(this);
        this.onClearSelection = this.onClearSelection.bind(this);
    }

    render ({app}, {name, level}) {
        return <div className="controls-group">
            <InputWithSelect
                defaultText={name}
                placeholder="name"
                all_items={app.listPrivilegesNames()}
                onSelect={this.onNameSelected}
            />

            <InputWithSelect
                defaultText={level}
                placeholder="level"
                all_items={app.listPrivilegeLevels(name)}
                onSelect={this.onLevelSelected}
            />

            <button
                type="button"
                tabIndex="-1"
                className="button"
                onClick={this.onClearSelection}>
                Clear
            </button>
        </div>;
    }

    componentWillReceiveProps (new_props) {
        if (new_props.defaultValue !== this.props.defaultValue) {
            this.setState(this.props.app.keyToPrivilege(new_props.defaultValue));
        }
    }


    onNameSelected (name) {
        let level = this.state.level;
        if (level !== 'base') level = 'base';
        this.setState({name, level});
        this.props.onChanged({name, level});
    }

    onLevelSelected (level) {
        const name = this.state.name;
        this.setState({level});
        this.props.onChanged({name, level});
    }

    onClearSelection () {
        const selection = {name: '', level: ''};
        this.setState(selection);
        this.props.onChanged(selection);
    }

}