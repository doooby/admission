import preact from 'preact';

export default class NestedListRow extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            unrolled: !!props.defaultUnrolled
        };

        this.toggleRollOut = this.toggleRollOut.bind(this);
    }

    render ({app, content, nestedRows}, {unrolled}) {
        return <li>
            <div onClick={this.toggleRollOut} className="nested-list-content">
                {nestedRows && <span className="icon">
                    {unrolled ? '\u25B6' : '\u25BC'}
                    </span>
                }
                <span className="content">{content}</span>
            </div>
            {unrolled && nestedRows && <ul className="nested-list">{
                nestedRows.map(row =>
                    <NestedListRow
                        app={app}
                        content={row.content}
                        nestedRows={row.nested_rows}
                        defaultUnrolled={this.props.defaultUnrolled}
                        />
                )
            }</ul>}
        </li>;
    }

    componentWillReceiveProps ({defaultUnrolled}) {
        if (defaultUnrolled !== this.props.defaultUnrolled) {
            this.setState({unrolled: !!defaultUnrolled});
        }
    }

    toggleRollOut () {
        this.setState({unrolled: !this.state.unrolled});
    }

}

