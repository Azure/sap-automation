// ================
// VALUE RETAINMENT
// ================

var model;

// initializes the model variable representing a system or landscape
function createModel(object) {
    model = object;
}

// updates the existing model and form with values from new object
function updateModel(object) {
    for (var prop in object) {
        if (object[prop]) {
            model[prop] = object[prop];
            setCurrentValue(prop);
        }
    }
}

// keep the form values selected when editing or error postback
function retainFormValues() {
    var azureResourceDropdowns = [
        {
            ids: ["location"],
            controller: "/Armclient/GetLocationOptions",
            errorMessage: "Error retrieving locations",
            input: {}
        },
        {
            ids: ["subscription"],
            controller: "/Armclient/GetSubscriptionOptions",
            errorMessage: "Error retrieving subscriptions",
            input: {}
        },
        {
            ids: ["workload_zone"],
            controller: "/Landscape/GetWorkloadZones",
            errorMessage: "Error retrieving existing workload zones",
            input: {}
        }
    ];

    // populate azure resource dropdowns and set to current value if any after populating
    updateDropdownData(azureResourceDropdowns);

    // retain all values
    for (var prop in model) {
        if (model[prop] != null) {
            setCurrentValue(prop);
        }
    }
}

// gets azure resource data from a controller, populates dropdowns, and sets the current value
function updateDropdownData(dropdowns) {
    dropdowns.forEach(function (dropdown) {
        resetDropdowns(dropdown.ids);
        $.ajax({
            type: "GET",
            url: dropdown.controller,
            data: dropdown.input,
            success: function (data) {
                dropdown.ids.forEach(function (id) {
                    populateAzureDropdownData(id, data);
                    setCurrentValue(id);
                });
            },
            error: function () { errorFunc(dropdown.ids, dropdown.errorMessage); }
        });
    });
}

// populate a dropdown with data
function populateAzureDropdownData(id, data) {
    for (i = 0; i < data.length; i++) {
        $("#" + id).append($("<option />").val(data[i].value).text(data[i].text));
    }
}

// set the current value for a parameter
function setCurrentValue(id) {
    var currentValue = model[id];
    if (typeof currentValue == "boolean") currentValue = currentValue.toString();
    if (currentValue) {
        if (Array.isArray(currentValue)) {
            populateListData(id, currentValue);
        }
        else {
            populateListData(id, [currentValue]);
        }
        $("#" + id).val(currentValue);
        if (id != "workload_zone") {
            $("#" + id).trigger('change');
        }
    }
}

// populate an input parameter that accepts lists as data
function populateListData(id, data) {
    for (j = 0; j < data.length; j++) {
        if ($("#" + id + " option[value='" + data[j] + "']").length <= 0) {
            $("#" + id).append($("<option />").val(data[j]).text(data[j]));
        }
    }
}

// to be run on unsuccessful ajax call
function errorFunc(idsAffected, errorMessage) {
    resetDropdowns(idsAffected);
    alert(errorMessage);
}

// clear all values from dropdown
function resetDropdowns(ids) {
    ids.forEach(function (id) {
        if ($("#" + id).val()) {
            $("#" + id).val(null).trigger('change');
        }
        $("#" + id).empty();
    });
}

// ===============
// EVENT LISTENERS
// ===============

$("#subscription").on("change", function () {
    var subscriptionid = $(this).val();
    var dropdownsToUpdate = [
        {
            ids: ["resourcegroup_arm_id"],
            controller: "/Armclient/GetResourceGroupOptions",
            errorMessage: "Error retrieving resource groups for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["network_address_arm_id"],
            controller: "/Armclient/GetVNetOptions",
            errorMessage: "Error retrieving vnets for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
    ];

    if (subscriptionid) {
        updateDropdownData(dropdownsToUpdate);
    }
});

$("#network_address_arm_id").on("change", function () {
    var vnetid = $(this).val();
    var dropdownsToUpdate = [
        {
            controller: "/Armclient/GetSubnetOptions",
            ids: [
                "admin_subnet_arm_id",
                "db_subnet_arm_id",
                "app_subnet_arm_id",
                "web_subnet_arm_id",
                "iscsi_subnet_arm_id",
                "anf_subnet_arm_id"
            ],
            errorMessage: "Error retrieving subnets for specified vnet",
            input: {
                vnetId: vnetid
            }
        },
        {
            controller: "/Armclient/GetNsgOptions",
            ids: [
                "admin_subnet_nsg_arm_id",
                "db_subnet_nsg_arm_id",
                "app_subnet_nsg_arm_id",
                "web_subnet_nsg_arm_id",
                "iscsi_subnet_nsg_arm_id",
                "anf_subnet_nsg_arm_id"
            ],
            errorMessage: "Error retrieving network security groups for specified vnet's resource group",
            input: {
                vnetId: vnetid
            }
        }
    ];

    if (vnetid) {
        updateDropdownData(dropdownsToUpdate);
    }
});

$("#workload_zone").on("change", function () {
    var workloadzoneid = $(this).val();
    if (workloadzoneid) {
        var confirmMessage = "Are you sure? Selecting this value will populate certain inputs with values from the landscape: " + workloadzoneid;
        if (confirm(confirmMessage)) {
            $.ajax({
                type: "GET",
                url: "/Landscape/GetByIdJson",
                data: {
                    id: workloadzoneid,
                },
                success: function (data) {
                    updateModel(JSON.parse(data));
                },
                error: function () { alert("Error populating data for given workload zone"); }
            });
        } else {
            $("#workload_zone").val(null);
        }
    }
});

// ========================
// TOGGLE DISABLE FUNCTIONS
// ========================

function toggleDisableViaCheckbox(checkbox, id) {
    if (checkbox.checked) {
        $("#" + id).prop('disabled', false);
    }
    else {
        $("#" + id).prop('disabled', true);
    }
}

function toggleDisableViaOneInput(input, id) {
    if ($("#" + input).val()) {
        $("#" + id).prop('disabled', false);
    }
    else {
        $("#" + id).prop('checked', false);
        $("#" + id).prop('disabled', true);
    }
}

function toggleDisableViaTwoInputs(input1, input2, id) {
    if ($("#" + input1).val() && $("#" + input2).val()) {
        $("#" + id).prop('disabled', false);
    }
    else {
        $("#" + id).prop('checked', false);
        $("#" + id).prop('disabled', true);
    }
}

// Disables an input when an overriding parameter has a value. Erases the pre-entered value if any
function overrulesHandler(source, target) {
    if (target == null || target.Length == 0 || source == null || source.length == 0) {
        return "";
    }
    var sourceVal = "";
    if (source.options[source.selectedIndex] != null) {
        sourceVal = (source.nodeName == "SELECT") ? source.options[source.selectedIndex].value : source.value;
    }
    if (sourceVal.length > 0) {
        target.disabled = true;
        $("#" + target.id).val(null).trigger('change');
    }
    else {
        target.disabled = false;
    }
}