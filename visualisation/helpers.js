
const helpers = {

    debounce (func, wait, immediate) {
        let timeout, context, args;

        if (immediate) {
            return function () {
                let call_now = true;
                context = this;
                args = arguments;

                if (timeout) {
                    call_now = false;
                    clearTimeout(timeout);
                }
                timeout = setTimeout(function () {
                    timeout = null;
                }, wait);
                if (call_now) func.apply(context, args);
            };

        } else {
            return function () {
                context = this;
                args = arguments;

                if (timeout) clearTimeout(timeout);

                timeout = setTimeout(function () {
                    timeout = null;
                    func.apply(context, args);
                }, wait);
            };
        }
    },

    throttle (callback, time, immediate) {
        let timeout, call_at_end, context, args;

        return function () {
            context = this;
            args = arguments;

            // throttling block
            if (timeout) {
                call_at_end = true;
                return;
            }

            // throttler - fire only if there was event in the mean-time
            let timeout_f = function () {
                timeout = null;
                if (call_at_end) {
                    call_at_end = false;
                    timeout = setTimeout(timeout_f, time);
                    callback.apply(context, args);
                }
            };

            call_at_end = true;
            if (immediate) timeout_f();
            else timeout = setTimeout(timeout_f, time);
        };
    }

};

export default helpers;