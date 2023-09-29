import re
import traceback

# List of 3 elm tuples of the format (regex, msg, valid_tags). regex
# is used to find if a stderr message contains a certain substring.
# msg is the error coded message to return in case a match is found
# using the regex provided the tags in the tag list passed to the
# are all present in the list of valid tags listed in the 3rd item
# of the tuple (valid_tags). Tags are used to capture the context in
# which the filter had been called.
regex_to_error_msgs = [
    (r'(.*)A secret with(.*)-sid-sshkey was not found in this key vault. If you recently deleted this secret you may be able to recover it using the correct recovery command.(.*)',
        'INSTALL:0015:Secret <SID>-sid-sshkey not found in key vault.',
        {}),
    (r'(.*)A secret with(.*)deployer-kv-name was not found in this key vault. If you recently deleted this secret you may be able to recover it using the correct recovery command.(.*)',
        'INSTALL:0016:Secret deployer-kv-name not found in key vault.',
        {}),
    (r'(.*)Failed to download(.*)',
        'INSTALL:0017:Update OS Packages has failed for host. Please ensure you have outbound connectivity to the right endpoints.',
        {'task_tag=update_os_packages'}),
    (r'(.*)non-zero return code(.*)',
        'INSTALL:0018:Zypper registration has failed on host. Please ensure you have outbound connectivity to the right endpoints.',
        {'task_tag=zypper_registration'}),
    (r'(.*)Zypper run command failed with return code 7(.*)',
        'INSTALL:0019:Update OS Packages has failed for host since zypper was locked by another process.',
        {'task_tag=update_os_package'}),
    (r'([\s\d\w\D\W]*)Connect to message server([\s\w\d\W\D]*)Make sure that the message server is started([\s\w\d\W\D]*)',
        'INSTALL:0020:DB Load failure, unable to connect to message server.',
        {'task_tag=dbload', 'failure=messageserver_offline'}),
    (r'([\s\d\w\D\W]*)Make sure the database is online([\s\w\d\W\D]*)',
        'INSTALL:0021:DB Load failure, database is offline.',
        {'task_tag=dbload', 'failure=db_offline'}),
    (r'([\s\d\w\D\W]*)Connect to message server([\s\w\d\W\D]*)Make sure that the message server is started([\s\w\d\W\D]*)',
        'INSTALL:0024:PAS Install failed, unable to connect to message server.',
        {'task_tag=pasinstall', 'failure=messageserver_offline'}),
    (r'([\s\d\w\D\W]*)Make sure the database is online([\s\w\d\W\D]*)',
        'INSTALL:0025:PAS Install failed, database is offline.',
        {'task_tag=pasinstall', 'failure=db_offline'})
]

# Takes a dictionary and converts it into a set of
# tokes of the format key=value. This set is the token list
def convert_kwargs_to_tags(kwargs):
    if not kwargs or len(kwargs) == 0:
        print(f"Invalid parameter kwargs={kwargs}")
        return set()
    try:
        tokens = set()
        for key,value in kwargs.items():
            token = key.strip()+"="+value.strip()
            tokens.add(token)
        return tokens
    except Exception:
        # return empty set in case anything goes wrong
        print("encountered exception while converting kwargs to tags")
        traceback.print_exec()
        return set()


# Returns the error message with an ansible error code
# if possible, otherwise returns the original message.
# message: the message to extract the error code from
# args[0]: the tags passed as a set from some other python
#          function
# kwargs:  tags passed through the ansible code while
#          calling the filter

def try_get_error_code(message, *args, **kwargs):
    try:
        tags = set()
        if args:
            tags = args[0]
        print(f"tags got from caller function = {tags}")
        tag_list = convert_kwargs_to_tags(kwargs)
        tag_list=tag_list.union(tags)
        print(f"tag_list = {tag_list}")
        for (matcher, op_message, valid_tags) in regex_to_error_msgs:
            if not valid_tags:
                valid_tags=set()
            print(f"valid_tags = {valid_tags}")
            if re.match(matcher, message):
                # if the tags supplied are in the list of valid tags
                # or the valid_tags set is empty (meaning the regex
                # conversion is valid for all tags), return the
                # converted message
                if tag_list.issubset(valid_tags) or len(valid_tags) == 0:
                    print(f"tag_list: {tag_list} is a subset of {valid_tags}")
                    return op_message
                else:
                    print(f"Invalid tag list. Valid tags = {valid_tags}, "+
                        f"supplied tag list = {tag_list}")
            else:
                print("regular expression could not be matched.")
    except:
        # Handle any unexpected exceptions while processing the error
        # messages
        traceback.print_exc()

    return message

# TODO: Instead of always looking at result_obj["results"]
#       parameterize this using tags so that other properties of the
#       result_obj can be scanned for errors.

# Gets the error coded string from a result object whose
# error details are present within result_obj.results[index].msg
# result_obj: The object from which the erorr coded strings
#             are to be got
# args:       No definitions as of now
# kwargs:     Tags passed in from ansible code while calling the
#             filter

def try_get_error_code_results(result_obj, *args, **kwargs):
    try:
        tags = convert_kwargs_to_tags(kwargs)
        print(f"converted kwargs to tag list {tags}")
        # Segment doing the error handling for different task_tag s
        results = result_obj["results"]
        for result in results:
            print(f'result item = {result}')
            message = result["msg"]
            error_coded_message = try_get_error_code(message, tags)
            if error_coded_message != message:
                return error_coded_message
            else:
                print("Message conversion not done")
    except:
        # This handling some unforeseen errors caused due to
        # indexing into dictionary. No special handling is
        # required as we shall pass back the object unconverted.
        traceback.print_exc()
    return result_obj

class FilterModule(object):

    # Custom filter plugins.

    def filters(self):
        return {
            'try_get_error_code': try_get_error_code,
            'try_get_error_code_results': try_get_error_code_results
        }



#-------------------------------------------------------
# Test code that can be commented out after development
#-------------------------------------------------------
# result = {
#     "results": [
#         {
#             "msg": "Failed to download something something"
#         }
#     ]
# }
# message = "asdConnect to message server\n<>>Make sure that the message server is started*asd\n"
# print(try_get_error_code_results(result, task_tag="update_os_packages", host_name="host"))
# print(try_get_error_code(message,task_tag="dbload_messageserver"))
# convert_kwargs_to_tags(None)
