#!/usr/bin/env

from __future__ import (absolute_import, division, print_function)
import pymongo
import pymongo.errors
__metaclass__ = type

DOCUMENTATION = r'''
---
module: modify_cmdb

short_description: Performs a CRUD operation to a MongoDB.

version_added: "1.0.0"

description: This module can create, update, read, and delete one or many objects in a given MongoDB.

options:
    connStr:
        description: The connection string for the database.
        required: true
        type: str
    collection:
        description: The database collection to modify.
        required: true
        type: str
    id:
        description: The id of the object to modify
        required: true
        type: str
    crud:
        description: 
            - The operation to perform
            - Accepted values: ("create", "update", "read", "delete")
        required: true
        type: str
    updates:
        description:
            - The parameters that will be added or changed (via create or update)
            - Dictionary mapping parameter names to their corresponding values
        required: false
        type: dict

author:
    - William Sheehan (@wksheehan)
'''

EXAMPLES = r'''
# Create a new system object 
- name: Create system
  modify_cmdb:
    connStr: "mongodb://localhost:27017/"
    collection: "Systems"
    id: "DEV-WEEU-SAP-100"
    crud: "create"
    updates: { "environment": "DEV", "location": "westeurope" }

# Update an existing system object
- name: Update system
  modify_cmdb:
    connStr: "mongodb://localhost:27017/"
    collection: "Systems"
    id: "DEV-WEEU-SAP-100"
    crud: "update"
    updates: { "use_prefix": false }

# Read an existing system object
- name: Read system
  modify_cmdb:
    connStr: "mongodb://localhost:27017/"
    collection: "Systems"
    id: "DEV-WEEU-SAP-100"
    crud: "read"

# Delete a system object
- name: Delete system
  modify_cmdb:
    connStr: "mongodb://localhost:27017/"
    collection: "Systems"
    id: "DEV-WEEU-SAP-100"
    crud: "delete"
'''

RETURN = r'''
# These are examples of possible return values, and in general should use other names for return values.
changed:
    description: Whether or not a modification to the database was made
    type: boolean
    returned: always
    sample: True
message:
    description: The output message that the test module generates.
    type: str
    returned: always
    sample: 'Successfully added DEV-WEEU-SAP-100 to Systems'
object:
    description: A JSON representation of the object during a read operation.
    type: JSON
    returned: sometimes
    sample: {'_id': 'PROD-WEEU-SAP-123', 'environment': 'PROD', 'location': 'westeurope'}
'''

from ansible.module_utils.basic import AnsibleModule


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        connStr=dict(type='str', required=True),
        collection=dict(type='str', required=True),
        id=dict(type='str', required=True),
        crud=dict(type='str', required=True),
        updates=dict(type='dict', required=False, default={})
    )

    # seed the result dict in the object
    result = dict(
        changed=False,
        message='',
        object=None
    )

    # abstraction object to work with ansible
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    # ================= MAIN CODE HERE ======================

    # capture the input values
    connStr = module.params["connStr"]
    collection = module.params["collection"]
    id = module.params["id"]
    crud = module.params["crud"].lower()
    updates = module.params["updates"]

    # specify the Deployment-Objects database in the connection string
    splitIndex = connStr.find("/?ssl") + 1
    if splitIndex <= 0:
        module.fail_json(msg="Invalid connection string", **result)
    connStr = connStr[:splitIndex] + "Deployment-Objects" + connStr[splitIndex:]

    client = pymongo.MongoClient(connStr)
    db = client["Deployment-Objects"]
    
    query = { "_id": id }
    newvalues = { "$set": updates }
    updates["_id"] = id
    
    existingObject = db[collection].find_one(query)

    try:
        if crud == "create":
            x = db[collection].insert_one(updates)
            if len(x.inserted_id) > 0:
                result["changed"] = True
                result["message"] = "Successfully added " + id + " to " + collection
        elif existingObject is None:
            result["message"] = "Error during " + crud
            module.fail_json(msg="No existing object " + id + " was found in collection " + collection, **result)
        elif crud == "read":
            result["object"] = existingObject
            result["message"] = "Successfully read " + id
        elif crud == "update":
            x = db[collection].update_one(query, newvalues)
            if x.modified_count > 0:
                result["changed"] = True
                result["message"] = "Successfully updated " + id
            else:
                result["message"] = "Nothing to update"
        elif crud == "delete":
            x = db[collection].delete_one(query)
            if x.deleted_count > 0:
                result["changed"] = True
                result["message"] = "Successfully deleted " + id
        else:
            module.fail_json(msg='Invalid CRUD operation. Must be one of create, read, update, or delete', **result)
    except pymongo.errors.DuplicateKeyError: 
        result["message"] = "object " + id + " already exists"
    except Exception:
        result["message"] = "Error during " + crud
        module.fail_json(msg="Please double check your inputs and try again", **result)

    # Success
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
