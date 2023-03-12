using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MySqlConnector;
using NCKH.Blockchain.Team4.Common.Entities.DTO;
using NCKH.Blockchain.Team4.Common.Constant;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace NCKH.Blockchain.Team4.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class CertificateController : ControllerBase
    {
        /// <summary>
        /// Lấy danh sách bằng đã cấp có phân trang và lọc theo loại bằng, tên người nhận, ngày kí, tình trạng kết nối, trình trạng bằng
        /// </summary>
        /// <param name="issuerID"></param>
        /// <param name="pageSize"></param>
        /// <param name="pageNumber"></param>
        /// <param name="certType"></param>
        /// <param name="receivedName"></param>
        /// <param name="signDate"></param>
        /// <param name="contactStatus"></param>
        /// <param name="certStatus"></param>
        /// <returns>danh sách bằng đã cấp có phân trang và lọc</returns>
        [HttpGet("Issued/")]
        public IActionResult GetCertificateIssuedByPaggingAndFilter(string issuedID = AccountContext.IssuerPolicyID,
                        int pageSize = 10,
                        int pageNumber = 1,
                        string? certType = null,
                        string? receivedName = null, 
                        int? signDate = null,
                        int? contactStatus = null,
                        int? certStatus = null)
        {
            try
            {
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                string storedProcedureName = DatabaseContext.CERTIFICATE_ISSUED_GET_PAGING_AND_FILLTER;

                var parameters = new DynamicParameters();
                parameters.Add("v_IssuerID", issuedID);
                parameters.Add("v_PageSize", pageSize);
                parameters.Add("v_PageNumber", pageNumber);
                parameters.Add("v_CertType", certType);
                parameters.Add("v_ReceivedName", receivedName);
                parameters.Add("v_SignDate", signDate);
                parameters.Add("v_ContactStatus", contactStatus);
                parameters.Add("v_CertStatus", certStatus);

                var certificateIssuedDTOs = mySqlConnection.Query(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (certificateIssuedDTOs != null)
                {
                    return StatusCode(StatusCodes.Status200OK, certificateIssuedDTOs);
                }
                return StatusCode(StatusCodes.Status200OK, new List<CertificateIssuedDTO>());
            }
            catch(Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        /// <summary>
        /// Lấy danh sách bằng nhận được có phân trang và lọc
        /// </summary>
        /// <param name="receivedID"></param>
        /// <param name="pageSize"></param>
        /// <param name="pageNumber"></param>
        /// <param name="certType"></param>
        /// <param name="userName"></param>
        /// <param name="receivedDate"></param>
        /// <returns></returns>
        [HttpGet("Received/")]
        public IActionResult GetCertificateReceivedByPaggingAndFilter(string receivedID = AccountContext.ReceivedPolicyID,
                        int pageSize = 10,
                        int pageNumber = 1,
                        string? certType = null,
                        string? userName = null,
                        int? receivedDate = null)
        {
            try
            {
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                string storedProcedureName = DatabaseContext.CERTIFICATE_RECEIVED_GET_PAGING_AND_FILLTER;

                var parameters = new DynamicParameters();
                parameters.Add("v_ReceivedID", receivedID);
                parameters.Add("v_PageSize", pageSize);
                parameters.Add("v_PageNumber", pageNumber);
                parameters.Add("v_CertificateType", certType);
                parameters.Add("v_UserName", userName);
                parameters.Add("v_ReceivedDate", receivedDate);

                var certificateReceivedDTOs = mySqlConnection.Query(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (certificateReceivedDTOs != null)
                {
                    return StatusCode(StatusCodes.Status200OK, certificateReceivedDTOs);
                }
                return StatusCode(StatusCodes.Status200OK, new List<CertificateReceivedDTO>());
            }
            catch(Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        /// <summary>
        /// Thêm mới 1 bằng cấp
        /// </summary>
        /// <param name="user"></param>
        /// <returns></returns>
        [HttpPost("Issued/")]
        public IActionResult CreateCert([FromBody] CertificateDTO cert)
        {
            try
            {
                //Khởi tạo kết nối đến DB
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql
                string storedProcedureName = DatabaseContext.CERTIFICATE_INSERT;

                var parameters = new DynamicParameters();
                var props = cert.GetType().GetProperties();

                //Add PolicyID cua tai khoan hien tai, hien dang fix cung
                parameters.Add($"@v_IssuedID", AccountContext.IssuerPolicyID);

                for (int i = 1; i < props.Length; i++)
                {
                    var value = props[i].GetValue(cert);
                    parameters.Add($"@v_{props[i].Name}", value);
                }

                //Thực hiện gọi vào DB
                int numberRowsAffected = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (numberRowsAffected > 0)
                {
                    return StatusCode(StatusCodes.Status201Created);
                }
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        /// <summary>
        /// Thêm mới nhiều băng cấp
        /// </summary>
        /// <param name="certificates"></param>
        /// <returns></returns>
        [HttpPost("Issued/InsertMultiple")]
        public IActionResult InsertEmployees([FromBody] List<CertificateDTO> certificates)
        {
            var connection = new MySqlConnection(DatabaseContext.ConnectionString);
            connection.Open();
            using (var transaction = connection.BeginTransaction())
            {
                try
                {
                    foreach (var cert in certificates)
                    {
                        var parameters = new DynamicParameters();
                        var props = cert.GetType().GetProperties();

                        //Add PolicyID cua tai khoan hien tai, hien dang fix cung
                        parameters.Add($"@v_IssuedID", AccountContext.IssuerPolicyID);

                        for (int i = 1; i < props.Length; i++)
                        {
                            var value = props[i].GetValue(cert);
                            parameters.Add($"@v_{props[i].Name}", value);
                        }
                    }
                    transaction.Commit();
                    return Ok("Employees inserted successfully.");
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    return BadRequest("Error inserting employees: " + ex.Message);
                }
            }
        }

        /// <summary>
        /// Kí 1 bằng
        /// </summary>
        /// <param name="certificateID"></param>
        /// <returns></returns>
        [HttpPost("Issued/Sign/")]
        public IActionResult SignCertificate(Guid certificateID)
        {
            try
            {
                //Khởi tạo kết nối với DB Mysql
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CERTIFICATE_SIGN;

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_CertificateID", certificateID);

                //Thực hiện gọi vào DB
                var employee = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (employee > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, certificateID);
                }
                return StatusCode(StatusCodes.Status404NotFound);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        /// <summary>
        /// Gửi 1 bằng
        /// </summary>
        /// <param name="certificateID"></param>
        /// <returns></returns>
        [HttpPost("Issued/Send/")]
        public IActionResult SendCertificate(Guid certificateID)
        {
            try
            {
                //Khởi tạo kết nối với DB Mysql
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CERTIFICATE_SEND;

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_CertificateID", certificateID);

                //Thực hiện gọi vào DB
                var employee = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (employee > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, certificateID);
                }
                return StatusCode(StatusCodes.Status404NotFound);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        /// <summary>
        /// Xóa 1 bằng cấp
        /// </summary>
        /// <param name="certificateID"></param>
        /// <returns></returns>
        [HttpDelete]
        public IActionResult DeleteCertificate(Guid certificateID)
        {
            try
            {
                //Khởi tạo kết nối với DB Mysql
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CERTIFICATE_DELETE;

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_CertificateID", certificateID);

                //Thực hiện gọi vào DB
                var employee = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (employee > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, certificateID);
                }
                return StatusCode(StatusCodes.Status404NotFound);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }

        [HttpDelete("DeleteMultiple")]
        public IActionResult DeleteMultipleCertificates([FromBody] List<string> certificateIDs)
        {
            try
            {
                var mySqlConnection = new MySqlConnection(DatabaseContext.ConnectionString);

                //Chuẩn bị câu lệnh sql 
                string storedProcedureName = DatabaseContext.CERTIFICATE_DELETE_MULTIPLE;

                //Xử lý string đầu vào proc về dạng "A,B,C"
                string inputProc = String.Join(",", certificateIDs);

                //Chuẩn bị tham số đầu vào
                var parameters = new DynamicParameters();
                parameters.Add("v_CertificateIDs", inputProc);

                //Thực hiện gọi vào DB
                var certEffected = mySqlConnection.Execute(storedProcedureName, parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (certificateIDs.Count > 0)
                {
                    return StatusCode(StatusCodes.Status200OK, certEffected);
                }

                return StatusCode(StatusCodes.Status403Forbidden);
            }
            //Try catch Exception
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                return StatusCode(StatusCodes.Status500InternalServerError);
            }
        }
    }
}
