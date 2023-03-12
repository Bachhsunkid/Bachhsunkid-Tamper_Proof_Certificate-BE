using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MySqlConnector;
using NCKH.Blockchain.Team4.Common.Constant;
using NCKH.Blockchain.Team4.Common.Entities;
using NCKH.Blockchain.Team4.Common.Entities.DTO;
using System.Data;

namespace NCKH.Blockchain.Team4.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        [HttpGet]
        public IActionResult GetDashbroadInfor(string userId = AccountContext.IssuerPolicyID)
        {
            try
            {
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                string storedProcedureName = DatabaseContext.DASHBROAD_INFOR;

                var parameters = new DynamicParameters();
                parameters.Add("v_UserID", userId, DbType.String, ParameterDirection.Input);
                parameters.Add("v_Pending", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parameters.Add("v_Connected", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parameters.Add("v_Draft", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parameters.Add("v_Signed", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parameters.Add("v_Sent", dbType: DbType.Int32, direction: ParameterDirection.Output);
                parameters.Add("v_Received", dbType: DbType.Int32, direction: ParameterDirection.Output);

                mySqlConnection.Execute("proc_dashbroad_GetInfor", parameters, commandType: CommandType.StoredProcedure);

                int pending = parameters.Get<int>("v_Pending");
                int connected = parameters.Get<int>("v_Connected");
                int draft = parameters.Get<int>("v_Draft");
                int signed = parameters.Get<int>("v_Signed");
                int sent = parameters.Get<int>("v_Sent");
                int receiveed = parameters.Get<int>("v_Received");

                var dashbroadDTO = new DashbroadDTO(pending, connected, draft, signed, sent, receiveed);

                if (dashbroadDTO != null)
                {
                    return StatusCode(StatusCodes.Status200OK, dashbroadDTO);
                }
                return StatusCode(StatusCodes.Status500InternalServerError);

            }catch(Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        [HttpPost]
        public IActionResult CreateUser([FromBody] UserDTO user)
        {
            try
            {
                //Khởi tạo kết nối đến DB
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql
                string storedProcedureName = DatabaseContext.USER_INSERT;

                var parameters = new DynamicParameters();
                var props = user.GetType().GetProperties();

                for (int i = 0; i < props.Length; i++)
                {
                    var value = props[i].GetValue(user);
                    parameters.Add($"@v_{props[i].Name}", value);
                }

                //Thực hiện gọi vào DB
                int numberRowsAffected = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (numberRowsAffected > 0)
                {
                    return StatusCode(StatusCodes.Status201Created, user);
                }
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
            catch(Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

    }
}
