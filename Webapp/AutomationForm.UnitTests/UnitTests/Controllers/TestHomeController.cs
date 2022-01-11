using AutomationForm.Controllers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using System;
using Xunit;

namespace AutomationForm.Tests.UnitTests.Controllers
{
    public class TestHomeController
    {
        [Fact]
        public void ShouldReturnIndexView()
        {
            var mockLogger = new Mock<ILogger<HomeController>>();
            var controller = new HomeController(mockLogger.Object);
            var result = controller.Index();
            Assert.IsType<ViewResult>(result);
        }

        [Fact]
        public void ShouldReturnPrivacyView()
        {
            var mockLogger = new Mock<ILogger<HomeController>>();
            var controller = new HomeController(mockLogger.Object);
            var result = controller.Privacy();
            Assert.IsType<ViewResult>(result);
        }

        /*[Fact]
        public void ShouldReturnErrorView()
        {
            var mockLogger = new Mock<ILogger<HomeController>>();
            var controller = new HomeController(mockLogger.Object);
            var result = controller.Error();
            var viewResult = Assert.IsType<ViewResult>(result);
        }*/
        
    }
}
