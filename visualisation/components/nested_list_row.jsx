import preact from 'preact';

export default class NestedListRow extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            unrolled: false
        };

        this.toggleRollOut = this.toggleRollOut.bind(this);
    }

    render ({app, content, level, nested_rows}, {unrolled}) {
        return <li>
            <div onClick={this.toggleRollOut} className="nested-list-content">
                {nested_rows && <span className="icon">
                    {unrolled ? '\u25B6' : '\u25BC'}
                    </span>
                }
                <span className="content">{content}</span>
            </div>
            {unrolled && nested_rows && <ul className="nested-list">{
                nested_rows.map(row =>
                    <NestedListRow
                        app={app}
                        content={row.content}
                        nested_rows={row.nested_rows}
                        level={level + 1}/>
                )
            }</ul>}
        </li>;
    }

    toggleRollOut () {
        this.setState({unrolled: !this.state.unrolled});
    }

}

