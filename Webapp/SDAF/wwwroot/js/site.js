// ================
// VALUE RETAINMENT
// ================

var model;
var azureResourceIds = [
    "location",
    "subscription",
    "workload_zone",
    "resourcegroup_arm_id",
    "network_arm_id",
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
    "anf_subnet_nsg_arm_id",
    "diagnostics_storage_account_arm_id",
    "witness_storage_account_arm_id",
    "transport_storage_account_id",
    "transport_private_endpoint_id",
    "install_storage_account_id",
    "azure_files_sapmnt_id",
    "install_private_endpoint_id",
    "user_keyvault_id",
    "automation_keyvault_id",
    "spn_keyvault_id",
    "proximityplacementgroup_arm_ids",
    "database_vm_avset_arm_ids",
    "application_server_vm_avset_arm_ids",
    "sapmnt_private_endpoint_id",
    "user_keyvault_id",
    "spn_keyvault_id"
];
var hanadb_sizes = [
    {
        "text": "Default",
        "value": "Default"
    },
    {
        "text": "S4Demo",
        "value": "S4Demo"
    },
    {
        "text": "Standard E20ds v4",
        "value": "E20ds_v4"
    },
    {
        "text": "Standard E20ds v5",
        "value": "E20ds_v5"
    },
    {
        "text": "Standard E32ds v4",
        "value": "E32ds_v4"
    },
    {
        "text": "Standard E32ds v5",
        "value": "E32ds_v5"
    },
    {
        "text": "Standard E48ds v4",
        "value": "E48ds_v4"
    },
    {
        "text": "Standard E48ds v5",
        "value": "E48ds_v5"
    },
    {
        "text": "Standard E64s v3",
        "value": "E64s_v3"
    },
    {
        "text": "Standard E64s v4",
        "value": "E64s_v4"
    },
    {
        "text": "Standard E64s v5",
        "value": "E64s_v5"
    },
    {
        "text": "Standard E96s v5",
        "value": "E96s_v5"
    },
    {
        "text": "Standard M32ts",
        "value": "M32ts"
    },
    {
        "text": "Standard M32ls",
        "value": "M32ls"
    },
    {
        "text": "Standard M64ls",
        "value": "M64ls"
    },
    {
        "text": "Standard M64s",
        "value": "M64s"
    },
    {
        "text": "Standard M64ms",
        "value": "M64ms"
    },
    {
        "text": "Standard M128s",
        "value": "M128s"
    },
    {
        "text": "Standard M128ms",
        "value": "M128ms"
    },
    {
        "text": "Standard M208s_v2",
        "value": "M208s_v2"
    },
    {
        "text": "Standard M208ms_v2",
        "value": "M208ms_v2"
    },
    {
        "text": "Standard M416s_v2",
        "value": "M416s_v2"
    },
    {
        "text": "Standard M416ms_v2",
        "value": "M416ms_v2"
    }
];
var anydb_sizes = [
    {
        "text": "Default",
        "value": "Default"
    },
    {
        "text": "256 GB",
        "value": "256"
    },
    {
        "text": "512 GB",
        "value": "512"
    },
    {
        "text": "1 TB",
        "value": "1024"
    },
    {
        "text": "2 TB",
        "value": "2048"
    },
    {
        "text": "5 TB",
        "value": "5120"
    },
    {
        "text": "10 TB",
        "value": "10240"
    },
    {
        "text": "15 TB",
        "value": "15360"
    },
    {
        "text": "20 TB",
        "value": "20480"
    },
    {
        "text": "30 TB",
        "value": "30720"
    },
    {
        "text": "40 TB",
        "value": "40960"
    },
    {
        "text": "50 TB",
        "value": "51200"
    }
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

    // default to only show basic parameters
    $("#advanced-filter").prop("checked", false);
    $("#advanced-filter").trigger("change");
    $("#expert-filter").prop("checked", false);
    $("#expert-filter").trigger("change");

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
            if (model[prop] != null) {
                setCurrentValue(prop);
            }
        }
        document.getElementById('loading-background').style.visibility = "hidden";
    }).catch(function () {
        for (var prop in model) {
            if (model[prop] != null) {
                setCurrentValue(prop);
            }
        }
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

// populate environment dropdown with values from ADO if pipeline deployment
function getEnvironmentsFromAdo(isPipelineDeployment) {
    var id = "environment";
    if (isPipelineDeployment) {
        $.ajax({
            type: "GET",
            url: "/Environment/GetEnvironments",
            data: {},
            success: function (data) {
                resetDropdowns([id]);
                populateAzureDropdownData(id, data);
                setCurrentValue(id);
            },
            error: function () { alert("Error retrieving existing environments from ADO"); }
        });
    }
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
        $("#" + id).prop('checked', currentValue);
        $("#" + id).trigger('change');
    }
    else if (currentValue) {
        if (Array.isArray(currentValue)) {
            populateListData(id, currentValue);
        }
        else if (azureResourceIds.indexOf(id) > 0) {
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

// set the subscription and virtual network to correct value based on one of the existing arm ids
// required for the case that a user inputs valid arm ids without choosing a subscription or vnet and later wishes to edit
function setDataFromResource() {
    if (model["subscription"] == null || model["network_arm_id"] == null) {
        var alreadySetArmId = null;
        for (i = 3; i < azureResourceIds.length; i++) {
            var currArmId = azureResourceIds[i];
            if (model[currArmId] != null) {
                alreadySetArmId = model[currArmId];
                break;
            }
        }
        if (alreadySetArmId != null) {
            if (model["subscription"] == null) {
                $.ajax({
                    type: "GET",
                    url: "/Armclient/GetSubscriptionFromResource",
                    data: {
                        resourceId: alreadySetArmId
                    },
                    success: function (data) {
                        model["subscription"] = data;
                    },
                    error: function () {
                        console.log("Couldn't get subscription from any existing resources");
                    }
                });
            }
            if (model["network_arm_id"] == null) {
                $.ajax({
                    type: "GET",
                    url: "/Armclient/GetVnetFromResource",
                    data: {
                        resourceId: alreadySetArmId
                    },
                    success: function (data) {
                        model["network_arm_id"] = data;
                    },
                    error: function () {
                        console.log("Couldn't get network_arm_id from any existing resources");
                    }
                });
            }
        }
    }
}

function updateImage(source, target) {
    var sourceVal = $(source).val();
    if (sourceVal) {
        var confirmMessage = "Are you sure? Selecting this value will populate values for the parameter " + target;
        if (confirm(confirmMessage)) {
            $.ajax({
                type: "GET",
                url: "/System/GetImage",
                data: {
                    name: sourceVal
                },
                success: function (data) {
                    $("#" + target + "_os_type").val(data["os_type"]);
                    $("#" + target + "_source_image_id").val(data["source_image_id"]);
                    $("#" + target + "_publisher").val(data["publisher"]);
                    $("#" + target + "_offer").val(data["offer"]);
                    $("#" + target + "_sku").val(data["sku"]);
                    $("#" + target + "_version").val(data["version"]);
                    $("#" + target + "_type").val(data["type"]);
                },
                error: function () { alert("Error getting image details"); }
            });
        }
        else {
            $(source).val(null).trigger('change');
        }
    }
}

function addTag(param) {
    var parentDiv = $("#" + param + "-tags-container");
    var numTags = $("#" + param + "-tags-container input").length / 2;
    parentDiv.append('<div class="tag"></div>');
    var lastTagContainer = parentDiv.children().last();
    lastTagContainer.append('<div class="tag-key"></div>');
    lastTagContainer.children().last().append('<label class="ms-Label tags-label" for="' + param + '_' + numTags + '__Key">Key</label>');
    lastTagContainer.children().last().append('<input class="ms-TextField-field" id="' + param + '_' + numTags + '__Key" name="' + param + '[' + numTags + '].Key" type="text" value="">');
    lastTagContainer.append('<div class="tag-value"></div>');
    lastTagContainer.children().last().append('<label class="ms-Label tags-label" for="' + param + '_' + numTags + '__Value">Value</label>');
    lastTagContainer.children().last().append('<input class="ms-TextField-field" id="' + param + '_' + numTags + '__Value" name="' + param + '[' + numTags + '].Value" type="text" value="">');
}

function populateLocations(id, value) {
    $.ajax({
        type: "GET",
        url: "/Armclient/GetLocationOptions",
        data: { useRegionMapping: true },
        success: function (data) {
            populateAzureDropdownData(id, data);
            $("#" + id).val(value);
            $("#" + id).trigger('change');
        },
        error: function () { errorFunc([id], "Error retrieving locations"); }
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
            ids: ["network_arm_id"],
            controller: "/Armclient/GetVNetOptions",
            errorMessage: "Error retrieving vnets for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["diagnostics_storage_account_arm_id",
                "witness_storage_account_arm_id",
                "transport_storage_account_id",
                "install_storage_account_id",
                "azure_files_sapmnt_id"
            ],
            controller: "/Armclient/GetStorageAccountOptions",
            errorMessage: "Error retrieving storage accounts for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["transport_private_endpoint_id",
                "install_private_endpoint_id",
                "sapmnt_private_endpoint_id"
            ],
            controller: "/Armclient/GetPrivateEndpointOptions",
            errorMessage: "Error retrieving private endpoints for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["user_keyvault_id",
                "spn_keyvault_id",
                "automation_keyvault_id"
            ],
            controller: "/Armclient/GetKeyvaultOptions",
            errorMessage: "Error retrieving keyvaults for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["proximityplacementgroup_arm_ids"],
            controller: "/Armclient/GetPPGroupOptions",
            errorMessage: "Error retrieving proximity placement groups for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["database_vm_avset_arm_ids",
                "application_server_vm_avset_arm_ids"
            ],
            controller: "/Armclient/GetAvSetOptions",
            errorMessage: "Error retrieving availability sets for specified subscription",
            input: {
                subscriptionId: subscriptionid
            }
        },
        {
            ids: ["user_assigned_identity_id"],
            controller: "/Armclient/GetUserAssignedIdentityOptions",
            errorMessage: "Error retrieving user assigned identities for specified subscription",
            input: {
              subscriptionId: subscriptionid
            }
        },
        {
            ids: ["scaleset_id"],
            controller: "/Armclient/GetVMSSOptions",
            errorMessage: "Error retrieving Virtual machine scalesets for specified subscription",
            input: {
              subscriptionId: subscriptionid
            }
      }
    ];
    if (subscriptionid) {
        Promise.all(dropdownsAffected.map(updateAndSetDropdowns));
    }
    else {
        dropdownsAffected.map(({ ids }) => { resetDropdowns(ids) });
    }
});

