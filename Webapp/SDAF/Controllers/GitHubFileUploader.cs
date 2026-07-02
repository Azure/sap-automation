
using Octokit;

using System.Threading.Tasks;
 namespace SDAFWebApp.Controllers;

public class GitHubFileUploader
{
    private readonly GitHubClient _client;
    private readonly string _owner;
    private readonly string _repo;

    public GitHubFileUploader(string token, string owner, string repo)
    {
        _owner = owner;
        _repo = repo;

        _client = new GitHubClient(new ProductHeaderValue("SDAFWebApp"));
        _client.Credentials = new Credentials(token);
    }

    public async Task<RepositoryContentChangeSet> CreateOrUpdateFileAsync(string path, string content, string message, string branch = "main")
    {
        try
        {

            // Try to get the existing file
            var existingFile = await _client.Repository.Content.GetAllContentsByRef(_owner, _repo, path, branch);

            // File exists - update it
            var updateRequest = new UpdateFileRequest(message, content, existingFile[0].Sha, branch);
            return await _client.Repository.Content.UpdateFile(_owner, _repo, path, updateRequest);
        }
        catch (NotFoundException)
        {
            // File doesn't exist - create it
            var createRequest = new CreateFileRequest(message, content, branch);
            return await _client.Repository.Content.CreateFile(_owner, _repo, path, createRequest);
        }
    }

    private async Task<string> GetFileShaAsync(string path, string branch)
    {
        try
        {
            var contents = await _client.Repository.Content.GetAllContentsByRef(_owner, _repo, path, branch);
            return contents[0].Sha;
        }
        catch (NotFoundException)
        {
            return null; // File doesn't exist
        }
    }
}
