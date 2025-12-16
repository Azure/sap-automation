import shutil
import subprocess

def run_az_command(args, capture_output=True, check=False, text=True):
    """
    Run an Azure CLI command with improved cross-platform compatibility.
    
    Args:
        args: List of arguments to pass to the az command
        capture_output: Whether to capture stdout/stderr
        check: Whether to raise an exception on non-zero exit
        text: Whether to decode output as text
    
    Returns:
        A CompletedProcess instance with attributes:
        - args: The command arguments
        - returncode: The exit code
        - stdout: The captured stdout (if capture_output=True)
        - stderr: The captured stderr (if capture_output=True)
    """
    # Find Azure CLI executable with cross-platform support
    exe = shutil.which("az") or shutil.which("az.cmd")
    if not exe:
        raise FileNotFoundError("Azure CLI not found in PATH. Install or add to PATH.")
    
    cmd = [exe] + args
    
    # Run the command
    try:
        if capture_output:
            result = subprocess.run(cmd, capture_output=True, check=check, text=text)
        else:
            result = subprocess.run(cmd, check=check, text=text)
            
        return result
    except FileNotFoundError as e:
        print(f"Error: Azure CLI command not found. Make sure Azure CLI is installed and in your PATH.")
        print(f"Attempted to run: {' '.join(cmd)}")
        if check:
            raise e
        # Create a fake CompletedProcess to mimic the expected return type
        class FakeCompletedProcess:
            def __init__(self):
                self.returncode = 127  # Standard "command not found" error code
                self.args = cmd
                self.stdout = ""
                self.stderr = f"Command not found: {cmd[0]}"
        return FakeCompletedProcess()
