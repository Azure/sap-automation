// Helper script to perform CRUD operations on a cosmos DB
// Called by both modify_cmdb.ps1 and modify_cmdb.sh

var query = { _id: id};
var newValues = {$set: updates};
updates["_id"] = id;
crud = crud.toLowerCase();

// specify the Deployment-Objects database in the connection string
splitIndex = connStr.indexOf("/?ssl") + 1;
if (splitIndex <= 0) throw ("Invalid connection string");
connStr = connStr.substring(0, splitIndex) + "Deployment-Objects" + connStr.substring(splitIndex, connStr.length);

var db = connect(connStr);
if (db.getName() != "Deployment-Objects") {
    throw ("Had trouble connecting to database Deployment-Objects");
}
var existingObject = db[collection].findOne(query);

if (crud == "create") {
    var x = db[collection].insertOne(updates);
    var insertedId = x["insertedId"];
    if (insertedId.length > 0) {
        console.log("Successfully inserted " + id + " to collection " + collection);
    }
    else {
        console.log("Nothing was inserted");
    }
}
else if (existingObject == null) {
    throw ("No existing object " + id + " was found in " + collection);
}
else if (crud == "read") {
    printjson(JSON.stringify(existingObject));
}
else if (crud == "update") {
    var x = db[collection].updateOne(query, newValues);
    var modifiedCount = x["modifiedCount"];
    if (modifiedCount > 0) {
        console.log("Successfully updated " + id);
    }
    else {
        console.log("Nothing to update");
    }
}
else if (crud == "delete") {
    var x = db[collection].deleteOne(query);
    var deletedCount = x["deletedCount"];
    if (deletedCount > 0) {
        console.log("Successfully deleted " + id);
    }
    else {
        console.log("Nothing was deleted");
    }
}
else {
    throw ("Invalid CRUD operation supplied");
}
