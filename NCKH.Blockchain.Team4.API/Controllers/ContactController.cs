using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MySqlConnector;
using NCKH.Blockchain.Team4.Common.Constant;
using NCKH.Blockchain.Team4.Common.Entities.DTO;
using System.Diagnostics.CodeAnalysis;

namespace NCKH.Blockchain.Team4.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class ContactController : ControllerBase
    {
        [HttpGet]
        public IActionResult GetContactByPaggingAndFilter( string userID = AccountContext.IssuerPolicyID,
            int pageSize = 10, 
            int pageNumber = 1, 
            string? userName = null, 
            int? contactStatus = null)
        {
            var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

            string storedProcedureName = DatabaseContext.CONTACT_GET_PAGING_AND_FILLTER;

            var parameters = new DynamicParameters();
            parameters.Add("v_UserID", userID);
            parameters.Add("v_PageSize", pageSize);
            parameters.Add("v_PageNumber", pageNumber);
            parameters.Add("v_UserName", userName);
            parameters.Add("v_ContactStatus", contactStatus);

            var contactDTOs = mySqlConnection.Query(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

            if(contactDTOs != null)
            {
                return StatusCode(StatusCodes.Status200OK, contactDTOs);
            }

            return StatusCode(StatusCodes.Status200OK, new List<ContactDTO>());
        }

        [HttpPost]
        public IActionResult AcceptContact(Guid contactID)
        {
            try
            {
                //Khởi tạo kết nối với DB Mysql
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CONTACT_ACCEPT;

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_ContactID", contactID);

                //Thực hiện gọi vào DB
                var employee = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (employee > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, contactID);
                }
                return StatusCode(StatusCodes.Status404NotFound);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        [HttpDelete]
        public IActionResult DeleteContact(Guid contactID)
        {
            try
            {
                //Khởi tạo kết nối với DB Mysql
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CERTIFICATE_DELETE;

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_ContactID", contactID);

                //Thực hiện gọi vào DB
                var employee = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (employee > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, contactID);
                }
                return StatusCode(StatusCodes.Status404NotFound);
            }
            catch(Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }
    }
}
