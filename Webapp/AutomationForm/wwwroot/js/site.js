
var model;

function setModelData(data) {
    model = data;
}

// Hide input based on overriding parameter; erase pre-entered value if any
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

function initializeDropdowns() {
    var dropdowns = [
        {
            ids: ["location"],
            values: [model.location],
            controller: "/Armclient/GetLocationOptions",
            data: {
                errorMessage: "Error retrieving locations"
            }
        },
        {
            ids: ["subscription"],
            values: [model.subscription],
            controller: "/Armclient/GetSubscriptionOptions",
            data: {
                errorMessage: "Error retrieving subscriptions"
            }
        }
    ];
    updateDropdownData(dropdowns, true);
    successFunc(["environment"], [model.environment], []);
}

function initializeLists(lists) {
    for (i = 0; i < lists.length; i++) {
        for (j = 0; j < lists[i].data.length; j++) {
            $("#" + lists[i].id).append($("<option />").val(lists[i].data[j]).text(lists[i].data[j]));
        }
    $("#" + lists[i].id).val(lists[i].data);
    }
}

function initializeWorkloadZones() {
    $.ajax({
        type: "GET",
        url: "/Landscape/GetWorkloadZones",
        data: {
            errorMessage: "Error retrieving existing workload zones"
        },
        success: function (data) {
            for (i = 0; i < data.length; i++) {
                $("#workload_zone").append($("<option />").val(data[i].value).text(data[i].text));
            }
            if (model.workloadzone) {
                $("#workload_zone").val(model.workloadzone);
            }
        },
        error: function () {
            alert("Error retrieving workload zones");
        }
    });

}

$("#workload_zone").on("change", function () {
    var workloadzoneid = $(this).val();
    if (workloadzoneid) {
        $.ajax({
            type: "GET",
            url: "/Landscape/GetById",
            data: {
                id: workloadzoneid
            },
            success: function (data) {
                var retainedValues = {
                    workloadzone: workloadzoneid,
                    subscription: data.subscription,
                    environment: data.environment,
                    location: data.location,
                    rg: data.resource_group_arm_id,
                    network: data.network_address_arm_id,
                    adminsubnetarmid: data.admin_subnet_arm_id,
                    dbsubnetarmid: data.db_subnet_arm_id,
                    appsubnetarmid: data.app_subnet_arm_id,
                    websubnetarmid: data.web_subnet_arm_id,
                    iscsisubnetarmid: data.iscsi_subnet_arm_id,
                    anfsubnetarmid: data.anf_subnet_arm_id,
                    adminsubnetnsgarmid: data.admin_subnet_nsg_arm_id,
                    dbsubnetnsgarmid: data.db_subnet_nsg_arm_id,
                    appsubnetnsgarmid: data.app_subnet_nsg_arm_id,
                    websubnetnsgarmid: data.web_subnet_nsg_arm_id,
                    iscsisubnetnsgarmid: data.iscsi_subnet_nsg_arm_id,
                    anfsubnetnsgarmid: data.anf_subnet_nsg_arm_id
                }
                setModelData(retainedValues);
                initializeDropdowns();
            },
            error: function () {
                alert("Error populating data for given workload zone");
            }
        });
    }
});

$("#subscription").on("change", function () {
    var subscriptionid = $(this).val();
    var dropdowns = [
        {
            ids: ["resource_group_arm_id"],
            values: [model.rg],
            controller: "/Armclient/GetResourceGroupOptions",
            data: {
                subscriptionId: subscriptionid,
                errorMessage: "Error retrieving resource groups for specified subscription"
            }
        },
        {
            ids: ["network_address_arm_id"],
            values: [model.network],
            controller: "/Armclient/GetVNetOptions",
            data: {
                subscriptionId: subscriptionid,
                errorMessage: "Error retrieving vnets for specified subscription"
            }
        },
    ];
    updateDropdownData(dropdowns, subscriptionid);
});

$("#network_address_arm_id").on("change", function () {
    var vnetid = $(this).val();
    var dropdowns = [
        {
            ids: [
                "admin_subnet_arm_id",
                "db_subnet_arm_id",
                "app_subnet_arm_id",
                "web_subnet_arm_id",
                "iscsi_subnet_arm_id",
                "anf_subnet_arm_id"
            ],
            values: [
                model.adminsubnetarmid,
                model.dbsubnetarmid,
                model.appsubnetarmid,
                model.websubnetarmid,
                model.iscsisubnetarmid,
                model.anfsubnetarmid
            ],
            controller: "/Armclient/GetSubnetOptions",
            data: {
                vnetId: vnetid,
                errorMessage: "Error retrieving subnets for specified vnet"
            }
        },
        {
            ids: [
                "admin_subnet_nsg_arm_id",
                "db_subnet_nsg_arm_id",
                "app_subnet_nsg_arm_id",
                "web_subnet_nsg_arm_id",
                "iscsi_subnet_nsg_arm_id",
                "anf_subnet_nsg_arm_id"
            ],
            values: [
                model.adminsubnetnsgarmid,
                model.dbsubnetnsgarmid,
                model.appsubnetnsgarmid,
                model.websubnetnsgarmid,
                model.iscsisubnetnsgarmid,
                model.anfsubnetnsgarmid
            ],
            controller: "/Armclient/GetNsgOptions",
            data: {
                vnetId: vnetid,
                errorMessage: "Error retrieving network security groups for specified vnet's resource group"
            }
        }
    ];
    updateDropdownData(dropdowns, vnetid);
});

function updateDropdownData(dropdowns, currid) {
    dropdowns.forEach(function (dropdown) {
        resetDropdowns(dropdown.ids);
        if (currid) {
            $.ajax({
                type: "GET",
                url: dropdown.controller,
                data: dropdown.data,
                success: function (data) { successFunc(dropdown.ids, dropdown.values, data); },
                error: function () { errorFunc(dropdown.ids, dropdown.data.errorMessage); }
            });
        }
    });
}

// Retains the dropdown values when editing
function successFunc(ids, values, data) {
    for (i = 0; i < ids.length; i++) {
        for (j = 0; j < data.length; j++) {
            $("#" + ids[i]).append($("<option />").val(data[j].value).text(data[j].text));
        }
        if (values[i]) {
            $("#" + ids[i]).val(values[i]).trigger('change');
        }
    }
}

function errorFunc(ids, errorMessage) {
    resetDropdowns(ids);
    alert(errorMessage);
}

function resetDropdowns(ids) {
    ids.forEach(function (id) {
        if ($("#" + id).val()) {
            $("#" + id).val(null).trigger('change');
        }
        $("#" + id).empty();
    });
}