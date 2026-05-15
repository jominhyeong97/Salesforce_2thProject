({
    handleInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        if (recordId) {
            component.set("v.accountId", recordId);
        }
    },

    handleCancel: function(component, event, helper) {
        helper.closeQuickAction();
    },

    handleSave: function(component, event, helper) {
        if (component.get("v.isSaving")) {
            return;
        }

        var fullNameInput = component.find("fullNameInput");
        if (!fullNameInput.checkValidity()) {
            fullNameInput.reportValidity();
            return;
        }

        var fullName = (component.get("v.fullName") || "").trim();
        if (!fullName) {
            fullNameInput.reportValidity();
            return;
        }

        component.set("v.isSaving", true);
        component.find("contactForm").submit();
    },

    handleSubmit: function(component, event, helper) {
        event.preventDefault();

        var fields = event.getParam("fields");
        fields.FirstName = "";
        fields.LastName = (component.get("v.fullName") || "").trim();

        var accountId = component.get("v.accountId");
        if (accountId && !fields.AccountId) {
            fields.AccountId = accountId;
        }

        component.find("contactForm").submit(fields);
    },

    handleSuccess: function(component, event, helper) {
        component.set("v.isSaving", false);
        helper.showToast("success", "연락처 생성 완료", "연락처가 저장되었습니다.");
        helper.closeQuickAction();

        var refreshView = $A.get("e.force:refreshView");
        if (refreshView) {
            refreshView.fire();
        }
    },

    handleError: function(component, event, helper) {
        component.set("v.isSaving", false);
        helper.showErrorToast(event.getParam("error"));
    }
})
