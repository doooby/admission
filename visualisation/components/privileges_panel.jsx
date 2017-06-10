import preact from 'preact';
import PrivilegeSelect from './privilege_select';
import PrivilegeInheritance from './privilege_inheritance';

export default class PrivilegesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            privilege_key: ''
        };

        this.onPrivilegeSelected = this.onPrivilegeSelected.bind(this);
    }

    render ({app}, {privilege_key}) {
        return <div className="panel">
            <PrivilegeSelect
                app={app}
                defaultValue={privilege_key}
                onChanged={this.onPrivilegeSelected}/>

            <div className="inheritance-list">
                <PrivilegeInheritance
                    app={app}
                    privilege={privilege_key ? app.getPrivilegeData(privilege_key) : null}
                    level={0}/>
            </div>
        </div>;
    }

    onPrivilegeSelected (privilege) {
        this.setState({privilege_key: this.props.app.privilegeToKey(privilege)});
    }

}