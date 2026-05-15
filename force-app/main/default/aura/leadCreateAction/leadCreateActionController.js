({
    handleInit: function(component, event, helper) {
        helper.registerPostcodeListener(component);
    },

    handleCancel: function(component, event, helper) {
        helper.closeQuickAction(component);
    },

    handleAddressSearch: function(component, event, helper) {
        helper.openPostcodePopup(component);
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

        var fullName = (fullNameInput.get("v.value") || component.get("v.fullName") || "").trim();
        if (!fullName) {
            fullNameInput.reportValidity();
            return;
        }

        var leadKind = component.get("v.leadKind");
        var companyValue = "";
        if (leadKind === "personal") {
            companyValue = helper.buildPersonalCompanyName(fullName);
        } else {
            var companyInput = component.find("companyInput");
            if (!companyInput.checkValidity()) {
                companyInput.reportValidity();
                return;
            }

            companyValue = (component.get("v.companyName") || "").trim();
            if (!companyValue) {
                companyInput.reportValidity();
                return;
            }
        }

        var street = helper.buildStreetValue(
            component.get("v.baseAddress"),
            component.get("v.extraAddress"),
            component.get("v.detailAddress")
        );

        component.find("lastNameField").set("v.value", fullName);
        component.find("firstNameField").set("v.value", "");
        component.find("companyField").set("v.value", companyValue);
        component.find("statusField").set("v.value", "Inbound_Received");
        component.find("leadSourceField").set("v.value", "Web");
        component.find("streetField").set("v.value", street);
        component.find("postalCodeField").set("v.value", component.get("v.postalCode") || "");
        component.find("stateField").set("v.value", component.get("v.addressRegion") || "");
        component.find("cityField").set("v.value", component.get("v.addressCity") || "");
        component.find("countryField").set("v.value", component.get("v.addressCountry") || "대한민국");

        component.set("v.isSaving", true);
        component.find("leadForm").submit();
    },

    handleSubmit: function(component, event, helper) {
        if (!component.get("v.isSaving")) {
            event.preventDefault();
        }
    },

    handleSuccess: function(component, event, helper) {
        component.set("v.isSaving", false);
        helper.showToast("success", "리드 생성 완료", "리드가 저장되었습니다.");
        helper.closeQuickAction(component);
        helper.navigateToRecord(event.getParam("id"));
    },

    handleError: function(component, event, helper) {
        component.set("v.isSaving", false);
        helper.showErrorToast(event.getParam("error"), "리드를 생성하지 못했습니다.");
    }
})
