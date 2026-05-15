({
    handleOpen: function(component, event, helper) {
        var navService = component.find("navService");
        navService.navigate({
            type: "standard__quickAction",
            attributes: {
                apiName: "Global.New_Lead_KR"
            }
        });
    }
})
