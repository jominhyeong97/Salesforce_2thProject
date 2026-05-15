({
    POSTCODE_MESSAGE_TYPE: "KAKAO_POSTCODE_SELECTED",
    PERSONAL_COMPANY_PREFIX: "(개인) ",

    closeQuickAction: function(component) {
        // pageReference is set when rendered as action override (URL-addressable page)
        // it is null/undefined when rendered as a quick action modal
        var pageRef = component && component.get("v.pageReference");
        if (pageRef) {
            var navEvent = $A.get("e.force:navigateToObjectHome");
            if (navEvent) {
                navEvent.setParams({ scope: "Lead" });
                navEvent.fire();
            }
        } else {
            var closeAction = $A.get("e.force:closeQuickAction");
            if (closeAction) {
                closeAction.fire();
            }
        }
    },

    navigateToRecord: function(recordId) {
        if (!recordId) {
            return;
        }

        var navigateEvent = $A.get("e.force:navigateToSObject");
        if (navigateEvent) {
            navigateEvent.setParams({
                recordId: recordId
            });
            navigateEvent.fire();
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

    showErrorToast: function(error, fallbackMessage) {
        var message = fallbackMessage || "요청을 처리하지 못했습니다.";

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

        this.showToast("error", "리드 생성 실패", message);
    },

    registerPostcodeListener: function(component) {
        if (component._postcodeListenerRegistered) {
            return;
        }

        var self = this;
        var messageHandler = $A.getCallback(function(event) {
            var payload = self.normalizePostcodePayload(event && event.data ? event.data : null);
            if (!payload || payload.type !== self.POSTCODE_MESSAGE_TYPE) {
                return;
            }

            var selectedAddress = self.resolveSelectedAddress(payload);
            component.set("v.postalCode", payload.zonecode || "");
            component.set("v.baseAddress", selectedAddress);
            component.set("v.extraAddress", payload.extraAddress || "");
            component.set("v.addressRegion", payload.region || "");
            component.set("v.addressCity", payload.city || "");
            component.set("v.addressCountry", payload.country || "대한민국");
            component.set("v.detailAddress", component.get("v.detailAddress") || "");

            window.setTimeout(
                $A.getCallback(function() {
                    var detailInput = component.find("detailAddressInput");
                    if (detailInput && detailInput.focus) {
                        detailInput.focus();
                    }
                }),
                0
            );
        });

        window.addEventListener("message", messageHandler);
        component._postcodeMessageHandler = messageHandler;
        component._postcodeListenerRegistered = true;
    },

    normalizePostcodePayload: function(rawPayload) {
        if (!rawPayload) {
            return null;
        }

        if (typeof rawPayload === "string") {
            try {
                return JSON.parse(rawPayload);
            } catch (error) {
                return null;
            }
        }

        return rawPayload;
    },

    resolveSelectedAddress: function(payload) {
        var primaryAddress =
            (payload && payload.address) ||
            (payload && payload.roadAddress) ||
            (payload && payload.jibunAddress) ||
            "";
        var extraAddress = payload && payload.extraAddress ? payload.extraAddress : "";

        return [primaryAddress, extraAddress].filter(Boolean).join(" ").trim();
    },

    openPostcodePopup: function(component) {
        var popupUrl =
            "/apex/KakaoPostcodePicker?origin=" +
            encodeURIComponent(window.location.origin);
        var popupWindow = window.open(
            popupUrl,
            "kakaoPostcodePicker",
            "width=520,height=640,resizable=yes,scrollbars=yes"
        );

        if (!popupWindow) {
            this.showToast(
                "error",
                "주소 검색 창을 열 수 없습니다.",
                "브라우저 팝업 차단을 해제한 뒤 다시 시도해 주세요."
            );
            return;
        }

        popupWindow.focus();
    },

    applyAddressFields: function(component, fields) {
        var street = this.buildStreetValue(
            component.get("v.baseAddress"),
            component.get("v.extraAddress"),
            component.get("v.detailAddress")
        );
        var postalCode = component.get("v.postalCode") || "";
        var region = component.get("v.addressRegion") || "";
        var city = component.get("v.addressCity") || "";
        var country = component.get("v.addressCountry") || "";

        fields.Street = street;
        fields.PostalCode = postalCode;
        fields.State = region;
        fields.City = city;
        fields.Country = country;
    },

    buildStreetValue: function(baseAddress, extraAddress, detailAddress) {
        var streetParts = [];
        var normalizedBaseAddress = baseAddress ? baseAddress.trim() : "";
        var normalizedExtraAddress = extraAddress ? extraAddress.trim() : "";

        if (normalizedBaseAddress) {
            streetParts.push(normalizedBaseAddress);
        }
        if (
            normalizedExtraAddress &&
            normalizedBaseAddress.indexOf(normalizedExtraAddress) === -1
        ) {
            streetParts.push(normalizedExtraAddress);
        }
        if (detailAddress) {
            streetParts.push(detailAddress.trim());
        }

        return streetParts.join(" ").trim().slice(0, 255);
    },

    buildPersonalCompanyName: function(fullName) {
        var normalizedName = (fullName || "").trim() || "이름없음";
        return (this.PERSONAL_COMPANY_PREFIX + normalizedName).slice(0, 255);
    }
})
