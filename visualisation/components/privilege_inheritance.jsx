import preact from 'preact';

export default class PrivilegeInheritance extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            unrolled: (!props.privilege && props.level === 0)
        };
    }

    render ({app, privilege, level}, {unrolled}) {
        let text = 'error', children, tabs=[];

        if (privilege) {
            text = `${privilege.name}-${privilege.level}`;
            children = privilege.inherits;

        } else if (level === 0) {
            text = '-root-';
            children = app.admission.top_levels;

        }
        if (children) children = find_privileges(app, children);

        for (let i=0; i<level; i+=1) tabs.push(<span className="tab">&nbsp;</span>);
        if (children) {
            tabs.push(<button
                className="button small tab"
                type="button"
                onClick={this.toggleRollOut.bind(this, !unrolled)}>
                {unrolled ? '\u21B0' : '\u21B3'}
            </button>);

        }
        else {
            tabs.push(<span className="tab"> &#8594;</span>);

        }

        return <div className="privilege-row">
            {tabs}
            <span className="name">{text}</span>
            {unrolled && children && children.map(p =>
                <PrivilegeInheritance
                    app={app}
                    privilege={p}
                    level={level + 1}/>
            )}
        </div>;
    }

    toggleRollOut (new_value) {
        this.setState({unrolled: new_value});
    }

}

function find_privileges (app, keys) {
    const privileges = [];
    keys.forEach(key => {
        const p = app.getPrivilegeData(key);
        if (p) privileges.push(p);
    });
    return privileges;
}