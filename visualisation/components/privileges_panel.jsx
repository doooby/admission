import preact from 'preact';
import PrivilegeSelect from './privilege_select';
import NestedListRow from './nested_list_row';

export default class PrivilegesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            privilege_key: ''
        };

        this.onPrivilegeSelected = this.onPrivilegeSelected.bind(this);
    }

    render ({app}, {privilege_key}) {
        const root_row = reduce_nested_data(app, {key: privilege_key});

        return <div className="panel">
            <PrivilegeSelect
                app={app}
                defaultValue={privilege_key}
                onChanged={this.onPrivilegeSelected}/>

            <br/>

            <ul className="nested-list">
                <NestedListRow
                app={app}
                content={root_row.content}
                nested_rows={root_row.nested_rows}
                level={0}/>
            </ul>
        </div>;
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