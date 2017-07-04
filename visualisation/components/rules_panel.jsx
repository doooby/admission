import preact from 'preact';
import InputWithSelect from './input_with_select';
import NestedListRow from './nested_list_row';

export default class RulesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            // rules_list: reduce_rules_to_list(props.app.admission.rules)
        };

        this.onActionSelected = this.onActionSelected.bind(this);
    }

    render ({app}, {action}) {
        const rules = {'non-scoped': app.admission.rules};
        const scopes = reduce_scopes(app, rules, {action});

        return <div className="panel">
            <div className="controls-group">
                <InputWithSelect
                    defaultText={action}
                    placeholder="action"
                    all_items={list_actions(rules)}
                    onSelect={this.onActionSelected}
                />
            </div>

            <br/>

            <div className="nested-list">
                {scopes.map(scope =>
                    <NestedListRow
                        app={app}
                        content={scope.content}
                        nested_rows={scope.nested_rows}
                        level={0}/>
                )}
            </div>
        </div>;
    }

    onActionSelected (action) {
        this.setState({action});
    }

}

function reduce_scopes (app, index, {action}) {
    return Object.keys(index).map(scope => {
        return {
            content: scope,
            nested_rows: reduce_actions(app, index[scope], {action})
        };
    });
}

function reduce_actions (app, index, {action}) {
    if (action) {
        const action_index = index[action];
        if (!action_index) return;
        return [{
            content: action,
            nested_rows: reduce_privileges(app, action_index)
        }];
    }

    return Object.keys(index).map(action => {
        return {
            content: action,
            nested_rows: reduce_privileges(app, index[action])
        }
    });
}

function reduce_privileges (app, index) {
    return Object.keys(index).map(privilege_key => {
        return {
            content: `${privilege_key}: ${index[privilege_key]}`
        };
    });
}

function list_actions (index) {
    let all = [];
    Object.keys(index).forEach(k => all = all.concat(Object.keys(index[k])));
    return all.filter((name, i, arr) => {
        return i === arr.indexOf(name);
    });
}