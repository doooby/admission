import preact from 'preact';
import InputWithSelect from './input_with_select';

export default class PrivilegeSelect extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            name: '',
            level: ''
        };

        this.onNameSelected = this.onNameSelected.bind(this);
        this.onLevelSelected = this.onLevelSelected.bind(this);
    }

    render ({app}, {name, level}) {
        return <div className="controls-row">
            <InputWithSelect
                app={app}
                defaultText={name}
                placeholder="name"
                all_items={app.listPrivilegesNames()}
                onSelect={this.onNameSelected}
            />

            <InputWithSelect
                app={app}
                defaultText={level}
                placeholder="level"
                all_items={app.listPrivilegeLevels(name)}
                onSelect={this.onLevelSelected}
            />
        </div>;
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

}