$("#network_arm_id").on("change", function () {
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
        var confirmMessage = "Are you sure? Selecting this value will populate certain inputs with values from the workload zone: " + workloadzoneid;
        if (confirm(confirmMessage)) {
            $.ajax({
                type: "GET",
                url: "/Landscape/GetByIdJson",
                data: {
                    id: workloadzoneid,
                },
                success: function (data) {
                    entireLandscape = JSON.parse(data);
                    partialLandscape = {};
                    partialLandscape["location"] = entireLandscape["location"];
                    partialLandscape["environment"] = entireLandscape["environment"];
                    partialLandscape["network_logical_name"] = entireLandscape["network_logical_name"];
                    updateModel(partialLandscape);
                },
                error: function () { alert("Error populating data for given workload zone"); }
            });
        } else {
            $("#workload_zone").val(null);
        }
    }
});

$("#database_platform").on("change", function () {
    var platform = $(this).val();
    if (platform == "" || platform == "NONE") {
        $("#database_size").val(null);
        $("#database_size").empty();
    }
    else if (platform == "HANA") {
        $("#database_size").empty();
        populateAzureDropdownData("database_size", hanadb_sizes);
    }
    else {
        $("#database_size").empty();
        populateAzureDropdownData("database_size", anydb_sizes);
    }
});

