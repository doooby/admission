import preact from 'preact';
import PrivilegeSelect from './privilege_select';

export default class PrivilegesPanel extends preact.Component {

    render ({app}) {

    console.log(app.admission);
        return <div className="panel">
            <PrivilegeSelect app={app} onChanged={val => console.log(val)}/>
        </div>;
    }

}