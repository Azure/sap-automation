# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Unit tests for the ``custom_filters`` Ansible filter plugin.
"""

from deploy.ansible.filter_plugins.custom_filters import (
    FilterModule,
    convert_kwargs_to_tags,
    try_get_error_code,
    try_get_error_code_results,
)


class TestCustomFilters:
    """
    Test suite covering every public function of
    ``deploy.ansible.filter_plugins.custom_filters``.
    """

    def test_convert_kwargs_to_tags_converts_kwargs_to_token_set(self):
        """
        Happy path for :func:`convert_kwargs_to_tags`.
        """
        result = convert_kwargs_to_tags({"task_tag": "dbload", "failure": "db_offline"})
        assert result == {"task_tag=dbload", "failure=db_offline"}

    def test_convert_kwargs_to_tags_empty_kwargs_returns_empty_set(self):
        """
        Edge case for :func:`convert_kwargs_to_tags`.
        """
        assert convert_kwargs_to_tags({}) == set()
        assert convert_kwargs_to_tags(None) == set()

    def test_convert_kwargs_to_tags_returns_empty_set_when_value_not_a_string(self):
        """
        Edge case for :func:`convert_kwargs_to_tags`.
        """
        result = convert_kwargs_to_tags({"task_tag": 123})
        assert result == set()

    def test_try_get_error_code_matches_known_message_without_tags(self):
        """
        Happy path for :func:`try_get_error_code`.
        """
        message = (
            "A secret with SHA-sid-sshkey was not found in this key vault. "
            "If you recently deleted this secret you may be able to recover it "
            "using the correct recovery command."
        )
        result = try_get_error_code(message)
        assert result == "INSTALL:0015:Secret <SID>-sid-sshkey not found in key vault."

    def test_try_get_error_code_no_match_returns_original_message(self):
        """
        Edge case for :func:`try_get_error_code`.
        """
        message = "Some unrelated error message that matches nothing."
        result = try_get_error_code(message)
        assert result == message

    def test_try_get_error_code_tag_restricted_regex_converts_with_matching_tags(self):
        """
        Happy path for :func:`try_get_error_code` with tag-restricted regexes.
        """
        message = "Failed to download package abc"
        result = try_get_error_code(message, task_tag="update_os_packages")
        assert result == (
            "INSTALL:0017:Update OS Packages has failed for host. "
            "Please ensure you have outbound connectivity to the right endpoints."
        )

    def test_try_get_error_code_tag_restricted_regex_skips_on_mismatched_tags(self):
        """
        Edge case for :func:`try_get_error_code` with tag-restricted regexes.
        """
        message = "Failed to download package abc"
        result = try_get_error_code(message, task_tag="some_other_tag")
        assert result == message

    def test_try_get_error_code_non_string_message_is_returned_unchanged(self):
        """
        Edge case for :func:`try_get_error_code`.
        """
        message = {"unexpected": "type"}
        result = try_get_error_code(message)
        assert result == message

    def test_try_get_error_code_unexpected_exception_returns_original_message(self):
        """
        Edge case for :func:`try_get_error_code`.
        """
        message = "Failed to download package abc"
        result = try_get_error_code(message, [["unhashable", "list"]])
        assert result == message

    def test_try_get_error_code_results_returns_first_converted_message(self):
        """
        Happy path for :func:`try_get_error_code_results`.
        """
        result_obj = {
            "results": [
                {"msg": "Failed to download something"},
            ]
        }
        result = try_get_error_code_results(result_obj, task_tag="update_os_packages")
        assert result == (
            "INSTALL:0017:Update OS Packages has failed for host. "
            "Please ensure you have outbound connectivity to the right endpoints."
        )

    def test_try_get_error_code_results_missing_results_key_returns_original_object(self):
        """
        Edge case for :func:`try_get_error_code_results`.
        """
        result_obj = {"no_results_key": True}
        result = try_get_error_code_results(result_obj)
        assert result == result_obj

    def test_try_get_error_code_results_result_item_without_msg_key_is_skipped(self):
        """
        Edge case for :func:`try_get_error_code_results`.
        """
        result_obj = {"results": [{"no_msg": "value"}]}
        result = try_get_error_code_results(result_obj)
        assert result == result_obj

    def test_try_get_error_code_results_non_string_msg_is_skipped(self):
        """
        Edge case for :func:`try_get_error_code_results`.
        """
        result_obj = {"results": [{"msg": 12345}]}
        result = try_get_error_code_results(result_obj)
        assert result == result_obj

    def test_try_get_error_code_results_returns_object_unchanged_when_no_conversion_occurs(self):
        """
        Edge case for :func:`try_get_error_code_results`.
        """
        result_obj = {"results": [{"msg": "an unrelated message"}]}
        result = try_get_error_code_results(result_obj)
        assert result == result_obj

    def test_try_get_error_code_results_exception_returns_original_object(self):
        """
        Edge case for :func:`try_get_error_code_results`.
        """
        result_obj = {"results": "not-a-list-of-dicts"}
        result = try_get_error_code_results(result_obj)
        assert result == result_obj

    def test_filter_module_filters_returns_expected_mapping(self):
        """
        Happy path for :meth:`FilterModule.filters`.
        """
        module = FilterModule()
        filters = module.filters()
        assert filters == {
            "try_get_error_code": try_get_error_code,
            "try_get_error_code_results": try_get_error_code_results,
        }
