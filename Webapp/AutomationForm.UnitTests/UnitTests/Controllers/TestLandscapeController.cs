using AutomationForm.Controllers;
using AutomationForm.Models;
using AutomationForm.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.Extensions.Logging;
using Moq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace AutomationForm.Tests.UnitTests.Controllers
{
    public class TestLandscapeController
    {
        // INDEX

        [Fact]
        public async Task ShouldReturnIndexView()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            mockLandscapeService.Setup(l => l.GetNAsync(10)).ReturnsAsync(GetTestLandscapes());
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = await controller.Index();

            var viewResult = Assert.IsType<ViewResult>(result);
            var model = Assert.IsAssignableFrom<IEnumerable<LandscapeModel>>(
                viewResult.ViewData.Model);
            Assert.InRange(model.Count(), 1, 5);
        }

        [Fact]
        public async Task ShouldNotFindLandscapeOnGetById()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = "1";
            LandscapeModel nullLandscape = null;
            mockLandscapeService.Setup(l => l.GetByIdAsync(testId)).ReturnsAsync(nullLandscape);
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = await controller.GetById(testId);

            var viewData = Assert.IsType<NotFoundResult>(result.Result);
        }

        [Fact]
        public async Task ShouldFindLandscapeOnGetById()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = "1";
            LandscapeModel landscape = new LandscapeModel { location = "TEST" };
            mockLandscapeService.Setup(l => l.GetByIdAsync(testId)).ReturnsAsync(landscape);
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = await controller.GetById(testId);

            var viewData = Assert.IsType<LandscapeModel>(result.Value);
        }

        // CREATE

        [Fact]
        public void ShouldReturnCreateView()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = controller.Create();

            var viewResult = Assert.IsType<ViewResult>(result);
            Assert.IsAssignableFrom<LandscapeViewModel>(viewResult.ViewData.Model);
        }

        [Fact]
        public async Task ShouldRedirectToIndexOnValidCreateAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var mockLandscape = GetMockLandscape();
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = await controller.CreateAsync(mockLandscape.Object);

            var redirectToActionResult = Assert.IsType<RedirectToActionResult>(result);
            Assert.Equal("Index", redirectToActionResult.ActionName);
        }

        [Fact]
        public async Task ShouldReturnCreateViewOnInvalidCreateAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var mockLandscape = GetMockLandscape();
            var controller = new LandscapeController(mockLandscapeService.Object);

            controller.ModelState.AddModelError("LandscapeName", "Required");

            var result = await controller.CreateAsync(mockLandscape.Object);

            var viewResult = Assert.IsType<ViewResult>(result);
            var viewModel = Assert.IsAssignableFrom<LandscapeViewModel>(viewResult.ViewData.Model);
            Assert.Same(mockLandscape.Object, viewModel.Landscape);
        }

        // SETVIEWDATA

        [Fact]
        public void ShouldReturnValidLandscapeViewModel()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = controller.SetViewData();
            var viewResult = Assert.IsType<LandscapeViewModel>(result);
            Assert.Equal(3, viewResult.ParameterGroupings.Length);
        }


        public List<LandscapeModel> GetTestLandscapes()
        {
            return new List<LandscapeModel>{
                new LandscapeModel() { location = "NOEU", environment = "DEV", logical_network_name = "SAP1" },
                new LandscapeModel() { location = "KOSO", environment = "NP", logical_network_name = "SAP2" },
                new LandscapeModel() { location = "WEUS", environment = "PROD", logical_network_name = "SAP3" },
            };
        }

        public Mock<LandscapeModel> GetMockLandscape()
        {
            var mockLandscape = new Mock<LandscapeModel>();
            mockLandscape.Object.logical_network_name = "SAP0";
            mockLandscape.Object.environment = "DEV";
            mockLandscape.Object.location = "WEUS";
            mockLandscape.Object.Id = "DEV-WEUS-SAP0-INFRASTRUCTURE";
            return mockLandscape;
        }

        // DETAILS

        [Fact]
        public async Task ShouldReturnDetailsView()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = "1";
            mockLandscapeService.Setup(l => l.GetByIdAsync(testId)).ReturnsAsync(GetTestLandscapes()[0]);
            var controller = new LandscapeController(mockLandscapeService.Object);

            var result = await controller.DetailsAsync(testId);

            var viewResult = Assert.IsType<ViewResult>(result);
            var model = Assert.IsAssignableFrom<LandscapeModel>(
                viewResult.ViewData.Model);
        }
        
        // EDIT & DELETE

        [Fact]
        public async Task ShouldReturnEditAndDeleteView()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = "1";
            mockLandscapeService.Setup(l => l.GetByIdAsync(testId)).ReturnsAsync(GetTestLandscapes()[0]);
            var controller = new LandscapeController(mockLandscapeService.Object);

            var editResult = await controller.EditAsync(testId);

            var viewEditResult = Assert.IsType<ViewResult>(editResult);
            var editModel = Assert.IsAssignableFrom<LandscapeViewModel>(
                viewEditResult.ViewData.Model);

            var deleteResult = await controller.DeleteAsync(testId);

            var viewDeleteResult = Assert.IsType<ViewResult>(deleteResult);
            var deleteModel = Assert.IsAssignableFrom<LandscapeModel>(
                viewDeleteResult.ViewData.Model);

        }
        
        [Fact]
        public async Task ShouldReturnBadRequestOnNullIdEditAndDeleteAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = null;
            var controller = new LandscapeController(mockLandscapeService.Object);

            var editResult = await controller.EditAsync(testId);

            Assert.IsAssignableFrom<BadRequestResult>(editResult);
            
            var deleteResult = await controller.DeleteAsync(testId);

            Assert.IsAssignableFrom<BadRequestResult>(deleteResult);
        }

        [Fact]
        public async Task ShouldReturnNotFoundOnNullLandscapeEditAndDeleteAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            string testId = "1";
            LandscapeModel nullLandscape = null;
            mockLandscapeService.Setup(l => l.GetByIdAsync(testId)).ReturnsAsync(nullLandscape);
            var controller = new LandscapeController(mockLandscapeService.Object);

            var editResult = await controller.EditAsync(testId);
            Assert.IsAssignableFrom<NotFoundResult>(editResult);
            
            var deleteResult = await controller.DeleteAsync(testId);
            Assert.IsAssignableFrom<NotFoundResult>(deleteResult);
        }

        [Fact]
        public async Task ShouldRedirectToIndexOnValidEditAndDeleteAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var mockLandscape = GetMockLandscape();
            var mockTempData = new Mock<ITempDataDictionary>();
            var controller = new LandscapeController(mockLandscapeService.Object)
            {
                TempData = mockTempData.Object
            };

            var editResult = await controller.EditAsync(mockLandscape.Object);

            var editRedirectToActionResult = Assert.IsType<RedirectToActionResult>(editResult);
            Assert.Equal("Index", editRedirectToActionResult.ActionName);

            string testId = "1";
            var deleteResult = await controller.DeleteConfirmedAsync(testId);
            var deleteRedirectToActionResult = Assert.IsType<RedirectToActionResult>(deleteResult);
            Assert.Equal("Index", deleteRedirectToActionResult.ActionName);
        }

        [Fact]
        public async Task ShouldReturnEditViewOnInvalidEditAsync()
        {
            var mockLandscapeService = new Mock<ILandscapeService<LandscapeModel>>();
            var mockLandscape = new Mock<LandscapeModel>();
            var controller = new LandscapeController(mockLandscapeService.Object);

            controller.ModelState.AddModelError("LandscapeName", "Required");

            var result = await controller.EditAsync(mockLandscape.Object);

            var viewResult = Assert.IsType<ViewResult>(result);
            var viewModel = Assert.IsAssignableFrom<LandscapeViewModel>(viewResult.ViewData.Model);
            Assert.Same(mockLandscape.Object, viewModel.Landscape);
        }

    }
}
