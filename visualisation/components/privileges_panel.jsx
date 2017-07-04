import preact from 'preact';
import classnames from 'classnames';
import PrivilegeSelect from './privilege_select';
import NestedListRow from './nested_list_row';

export default class PrivilegesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            roll_down_all: true,
            privilege_key: ''
        };

        this.onToggleRollDownAll = this.onToggleRollDownAll.bind(this);
        this.onPrivilegeSelected = this.onPrivilegeSelected.bind(this);
    }

    render ({app}, {privilege_key, roll_down_all}) {
        const root_row = reduce_nested_data(app, {key: privilege_key});

        return <div className="panel">
            <div className="controls">
                <div className="controls-group">
                    <div className={classnames('check_box', roll_down_all && 'checked')}
                         onClick={this.onToggleRollDownAll}>
                        {"\u25BC"}
                    </div>
                </div>

                <PrivilegeSelect
                    app={app}
                    defaultValue={privilege_key}
                    onChanged={this.onPrivilegeSelected}/>
            </div>

            <ul className="nested-list">
                <NestedListRow
                app={app}
                content={root_row.content}
                nestedRows={root_row.nested_rows}
                defaultUnrolled={roll_down_all}/>
            </ul>
        </div>;
    }

    onToggleRollDownAll () {
        this.setState({roll_down_all: !this.state.roll_down_all});
    }

    onPrivilegeSelected (privilege) {
        this.setState({privilege_key: this.props.app.privilegeToKey(privilege)});
    }

}

function reduce_nested_data (app, {privilege, key}) {
    if (!privilege && key) privilege = app.getPrivilegeData(key);
    let nested;

    if (!privilege) {
        nested = app.admission.top_levels;
    } else if (privilege.inherits) {
        nested = privilege.inherits;
    }
    if (nested) nested = nested.map(p => reduce_nested_data(app, {key: p}));

    return {
        content: (privilege ? app.privilegeToKey(privilege) : '-listing-'),
        nested_rows: nested
    };
}