using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace funcappcode
{
    public class runhttp
    {
        private readonly ILogger<runhttp> _logger;

        public runhttp(ILogger<runhttp> logger)
        {
            _logger = logger;
        }

        [Function("runhttp")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            return new OkObjectResult("Welcome to Azure Functions!");
        }
    }
}
