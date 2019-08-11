$(function() {
    $(".tenbou").focusout(function() {
        let sum = __sum();
        if (__validateTenbo(sum)) {
            __hideMessage();
            return false;
        } else {
            __showMessage(sum);
        }

        /**
         *
         * @param {Integer}
         * @return {boolean}
         * @private
         */
        function __validateTenbo(point) {
            return point === 100000;
        }

        /**
         *
         * @return {number}
         * @private
         */
        function __sum() {
            let val = 0;
            $('.tenbou').each(function(ind, elm) {
                val += parseInt($(elm).val());
            });
            return val;
        }

        /**
         *
         * @private
         */
        function __hideMessage() {
            $('#point-validate-message').hide();
        }
        /**
         *
         * @param {Integer}
         * @private
         */
        function __showMessage(point) {
            $("#point-validate-alert-message").text("合計点棒が" + point + "です。" + (100000 - point) + "合いません。")
            $('#point-validate-message').show();
        }
    });
});