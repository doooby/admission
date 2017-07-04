import preact from 'preact';
import NestedListRow from './nested_list_row';

export default class RulesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            rules_list: reduce_rules_to_list(props.app.admission.rules)
        };

        // this.onPrivilegeSelected = this.onPrivilegeSelected.bind(this);
    }

    render ({app}, {rules_list}) {
        return <div className="panel">


            <div className="nested-list">
                {rules_list && rules_list.map(([request_name, request_rules]) =>
                    <NestedListRow
                        app={app}
                        text={request_name}
                        nestedRows={request_rules}
                        level={0}/>
                )}
            </div>

        </div>;
    }

}

function reduce_rules_to_list (rules_index, request_beginning=null, privilege_key=null) {
    return Object.keys(rules_index)
        .map(request_name => {
            if (request_beginning && !request_name.startsWith(request_beginning)) return null;

            const privileges_list = reduce_req_rules_to_list(rules_index[request_name], privilege_key);
            return [request_name, privileges_list];
        })
        .filter(item => item !== null);
}

function reduce_req_rules_to_list (request_index, privilege_key) {
    return Object.keys(request_index)
        .map(privilege => {
            if (privilege_key && privilege_key !== privilege) return;

            return `${privilege} ${request_index[privilege]}`;
            // return [privilege, request_index[privilege]];
        })
        .filter(item => item !== null);
}