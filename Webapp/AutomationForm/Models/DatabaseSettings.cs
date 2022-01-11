namespace AutomationForm.Models
{
    public class DatabaseSettings : IDatabaseSettings
    {
        public string DatabaseName { get; set; }
        public string LandscapeCollectionName { get; set; }
        public string SystemCollectionName { get; set; }
        public string MongoConnectionStringKey { get; set; }
    }

    public interface IDatabaseSettings
    {
        string DatabaseName { get; set; }
        string LandscapeCollectionName { get; set; }
        string SystemCollectionName { get; set; }
        string MongoConnectionStringKey { get; set; }
    }
}