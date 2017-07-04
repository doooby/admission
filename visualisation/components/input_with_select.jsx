import preact from 'preact';
import classnames from 'classnames';
import helpers from '../helpers';

export default class InputWithSelect extends preact.Component {

    constructor (props) {
        super(props);

        this.state = {
            text: props.defaultText || '',
            matching: null,
        };

        this.setParentRef = ref => this.element = ref;
        this.setListRef = ref => this.list = ref;
        this.onKeyDown = this.onKeyDown.bind(this);
        this.onTextChange = helpers.debounce(this.onTextChange.bind(this), 400);
        this.toggleList = helpers.debounce(this.toggleList.bind(this), 400, true);
        this.closeList = this.closeList.bind(this);
        this.onSelected = this.onSelected.bind(this);
    }

    render ({placeholder}, {text, matching}) {
        if (!matching) this.list = null;

        return <div
            ref={this.setParentRef}
            className="controls-select">

            <div className="_inputs">
                <input
                    type="text"
                    className="input_text"
                    placeholder={placeholder}
                    onKeyDown={this.onKeyDown}
                    value={text}/>

                <button
                    type="button"
                    tabIndex="-1"
                    className="button"
                    onClick={this.toggleList}>
                    &#8964;
                </button>
            </div>

            {matching && <DropdownList
                ref={this.setListRef}
                items={matching}
                toSelect={this.onSelected}
                toClose={this.closeList}
            />}

        </div>;
    }

    componentDidMount () {
        this._outside_click_listener = e => {
            if (!this.element.contains(e.target) && this.list) {
                this.closeList();
            }
        };
        document.addEventListener('click', this._outside_click_listener);
    }

    componentWillUnmount () {
        document.removeEventListener('click', this._outside_click_listener);
    }

    componentWillReceiveProps (new_props) {
        if (new_props.defaultText !== this.props.defaultText) this.setState({text: new_props.defaultText});
    }

    onKeyDown (e) {
        if (this.list && this.list.onKeyDown(e)) return;
        if (e.keyCode === 13 && this.props.enterable) {
            this.onSelected(e.target.value.trim());
            return;
        }
        this.onTextChange(e);
    }

    onTextChange (e) {
        const text = e.target.value.trim();
        let matching = null;
        if ((text && text !==this.state.text) || e.keyCode === 40) {
            matching = filter_items(this.props.all_items, text);
        }
        this.setState({matching, text});
    }

    toggleList () {
        if (this.list) {
            this.closeList();

        } else {
            this.setState({matching: this.props.all_items});
        }
    }

    closeList () {
        this.setState({matching: null});
    }

    onSelected (value) {
        this.setState({text: value, matching: null});
        this.props.onSelect(value);
    }

}

class DropdownList extends preact.Component {

    constructor (props) {
        super(props);
        this.state = {selected: -1};
    }

    render ({items, toSelect}, {selected}) {
        return <div
            className="_dropdown">
            <ul>
                {items.map((name, i) => <li
                    className={classnames({'selected': selected === i})}
                    onClick={() => toSelect(name)}>
                    {name}
                </li>)}
            </ul>
        </div>;
    }

    onKeyDown (e) {
        switch (e.keyCode) {
            case 40: // down
                this.changeSelection(1);
                return true;
                break;

            case 38: // up
                this.changeSelection(-1);
                return true;
                break;

            case 13: // enter
                const selected = this.state.selected;
                if (selected !== -1) {
                    this.props.toSelect(this.props.items[selected]);
                    return true;
                }
                break;

            case 27: // escape
                this.props.toClose();
                return true;
                break;

        }
        return false;
    }

    changeSelection (value) {
        let selected = this.state.selected;
        selected += value;
        if (selected < 0) selected = 0;
        if (selected >= this.props.items.length) selected = this.props.items.length -1;
        this.setState({selected});
    }
}

function filter_items (all, input_text) {
    let items = all.filter(value => value.startsWith(input_text));
    if (items.length === 0) items = null;
    return items;
}