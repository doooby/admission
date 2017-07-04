import preact from 'preact';
import InputWithSelect from './input_with_select';
import NestedListRow from './nested_list_row';

export default class RulesPanel extends preact.Component {

    constructor (props) {
        super(props);

        this.onScopeSelected = this.onScopeSelected.bind(this);
        this.onActionSelected = this.onActionSelected.bind(this);
    }

    render ({app}, {scope, action}) {
        const rules = filter_index_for_scope(app.admission.rules, scope);
        const scopes = reduce_scopes(rules, {action});

        return <div className="panel">
            <div className="controls-group">
                <InputWithSelect
                    defaultText={scope}
                    placeholder="scope"
                    enterable
                    all_items={Object.keys(rules)}
                    onSelect={this.onScopeSelected}
                />

                <InputWithSelect
                    defaultText={action}
                    placeholder="action"
                    enterable
                    all_items={list_actions(rules)}
                    onSelect={this.onActionSelected}
                />
            </div>

            <br/>

            <ul className="nested-list">
                {scopes.map(scope =>
                    <NestedListRow
                        app={app}
                        content={scope.content}
                        nested_rows={scope.nested_rows}
                        level={0}/>
                )}
            </ul>
        </div>;
    }

    onScopeSelected (scope) {
        this.setState({scope});
    }

    onActionSelected (action) {
        this.setState({action});
    }

}

function filter_index_for_scope (rules, scope) {
    if (!scope) return rules;
    const filtered = Object.assign({}, rules);
    Object.keys(filtered).forEach(key => {
        if (!key.includes(scope)) delete filtered[key]
    });
    return filtered;
}

function reduce_scopes (index, {action}) {
    return Object.keys(index).map(scope => {
        return {
            content: scope,
            nested_rows: reduce_actions(index[scope], {action})
        };
    });
}

function reduce_actions (index, {action}) {
    let selected = Object.keys(index);
    if (action) selected = selected.filter(a => a.includes(action));

    return selected.map(action => {
        return {
            content: action,
            nested_rows: reduce_privileges(index[action])
        }
    });
}

function reduce_privileges (index) {
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