// ================
// VALUE RETAINMENT
// ================

var model;
var azureResourceIds = [
    "location",
    "subscription",
    "workload_zone",
    "resourcegroup_arm_id",
    "network_address_arm_id",
    "admin_subnet_arm_id",
    "db_subnet_arm_id",
    "app_subnet_arm_id",
    "web_subnet_arm_id",
    "iscsi_subnet_arm_id",
    "anf_subnet_arm_id",
    "admin_subnet_nsg_arm_id",
    "db_subnet_nsg_arm_id",
    "app_subnet_nsg_arm_id",
    "web_subnet_nsg_arm_id",
    "iscsi_subnet_nsg_arm_id",
    "anf_subnet_nsg_arm_id"
];

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

// populate azure resource dropdowns and set to current value
// retain all other form values selected for editing or on submit error
// remove the loading background and access the form
function retainFormValues() {
    var dropdownsAffected = [
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
    Promise.all(dropdownsAffected.map(updateAndSetDropdowns)).then(function () {
        for (var prop in model) {
            if (model[prop] != null && azureResourceIds.indexOf(prop) < 0 ) {
                setCurrentValue(prop);
            }
        }
        document.getElementById('loading-background').style.visibility = "hidden";
    }).catch(function () {
        document.getElementById('loading-background').style.visibility = "hidden";
    });
}

// gets azure resource data from a controller, populates dropdowns, and sets the current value
function updateAndSetDropdowns(dropdown) {
    return new Promise(function (resolve, reject) {
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
                resolve();
            },
            error: function () { errorFunc(dropdown.ids, dropdown.errorMessage); reject(); }
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
    if (typeof currentValue == "boolean") {
        currentValue = currentValue.toString();
    }
    if (currentValue) {
        if (Array.isArray(currentValue)) {
            populateListData(id, currentValue);
        }
        else if (azureResourceIds.indexOf(id) < 0) {
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
    var dropdownsAffected = [
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
        Promise.all(dropdownsAffected.map(updateAndSetDropdowns));
    }
    else {
        dropdownsAffected.map(({ ids }) => { resetDropdowns(ids) });
    }
});

$("#network_address_arm_id").on("change", function () {
    var vnetid = $(this).val();
    var dropdownsAffected = [
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
        Promise.all(dropdownsAffected.map(updateAndSetDropdowns));
    }
    else {
        dropdownsAffected.map(({ ids }) => { resetDropdowns(ids) });
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

// ====================
// FILTER PARAMETERS
// ====================

function filterResults(searchText) {
    if (searchText == "") {
        $(".grouping").show();
        $(".ms-TextField").show();
    }
    else {
        $(".grouping").hide();
        $(".grouping").has("label[for*='" + searchText + "']").show();
        $(".ms-TextField").hide();
        $(".ms-TextField").has("label[for*='" + searchText + "']").show();
    }
};