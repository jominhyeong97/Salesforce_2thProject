({
    closeQuickAction: function() {
        var closeAction = $A.get("e.force:closeQuickAction");
        if (closeAction) {
            closeAction.fire();
        }
    },

    showToast: function(variant, title, message) {
        var toast = $A.get("e.force:showToast");
        if (toast) {
            toast.setParams({
                message: message,
                title: title,
                type: variant
            });
            toast.fire();
        }
    },

    showErrorToast: function(error) {
        var message = "연락처를 생성하지 못했습니다.";

        if (error && error.message) {
            message = error.message;
        } else if (
            error &&
            error.output &&
            error.output.errors &&
            error.output.errors.length
        ) {
            message = error.output.errors[0].message;
        } else if (
            error &&
            error.output &&
            error.output.fieldErrors
        ) {
            var fieldNames = Object.keys(error.output.fieldErrors);
            if (fieldNames.length && error.output.fieldErrors[fieldNames[0]].length) {
                message = error.output.fieldErrors[fieldNames[0]][0].message;
            }
        }

        this.showToast("error", "연락처 생성 실패", message);
    }
})