// ========================
// TOGGLE FUNCTIONS
// ========================

// Hide and show basic, advanced, expert views
function toggleParams(checkbox, displayNum) {
    var displayClass = (displayNum == 1) ? ".basic-parameter" : ((displayNum == 2) ? ".advanced-parameter" : ".expert-parameter");
    if (checkbox.checked) {
        $(displayClass).show();
        $(".grouping").has("div" + displayClass).show();
    }
    else {
        $(displayClass).hide();
        var matchingHeaders = $(".grouping").has("div.parameters > div:visible");
        $(".grouping").hide();
        matchingHeaders.show();
    }
}

function toggleDefault(checkbox, id, modelType) {
    var modelDisplayText = (modelType == "Landscape") ? "workload zone." : "system."
    if (checkbox.checked) {
        var confirmMessage = "Are you sure? Selecting this value will populate certain inputs with values from the default " + modelDisplayText;
        if (confirm(confirmMessage)) {
            $.ajax({
                type: "GET",
                url: "/" + modelType + "/GetDefaultJson",
                data: {},
                success: function (data) {
                    data = JSON.parse(data);
                    data['IsDefault'] = false;
                    data['sid'] = null;
                    updateModel(data);
                },
                error: function () {
                    alert("Error populating data using the default " + modelDisplayText);
                }
            });
        } else {
            $("#" + id).prop('checked', false);
        }
    }
}

function toggleDisableViaCheckbox(checkbox, id) {
    if (checkbox.checked) {
        $("#" + id).prop('disabled', false);
    }
    else {
        $("#" + id).prop('disabled', true);
    }
}

function toggleDisableViaNInputs(inputList, id) {
    for (i = 0; i < inputList.length; i++) {
        var input = inputList[i];
        if ($("#" + input).val()) continue;
        else break;
    }
    if (i == inputList.length) {
        $("#" + id).prop('disabled', false);
    }
    else {
        $("#" + id).prop('checked', false);
        $("#" + id).prop('disabled', true);
    }
}

function toggleNullParameters() {
    $(".is-null-value").toggle();
}

// Make header sticky on create and edit views
function stickifyHeader(formHeader, sticky) {
    var currPosition = $(window).scrollTop();
    if (currPosition > sticky) {
        formHeader.addClass("sticky");
        $(".filter-checkboxes").css("text-align", "left");
        $("#checkbox-and-searchbar").css("padding-left", "10px");
    } else {
        formHeader.removeClass("sticky");
        $(".filter-checkboxes").css("text-align", "center");
        $("#checkbox-and-searchbar").css("padding-left", "0px");
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
        $("#basic-filter").trigger("change");
        $("#advanced-filter").trigger("change");
        $("#expert-filter").trigger("change");
    }
    else {
        $(".grouping").hide();
        $(".ms-TextField").hide();

        var matchingHeaders = $(".grouping").has("h2:Contains(" + searchText + ")");
        matchingHeaders.show();
        matchingHeaders.find($(".ms-TextField")).show();

        $(".grouping").has("label:Contains(" + searchText + ")").show();
        $(".ms-TextField").has("label:Contains(" + searchText + ")").show();
    }
};

// Case insensitive contains
jQuery.expr[':'].Contains = function (a, i, m) {
    return jQuery(a).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0;
};
