using System.Net;
using Bogus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace src
{
    public class GetAdventurers
    {
        private readonly ILogger _logger;

        public GetAdventurers(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<GetAdventurers>();
        }

        [Function("GetAdventurers")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            var response = req.CreateResponse(HttpStatusCode.OK);

            var generator = new Faker<Adventurer>()
                .RuleFor(a => a.Name, f => f.Name.FullName())
                .RuleFor(a => a.Class, f => f.PickRandom(new[] { "Warrior", "Mage", "Rogue", "Cleric" }))
                .RuleFor(a => a.Level, f => f.Random.Number(1, 100));

            var adventurers = generator.Generate(20);
            await response.WriteAsJsonAsync(adventurers);

            return response;
        }
    }

    public class Adventurer
    {
        public string Name { get; set; }
        public string Class { get; set; }
        public int Level { get; set; }
    }
}
