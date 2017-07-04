import preact from 'preact';

export default class NestedListRow extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            unrolled: false
        };
    }

    render ({app, content, level, nested_rows}, {unrolled}) {
        let tabs=[];

        for (let i=0; i<level; i+=1) tabs.push(<span className="list-row-tab">&nbsp;</span>);
        if (nested_rows) {
            tabs.push(<button
                className="button small list-row-tab"
                type="button"
                onClick={this.toggleRollOut.bind(this, !unrolled)}>
                {unrolled ? '\u21B0' : '\u21B3'}
            </button>);

        }
        else {
            tabs.push(<span className="list-row-tab"> &#8594;</span>);

        }

        return <div className="nested-list-row">
            {tabs}
            <span className="list-row-content">{content}</span>
            {unrolled && nested_rows && nested_rows.map(row =>
                <NestedListRow
                    app={app}
                    content={row.content}
                    nested_rows={row.nested_rows}
                    level={level + 1}/>
            )}
        </div>;
    }

    toggleRollOut (new_value) {
        this.setState({unrolled: new_value});
    }

}

